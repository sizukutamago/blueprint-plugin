# ユーザーストーリー出力フォーマット

`/requirements` Step 4 で生成する `docs/requirements/user-stories.md` のフォーマット仕様。

## ファイル構造

```markdown
---
version: 1.0.0
generated_by: /requirements
generated_at: YYYY-MM-DDTHH:MM:SSZ
mode: greenfield | brownfield
personas: N
epics: N
stories: N
acceptance_criteria: N
confidence:
  blue: N
  yellow: N
  red: N
---

# ユーザーストーリー

## ペルソナ

### P-001: {ペルソナ名} [Blue]

- **属性**: {年齢層 / 職種 / 技術レベル 等}
- **ゴール**: {このペルソナが達成したいこと}
- **課題**: {現在困っていること}

---

## Epic-001: {エピック名}

### US-001: {ストーリータイトル}

| 項目 | 値 |
|------|-----|
| Epic | Epic-001 |
| ペルソナ | P-001 |
| 優先度 | Must |
| EARS | SHALL |
| 信頼度 | Blue |

> As a **{P-001 ペルソナ名}**,
> I want to **{やりたいこと}**,
> So that **{得られる価値}**.

**EARS**: システム SHALL {動作の構造化表現}

#### 受け入れ基準

##### AC-001-1: {正常系タイトル} [Blue]

```gherkin
Given {前提条件}
When {操作}
Then {期待結果}
```

##### AC-001-2: {異常系タイトル} [Yellow]

```gherkin
Given {前提条件}
When {異常な操作 / 無効な入力}
Then {エラーハンドリング / エラーメッセージ}
```

#### 非機能要件（該当する場合）

- NFR-PERF-001: WHERE {パフォーマンス制約}
- NFR-SEC-001: WHERE {セキュリティ制約}

---

### US-002: {次のストーリー}

...

---

## Non-Goals

以下は今回のスコープに含めない:

- {スコープ外の項目 1}
- {スコープ外の項目 2}

## 未解決事項

- {open_question_1}
- {open_question_2}
```

## フォーマットルール

### 必須要素

| 要素 | 必須 | 説明 |
|------|------|------|
| frontmatter | ○ | version, generated_by, generated_at, mode, 統計情報 |
| ペルソナ（P-XXX） | ○ | 最低 1 人。属性・ゴール・課題を含む |
| Epic（Epic-XXX） | ○ | 最低 1 つ。大機能領域ごと |
| ストーリー（US-XXX） | ○ | As a / I want / So that 形式 |
| メタテーブル | ○ | Epic, ペルソナ, 優先度, EARS, 信頼度 |
| EARS 記法 | ○ | 各 Story に対応する EARS 分類 |
| 正常系 AC | ○ | 各 Story に最低 1 件。Gherkin 形式 |
| 異常系 AC | ○ | 各 Story に最低 1 件。Gherkin 形式 |
| 信頼度レベル | ○ | 各 AC の見出しに [Blue] / [Yellow] / [Red] を付記 |
| Non-Goals | ○ | 最低 1 項目 |

### オプション要素

| 要素 | 条件 |
|------|------|
| NFR 紐付け | WHERE 制約がある Story のみ |
| 未解決事項 | インタビューで解決しなかった論点がある場合 |
| 依存関係 | Story 間に blockedBy / enables 関係がある場合 |

### ID 採番ルール

| ID | 形式 | 連番 | 例 |
|----|------|------|-----|
| P-XXX | 3 桁ゼロ埋め | ペルソナ登場順 | P-001, P-002 |
| Epic-XXX | 3 桁ゼロ埋め | Epic 定義順 | Epic-001, Epic-002 |
| US-XXX | 3 桁ゼロ埋め | ストーリー定義順（Epic をまたいで通し番号） | US-001, US-002 |
| AC-XXX-Y | Story 番号 + 連番 | 各 Story 内で連番 | AC-001-1, AC-001-2 |
| NFR-{CAT}-XXX | カテゴリ + 3 桁 | カテゴリ別連番 | NFR-PERF-001, NFR-SEC-001 |

### 信頼度の表記

- 見出し末尾に `[Blue]` / `[Yellow]` / `[Red]` を付記
- ペルソナ、ストーリー、AC それぞれに付与
- frontmatter の `confidence` に集計値を記載

## 中間成果物（docs/requirements/.work/）

| ファイル | 内容 | 生成タイミング |
|---------|------|--------------|
| `context_summary.md` | brownfield 分析結果（3 Agent の統合出力） | Step 1（brownfield のみ） |
| `interview_log.md` | インタビューの質問・回答・EARS 分類の記録 | Step 2 |
| `story_map.md` | ストーリーマップ（承認前の構造） | Step 3 |

中間成果物は `.gitignore` 対象とする（`docs/requirements/.work/` をプロジェクトの `.gitignore` に追加）。
