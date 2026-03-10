#!/usr/bin/env python3
"""
extract_transcript_data.py - transcript JSONL から blueprint 補助データを抽出

使用方法:
    python3 extract_transcript_data.py <transcript.jsonl>

出力: YAML 形式の補助データ（標準出力）
責務: user_corrections, tool errors, session stats, blueprint使用判定のみ。
      Gate findings は pipeline-state.yaml に委譲するため抽出しない。

依存: Python 3.x 標準ライブラリのみ（json, re, sys, os）
ベース: dev-tools-plugin/skills/hurikaeri/scripts/extract_session_trace.py
"""

import json
import re
import sys
import os

# ユーザー修正検出パターン（hurikaeri と同一）
CORRECTION_PATTERNS = {
    "negation_start": re.compile(
        r"^(いや|違う|違います|そうじゃない|それじゃない|間違|訂正|no[,.]|not |that's not|you misunderstood)",
        re.IGNORECASE,
    ),
    "contrast": re.compile(
        r"(ではなく|じゃなくて|ではなくて|instead|rather than)", re.IGNORECASE
    ),
    "correction_request": re.compile(
        r"(直して|修正して|やり直して|〜にして|してください|please fix|please change|redo)",
        re.IGNORECASE,
    ),
    "instruction_reminder": re.compile(
        r"(って言った|と言った|って指示した|って頼んだ|told you|said to|asked you|I said)",
        re.IGNORECASE,
    ),
    "why_doing": re.compile(
        r"(なんで|なぜ|どうして|why).{0,20}(してる|やってる|している|するの|doing|did you)",
        re.IGNORECASE,
    ),
    "comprehension_check": re.compile(
        r"(聞いてた|聞いてる|わかってる|理解してる|読んだ(?:\?|？)|見た(?:\?|？)|are you listening|did you understand)",
        re.IGNORECASE,
    ),
    "repetition_frustration": re.compile(
        r"(もう一回|何度も|さっきも)(言|説明)", re.IGNORECASE
    ),
    "missing_element": re.compile(
        r"(がない|が足りない|が抜けてる|を忘れてる)(?!か|ことを|ように|ようです|かも)",
        re.IGNORECASE,
    ),
}

HIGH_SCORE_PATTERNS = {
    "correction_request",
    "instruction_reminder",
    "why_doing",
    "comprehension_check",
    "repetition_frustration",
    "missing_element",
}

# Blueprint スキル検出パターン
BLUEPRINT_SKILL_PATTERN = re.compile(
    r'"skill"[:\s]*"(?:blueprint-plugin:)?(spec|test-from-contract|implement|generate-docs|orchestrator|blueprint)"',
    re.IGNORECASE,
)


def extract_text_from_content(content, include_tool_results=False):
    """メッセージコンテンツからテキストを抽出"""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        texts = []
        for item in content:
            if isinstance(item, dict):
                if item.get("type") == "text":
                    texts.append(item.get("text", ""))
                elif item.get("type") == "tool_result" and include_tool_results:
                    result_content = item.get("content", "")
                    if isinstance(result_content, str):
                        texts.append(result_content)
                    elif isinstance(result_content, list):
                        for block in result_content:
                            if isinstance(block, dict) and block.get("type") == "text":
                                texts.append(block.get("text", ""))
        return " ".join(texts)
    return ""


def detect_user_correction(text):
    """ユーザーの修正指示を検出"""
    score = 0
    patterns_matched = []

    for pattern_name, pattern in CORRECTION_PATTERNS.items():
        if pattern.search(text):
            if pattern_name in HIGH_SCORE_PATTERNS:
                score += 3
            else:
                score += 2
            patterns_matched.append(pattern_name)

    if score >= 3:
        return {
            "score": score,
            "patterns": patterns_matched,
            "excerpt": text[:120],
        }
    return None


def detect_blueprint_stage(text):
    """テキストから blueprint ステージ名を検出"""
    match = BLUEPRINT_SKILL_PATTERN.search(text)
    if match:
        return match.group(1)
    return None


