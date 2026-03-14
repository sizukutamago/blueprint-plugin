# Requirements Review Swarm プロンプト

パイプライン Stage 0 後の Requirements Review Gate で使用するレビュープロンプト。
3 エージェントが並列でレビューし、findings を返す。

## 共通入力

各エージェントに以下を渡す:
- `docs/requirements/user-stories.md`（メイン成果物）
- `core/id-system.md` の内容（ID 採番規約）
- `core/review-criteria.md` の内容（P0/P1/P2 定義、Gate 判定基準、Severity ガバナンスルール）
- `skills/requirements/references/quality_rules.md` の内容（品質ルール）

## 共通出力フォーマット

```yaml
reviewer: "{エージェント名}"
gate: "requirements"
findings:
  - severity: P0 | P1 | P2
    target: "US-xxx | Epic-xxx | P-xxx | AC-xxx-x"
    field: "section.or.field"
    message: "問題の説明"
    suggestion: "修正提案"
summary:
  p0: 0
  p1: 0
  p2: 0
```

> **Note**: REVISE サイクルで severity を変更する場合は `core/review-criteria.md` の Severity ガバナンスルールに従い、`disposition` + `disposition_reason` + `original_severity` を記録すること。

---

## Agent 1: Completeness Checker

### 役割

ユーザーストーリーの構造的完全性を検証する。欠落要素があると `/spec` で Contract 候補の導出が不完全になるため、網羅性を厳密にチェックする。

### チェック手順

```
1. frontmatter の存在チェック:
   - version, generated_by, generated_at, mode が定義されているか
   → 欠落: P1

2. ペルソナの定義チェック:
   - P-XXX が最低 1 人定義されているか
   → 0 人: P0（後続の As a {ペルソナ} が成立しない）
   - 各ペルソナに属性・ゴール・課題が記載されているか
   → 欠落: P2

3. Epic の定義チェック:
   - Epic-XXX が最低 1 つ定義されているか
   → 0 件: P0（ストーリーの分類先がない）

4. ストーリーの完全性チェック:
   - 全 Story が As a / I want / So that 形式であるか
   → 形式違反: P1
   - 全 Story にメタテーブル（Epic, ペルソナ, 優先度, EARS, 信頼度）があるか
   → 欠落: P1
   - 全 Story が いずれかの Epic に属しているか（孤児 Story 禁止）
   → 孤児: P1
   - 全 Story のペルソナ参照（P-XXX）が定義済みペルソナに存在するか
   → 参照切れ: P1

5. 受け入れ基準の完全性チェック:
   - 全 Story に正常系 AC が最低 1 件あるか
   → 0 件: P0（テスト導出不可）
   - 全 Story に異常系 AC が最低 1 件あるか
   → 0 件: P1（エラーパスが未定義）
   - 全 AC が Gherkin 形式（Given/When/Then）であるか
   → 形式違反: P1

6. Non-Goals の定義チェック:
   - Non-Goals セクションが存在するか
   → 未定義: P1（スコープ境界が不明確）
   - Non-Goals が最低 1 項目あるか
   → 0 件: P2

7. MoSCoW 分類チェック:
   - Must の Story が最低 1 件あるか
   → 0 件: P1（MVP が定義されていない）
   - 全 Story に優先度（Must/Should/Could）が付与されているか
   → 未分類: P2
```

---

## Agent 2: Quality Auditor

### 役割

ユーザーストーリーの品質を検証する。曖昧な要件は `/spec` での Contract 定義や `/test-from-contract` でのテスト導出を困難にするため、具体性・テスト可能性を確保する。

### チェック手順

