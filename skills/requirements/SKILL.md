---
name: requirements
description: "Define requirements through structured user interviews using Double Diamond pattern and EARS-inspired notation. This skill should be used BEFORE /spec — use /spec when you already know what to build and need I/O boundary contracts, use /requirements when you need to figure out WHAT to build first. Use when the user wants to \"define requirements\", \"gather requirements\", \"create user stories\", \"interview for requirements\", \"identify personas\", \"define MVP scope\", \"create acceptance criteria\", \"structure requirements\", \"start a new project\", \"plan a new app\", \"figure out what to build\", or \"scope out a product\". Also use when the user says \"要件定義\", \"ユーザーストーリー\", \"要件をまとめる\", \"ヒアリング\", \"ペルソナを定義\", \"MVPを決める\", \"受け入れ基準\", \"何を作るか整理\", \"新しいプロジェクトを始めたい\", \"アプリのアイデアがある\", \"何を作るか決めたい\", \"プロダクトの要件を整理\", or \"機能を洗い出したい\". Make sure to use this skill proactively when the user describes an app idea or project concept without existing contracts or specs."
version: 1.0.0
core_ref: core/requirements.md
---

# Requirements スキル (Claude Code)

ユーザーへの構造化インタビューを通じて要件定義を行うスキル。
Double Diamond パターンでヒアリングし、EARS-inspired 記法で構造化、信頼度レベルで透明性を確保する。

## 仕様参照

本スキルのワークフローは `core/requirements.md` に定義。
ID 規約は `core/id-system.md` を参照。

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| Git リポジトリ | ○ | `docs/requirements/` をプロジェクトルートに配置するため |
| プロジェクトの構想 | ○ | ユーザーが「何を作りたいか」のイメージを持っていること |

## 出力ファイル

| ファイル | 説明 |
|---------|------|
| `docs/requirements/user-stories.md` | メイン成果物: ペルソナ、Epic、ユーザーストーリー、Gherkin AC |
| `docs/requirements/.work/context_summary.md` | brownfield 分析結果（brownfield のみ） |
| `docs/requirements/.work/interview_log.md` | インタビュー記録 |
| `docs/requirements/.work/story_map.md` | ストーリーマップ |

## ツール

| ツール | 用途 |
|--------|------|
| Bash | git root 検出、ファイル数カウント |
| Glob | 既存ファイルスキャン、src/ 構成確認 |
| Read | README.md、PRD、既存 requirements の読み込み |
| Write | user-stories.md、中間成果物の書き出し |
| AskUserQuestion | 構造化インタビュー（全 10 質問） |
| Agent | brownfield 分析（3 並列） |

## ワークフロー（Claude Code 固有部分）

`core/requirements.md` の 6 ステップに従う。以下は Claude Code 固有の実行詳細:

### Step 1: コンテキスト読み込み + モード判定（必須）

**⛔ 絶対必須: インタビュー開始前にモード判定を完了すること。この Step を省略してはならない。**

```bash
# git root を検出
git rev-parse --show-toplevel
```

実行順序:

1. `Glob("docs/requirements/user-stories.md")` で既存チェック
   - 存在する場合: 既存ファイルを Read して内容をユーザーに提示し、AskUserQuestion ツールで確認:
     - question: `"既存の要件定義が見つかりました。どうしますか？"`
     - header: `"既存要件"`
     - options:
       - label: `"上書き更新"` / description: `"既存の要件を破棄して新規作成する"`
       - label: `"追記"` / description: `"既存の要件に追加する"`
       - label: `"中止"` / description: `"既存の要件をそのまま使う"`
2. ソースコードディレクトリの検出 + ファイル数で greenfield/brownfield 判定:
   ```
   # 判定対象ディレクトリ: src/, cmd/, internal/, pkg/, app/, lib/, packages/, apps/
   Glob("{src,cmd,internal,pkg,app,lib,packages,apps}/**/*") でファイル数をカウント
   # いずれかが存在し、合計ファイル数 >= 5 → brownfield
   ```
3. `.gitignore` チェック:
   ```
   Grep("docs/requirements/.work" in ".gitignore")
   → 存在しない場合: Bash("echo '\n# requirements work directory\ndocs/requirements/.work/' >> .gitignore")
   ```
4. brownfield の場合: Agent を 3 つ並列起動

**brownfield 時の Agent 起動（3 並列）**:

各 Agent のプロンプトは `{baseDir}/references/explorer-prompts/` を参照。
3 つの Agent を**同一メッセージ内で並列**起動する:

```
# 並列起動（3 Agent、同一ターンで全て起動）
Agent(subagent_type: "Explore", prompt: "{explorer-prompts/tech-stack-analyzer.md の内容} 対象: {プロジェクトルートパス}")
Agent(subagent_type: "Explore", prompt: "{explorer-prompts/domain-analyzer.md の内容} 対象: {プロジェクトルートパス}")
Agent(subagent_type: "Explore", prompt: "{explorer-prompts/integration-analyzer.md の内容} 対象: {プロジェクトルートパス}")
```

> **subagent_type**: `Explore` を使用（コードベース探索に特化、Read/Grep/Glob が利用可能）

3 Agent の結果をマージして `Write("docs/requirements/.work/context_summary.md")` に書き出す。

5. greenfield の場合: `Read("README.md")` と PRD ファイルを確認（存在すれば内容を要約して Q1 に活用）
6. `Bash("mkdir -p docs/requirements/.work")` でディレクトリ作成

### Step 2: インタビュー（コアフェーズ）

**⛔ このフェーズが `/requirements` の最大の価値。丁寧にヒアリングすること。**

`core/requirements.md` Step 2 + `references/interview_questions.md` のテンプレートに従う。