def process_transcript(jsonl_path):
    """transcript JSONL から補助データを抽出"""

    turn_number = 0
    last_entry_type = None

    # メトリクス
    message_count = 0
    tool_use_count = 0
    code_changes = 0

    # 抽出データ
    errors = []
    user_corrections = []
    blueprint_skills_detected = set()
    tool_use_id_map = {}

    with open(jsonl_path, "r", encoding="utf-8") as f:
        for line in f:
            message_count += 1
            try:
                entry = json.loads(line.strip())
            except json.JSONDecodeError:
                continue

            entry_type = entry.get("type")
            message = entry.get("message", {})
            content = message.get("content", [])

            # ターンカウント
            if entry_type != last_entry_type:
                if entry_type in ("user", "human"):
                    turn_number += 1
            last_entry_type = entry_type

            # blueprint スキル使用検出
            line_text = line
            stage = detect_blueprint_stage(line_text)
            if stage:
                blueprint_skills_detected.add(stage)

            # ツール使用の検出
            if entry_type == "assistant" and isinstance(content, list):
                for item in content:
                    if isinstance(item, dict) and item.get("type") == "tool_use":
                        tool_name = item.get("name", "")
                        tool_use_count += 1

                        tool_use_id = item.get("id", "")
                        if tool_use_id:
                            tool_use_id_map[tool_use_id] = tool_name

                        if tool_name in ("Write", "Edit"):
                            code_changes += 1

            # エラーの検出
            if entry_type in ("user", "human") and isinstance(content, list):
                for item in content:
                    if isinstance(item, dict) and item.get("type") == "tool_result":
                        if item.get("is_error"):
                            error_content = item.get("content", "")
                            if isinstance(error_content, str):
                                # エラー元のツール名を特定
                                result_tool_use_id = item.get("tool_use_id", "")
                                phase = tool_use_id_map.get(result_tool_use_id, "unknown")
                                errors.append({
                                    "phase": phase,
                                    "type": "tool_error",
                                    "message": error_content[:200],
                                })

            # ユーザー修正の検出
            if entry_type in ("user", "human"):
                user_text = extract_text_from_content(content, include_tool_results=False)
                if user_text.startswith("<system-reminder>"):
                    continue
                correction = detect_user_correction(user_text)
                if correction:
                    # 直前のステージを推定（最後に検出された blueprint スキル）
                    current_stage = sorted(blueprint_skills_detected)[-1] if blueprint_skills_detected else "unknown"
                    user_corrections.append({
                        "stage": current_stage,
                        "description": correction["excerpt"],
                    })

    return {
        "blueprint_used": len(blueprint_skills_detected) > 0,
        "skills_detected": sorted(blueprint_skills_detected),
        "errors": errors[:20],
        "user_corrections": {
            "count": len(user_corrections),
            "items": user_corrections[:10],
        },
        "stats": {
            "message_count": message_count,
            "tool_uses": tool_use_count,
            "code_changes": code_changes,
        },
    }


def format_yaml_output(data):
    """YAML 形式で出力（PyYAML 依存なし）"""
    lines = []

    # blueprint 使用判定
    lines.append(f"blueprint_used: {str(data['blueprint_used']).lower()}")
    skills = ", ".join(data["skills_detected"])
    lines.append(f"skills_detected: [{skills}]")

    # errors
    if data["errors"]:
        lines.append("errors:")
        for err in data["errors"]:
            phase = err["phase"].replace('"', '\\"')
            etype = err["type"].replace('"', '\\"')
            msg = err["message"].replace('"', '\\"').replace("\n", "\\n")
            lines.append(f'  - phase: "{phase}"')
            lines.append(f'    type: "{etype}"')
            lines.append(f'    message: "{msg[:150]}"')
    else:
        lines.append("errors: []")

    # user_corrections
    uc = data["user_corrections"]
    lines.append("user_corrections:")
    lines.append(f"  count: {uc['count']}")
    if uc["items"]:
        lines.append("  items:")
        for item in uc["items"]:
            stage = item["stage"].replace('"', '\\"')
            desc = item["description"].replace('"', '\\"').replace("\n", "\\n")
            lines.append(f'    - stage: "{stage}"')
            lines.append(f'      description: "{desc}"')
    else:
        lines.append("  items: []")

    # stats
    s = data["stats"]
    lines.append("stats:")
    lines.append(f"  message_count: {s['message_count']}")
    lines.append(f"  tool_uses: {s['tool_uses']}")
    lines.append(f"  code_changes: {s['code_changes']}")

    return "\n".join(lines)


def main():
    if len(sys.argv) < 2:
        print(
            "Usage: python3 extract_transcript_data.py <transcript.jsonl>",
            file=sys.stderr,
        )
        sys.exit(1)

    jsonl_path = sys.argv[1]
    if not os.path.exists(jsonl_path):
        print(f"Error: File not found: {jsonl_path}", file=sys.stderr)
        sys.exit(1)

    data = process_transcript(jsonl_path)
    print(format_yaml_output(data))


if __name__ == "__main__":
    main()