```
1. 曖昧語チェック:
   - quality_rules.md の禁止語リストに該当する語句が残っていないか
   - 対象: Story 本文、AC の Given/When/Then、EARS 記法
   - 検出対象語:
     「適切に」「など」「必要に応じて」「可能であれば」「いくつかの」
     「十分な」「速い/速く」「多い/少ない」「安全に」「使いやすい」
     「高品質な」「柔軟に」
   → 検出: P1（テスト導出不可）

2. EARS 記法準拠チェック:
   - 全 Story に EARS 分類（SHALL / WHEN-THEN / IF-THEN / WHERE / MAY / MUST NOT）
     が付与されているか
   → 未分類: P1
   - EARS 分類が要件の内容と整合しているか
     例: 条件分岐がある要件なのに SHALL に分類されている
   → 不整合: P2

3. Gherkin 品質チェック:
   - Given に具体的な前提条件があるか（「Given ユーザーがログインしている」等）
   → 抽象的: P2
   - When に具体的な操作があるか
   → 抽象的: P2
   - Then に検証可能な結果があるか
     NG: 「正しく表示される」「適切に処理される」
     OK: 「ステータス 200 を返す」「エラーメッセージ "X" を表示する」
   → 検証不可: P1

4. 定量基準チェック:
   - WHERE（NFR）要件に具体的な数値があるか
     NG: 「速い」「安全」
     OK: 「500ms 以内」「TLS 1.3」
   → 数値なし: P1

5. 信頼度バランスチェック:
   - Red の割合が全体の 30% 以上か
   → 30-50%: P2（警告）
   → 50% 以上: P1（インタビュー不足）
   - Must の Story に Red の AC があるか
   → 検出: P1（MVP 必須機能の AC が推測ベース）

6. 重複チェック:
   - 同一内容のストーリーが複数存在しないか
   → 重複: P2
   - 同一内容の AC が複数の Story に存在しないか
   → 重複: P2
```

---

## Agent 3: Traceability Checker

### 役割

ID 体系の整合性と追跡可能性を検証する。ID の欠番・重複・参照切れは `/spec` での US-XXX → FR-XXX 導出を破壊するため、厳密にチェックする。

### チェック手順

```
1. ID 連番チェック:
   - P-XXX が連番（欠番なし）か
   → 欠番: P2
   - Epic-XXX が連番（欠番なし）か
   → 欠番: P2
   - US-XXX が連番（欠番なし、Epic をまたいで通し番号）か
   → 欠番: P1（/spec での FR-XXX 導出に影響）
   - AC-XXX-Y が各 Story 内で連番か
   → 欠番: P2

2. ID 重複チェック:
   - 同一 ID が複数箇所で定義されていないか
   → 重複: P0（ID の一意性違反）

3. ID 形式チェック:
   - P-XXX: 3 桁ゼロ埋めか → 形式違反: P2
   - Epic-XXX: 3 桁ゼロ埋めか → 形式違反: P2
   - US-XXX: 3 桁ゼロ埋めか → 形式違反: P2
   - AC-XXX-Y: Story 番号 + 連番か → 形式違反: P2
   - NFR-{CAT}-XXX: カテゴリコードが id-system.md の NFR カテゴリに存在するか
   → 不正カテゴリ: P1

4. 参照整合性チェック:
   - Story のメタテーブルの Epic 参照が定義済み Epic に存在するか
   → 参照切れ: P1
   - Story のメタテーブルのペルソナ参照が定義済みペルソナに存在するか
   → 参照切れ: P1
   - AC-XXX-Y の XXX 部分が対応する US-XXX の番号と一致するか
   → 不一致: P1

5. 信頼度タグの整合性:
   - 全 AC の見出しに [Blue] / [Yellow] / [Red] タグがあるか
   → 欠落: P2
   - 全ペルソナの見出しに信頼度タグがあるか
   → 欠落: P2
   - frontmatter の confidence 集計値が本文の実数と一致するか
   → 不一致: P1

6. NFR 紐付けチェック:
   - NFR-{CAT}-XXX が Story に紐付けられているか
   → 孤立 NFR: P2
   - WHERE 記法で参照された NFR ID が定義済みか
   → 参照切れ: P1
```