**実行ルール**:
- 全質問は **AskUserQuestion ツール** で実行する（テキスト質問禁止）
- 1 質問ずつ実行する（まとめて聞かない）
- 回答を受け取ったら即座に EARS-inspired 分類 + 信頼度レベルを付与
- フォローアップ質問は回答内容に応じて動的に生成
- brownfield の場合、context_summary の内容を質問に反映

**AskUserQuestion の呼び出しパターン**:

選択式の場合:
```
AskUserQuestion:
  question: "{質問文}"
  header: "{カテゴリ}"
  options:
    - label: "{選択肢1}" / description: "{補足}"
    - label: "{選択肢2}" / description: "{補足}"
```

自由回答の場合:
```
AskUserQuestion:
  question: "{質問文}"
  header: "{カテゴリ}"
```

**各回答の記録フォーマット**（interview_log.md に蓄積）:

```markdown
### Q{N}: {質問タイトル}
- **質問**: {質問文}
- **回答**: {ユーザーの回答}
- **EARS-inspired 分類**: {SHALL / WHEN-THEN / IF-THEN / WHILE / WHERE / MAY / MUST NOT}
- **信頼度**: {Blue / Yellow / Red}
- **導出された要件**:
  - {EARS-inspired 記法で構造化した要件文}
```

**終了条件**: コア質問最大 10 問（フォローアップは枠を消費しない、各質問につき最大 2 回まで） or ユーザーの終了宣言。
未解決論点は `open_questions` リストに退避。

インタビュー完了後、`Write("docs/requirements/.work/interview_log.md")` で記録を保存。

### Step 3: 構造化（Epic → Story 階層化）

`core/requirements.md` Step 3 のフォーマットでストーリーマップを生成。

処理順序:
1. インタビュー記録 + context_summary（あれば）を入力として構造化
2. ペルソナ → Epic → Story の階層を生成
3. MoSCoW 分類を適用
4. ストーリーマップをユーザーに提示

**必ず AskUserQuestion ツールを呼び出して承認を得てから次へ進む**:

- question: `"このストーリーマップで進めますか？"`
- header: `"ストーリーマップ確認"`
- options:
  - label: `"承認 — ストーリー生成に進む"` / description: `"上記の構造でユーザーストーリーを生成する"`
  - label: `"修正する"` / description: `"Epic や Story の追加・削除・変更がある"`

「修正する」が選択された場合は、変更点をヒアリングして更新し、再度 AskUserQuestion で確認する。

承認後、`Write("docs/requirements/.work/story_map.md")` で保存。

### Step 4: ユーザーストーリー生成

`references/user_stories_format.md` のフォーマットに従い、`docs/requirements/user-stories.md` を生成。

**生成ルール**:
- 各 Story に As a / I want / So that + EARS-inspired 記法 + メタテーブル
- 正常系 AC: 最低 1 件（Gherkin 形式）
- 異常系 AC: 最低 1 件（Gherkin 形式）。ただし MAY のストーリーは異常系 AC をオプションとする（省略時は N/A + 理由を記載）
- 全 AC に信頼度レベル付記
- NFR は WHERE 記法で紐付け

`Write("docs/requirements/user-stories.md", content)` で書き出す。

### Step 5: 品質チェック + 自動補正

`references/quality_rules.md` のルールに従い品質チェックを実行。

チェック順序:
1. 曖昧語チェック（禁止語リスト照合）
2. EARS-inspired 準拠チェック（全要件が分類済みか）
3. テスト可能性チェック（Gherkin 形式、定量基準）
4. 完全性チェック（Epic/Story/AC の網羅性）
5. 信頼度バランスチェック（Red の割合）

問題検出時:
1. 自動修正（1 回目）→ user-stories.md を更新
2. 再チェック → まだ問題あり → 自動修正（2 回目）
3. 再チェック → まだ問題あり → ユーザーに報告

信頼度 Red が 30% 以上の場合:
- AskUserQuestion で追加ヒアリングを提案:
  - question: `"要件の一部が推測に基づいています。追加でヒアリングしますか？"`
  - header: `"信頼度確認"`
  - options:
    - label: `"追加ヒアリングする"` / description: `"Red の要件について確認質問をする"`
    - label: `"このまま進める"` / description: `"推測ベースの要件はそのまま残す"`

### Step 6: サマリー出力

生成結果をユーザーに提示し、次のアクションを案内:

```
## 要件定義完了

### 生成ファイル
- docs/requirements/user-stories.md（ペルソナ N 人、Epic N 件、ストーリー N 件、AC N 件）

### 信頼度サマリー
| レベル | 件数 | 割合 |
|--------|------|------|
| 🔵 Blue | N | N% |
| 🟡 Yellow | N | N% |
| 🔴 Red | N | N% |

### 未解決事項
- {open_questions}

### 次のステップ
Contract を生成するには: `/spec`
```

## 原則

| 原則 | 説明 |
|------|------|
| ヒアリング最優先 | AI は質問者。ユーザーがビジネス判断する |
| 信頼度の透明性 | AI の推測は Red で明示。ユーザー確認で昇格 |
| テスト可能性 | 全要件・AC は検証可能な基準を含む |
| 1 質問ずつ | まとめて聞かない。回答を踏まえて次の質問を組み立てる |

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| git root 検出失敗 | ユーザーにプロジェクトルートで実行するよう案内 |
| brownfield 分析タイムアウト | Agent にタイムアウトを設定。失敗した Agent の分析はスキップし、インタビューで補完 |
| インタビューが収束しない | コア質問 10 問上限 + open_questions への退避 |
| 既存 requirements との競合 | 既存ファイルを提示し、上書き / 追記 / 中止 を確認 |
