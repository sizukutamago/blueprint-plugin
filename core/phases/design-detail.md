# Phase: Design Detail

画面詳細設計フェーズ。
画面一覧・API 設計の完了後に実行する。
画面詳細仕様、コンポーネントカタログ、エラーパターン、UI テスト戦略を定義する。

## Contract (YAML)

```yaml
phase_id: "6b"
required_artifacts:
  - docs/06_screen_design/screen_list.md          # design-inventory フェーズ
  - docs/06_screen_design/screen_transition.md     # design-inventory フェーズ
  - docs/05_api_design/api_design.md               # api フェーズ
  - decisions.screens                               # Blackboard
  - decisions.api_resources                         # Blackboard
  - decisions.architecture.nfr_policies             # Blackboard

outputs:
  - path: docs/06_screen_design/component_catalog.md
    required: true
  - path: docs/06_screen_design/error_patterns.md
    required: true
  - path: docs/06_screen_design/ui_testing_strategy.md
    required: true
  - path: docs/06_screen_design/details/screen_detail_SC-XXX.md
    required: true
    note: "全 SC-ID 分を生成"

contract_outputs:
  - key: traceability.api_to_sc
    type: object
    description: "API-ID から SC-ID への逆引きマッピング"
  - key: decisions.screens
    type: array
    description: "画面詳細情報（コンポーネント構成・状態管理を追加）"

quality_gates:
  - "screen_list.md の全 SC-ID に対応する screen_detail_SC-XXX.md が存在すること"
  - "全 screen_detail の API 連携セクションに定義された API-ID が api_design.md に存在すること"
  - "コンポーネントカタログに使用画面の SC-ID 参照があること"
```

## 入力要件

| 入力 | 必須 | 説明 |
|------|------|------|
| docs/06_screen_design/screen_list.md | ○ | 画面一覧（design-inventory フェーズ） |
| docs/06_screen_design/screen_transition.md | ○ | 画面遷移図（design-inventory フェーズ） |
| docs/05_api_design/api_design.md | ○ | API 設計（api フェーズ） |
| Blackboard: decisions.screens | ○ | 画面情報 |
| Blackboard: decisions.api_resources | ○ | API リソース情報 |
| Blackboard: decisions.architecture.nfr_policies | ○ | エラー形式等の NFR ポリシー |

## 出力ファイル

| ファイル | 説明 |
|---------|------|
| docs/06_screen_design/component_catalog.md | コンポーネントカタログ |
| docs/06_screen_design/error_patterns.md | エラー表示パターン |
| docs/06_screen_design/ui_testing_strategy.md | UI テスト戦略 |
| docs/06_screen_design/details/screen_detail_SC-XXX.md | 画面詳細（全 SC-ID 分） |

### 画面詳細ファイル生成ルール

**必須**: screen_list.md に定義した**全ての SC-ID** に対して、
`screen_detail_SC-XXX.md` を作成すること。

| チェック項目 | 説明 |
|-------------|------|
| 全 SC-ID カバー | screen_list.md の各 SC-ID に対応するファイル |
| モーダル含む | URL がなくても SC-ID があれば詳細作成 |
| 命名規則 | `screen_detail_SC-XXX.md`（3桁ゼロパディング） |

**完了条件**:
```
定義済 SC-ID 数 == details/screen_detail_SC-*.md ファイル数
```

## ワークフロー

```
1. 画面一覧・API 設計・Blackboard データを読み込み
2. 共通コンポーネントを抽出
3. コンポーネントカタログを生成
4. エラー表示パターンを定義（NFR ポリシー参照）
5. 各画面の詳細設計を生成（全 SC-ID 分）
6. SC → API トレーサビリティを記録
7. UI テスト戦略を策定
8. contract_outputs を出力
```

## 画面詳細テンプレート

```markdown
# SC-XXX: {画面名}

## 基本情報

| 項目 | 値 |
|------|-----|
| SC-ID | SC-XXX |
| 画面名 | {名前} |
| カテゴリ | {Auth/Member/Admin/...} |
| URL | {パス} |
| 認証 | 必要 / 不要 |
| 関連 FR | FR-XXX, FR-YYY |

## 画面レイアウト

### PC版
```
+------------------+
| [Header]         |
+------------------+
| [Main Content]   |
| ...              |
+------------------+
| [Footer]         |
+------------------+
```

### SP版
```
+----------+
| [Menu]   |
+----------+
| [Main]   |
+----------+
```

## コンポーネント構成

| コンポーネント | 用途 | Props |
|--------------|------|-------|
| Header | ナビゲーション | user, onLogout |
| UserForm | ユーザー入力 | initialValues, onSubmit |

## 状態管理

| 状態 | 型 | 初期値 | 更新タイミング |
|------|-----|-------|--------------|
| isLoading | boolean | false | API 呼び出し時 |
| error | string | null | エラー発生時 |

## ユーザー操作

| 操作 | アクション | API | 遷移先 |
|------|----------|-----|--------|
| 送信ボタン | submitForm | API-XXX | SC-YYY |
| キャンセル | cancel | - | SC-ZZZ |

## API 連携

| API-ID | メソッド | 用途 |
|--------|---------|------|
| API-001 | GET | データ取得 |
| API-002 | POST | データ登録 |

## エラーハンドリング

| エラー種別 | 表示方法 | メッセージ |
|-----------|---------|-----------|
| 入力エラー | インライン | フィールド横 |
| サーバーエラー | トースト | 再試行を促す |
```

## コンポーネントカタログ

### 優先度定義

| 優先度 | 定義 | 実装タイミング |
|--------|------|--------------|
| P0 | 必須、複数画面で使用 | Sprint 1 |
| P1 | 重要、主要機能で使用 | Sprint 2 |
| P2 | あれば便利 | Sprint 3+ |

### カタログ形式

```markdown
## Button

### バリエーション
- Primary: 主要アクション
- Secondary: 補助アクション
- Danger: 削除等の危険操作

### Props
| Prop | Type | Default | Description |
|------|------|---------|-------------|
| variant | 'primary' \| 'secondary' \| 'danger' | 'primary' | スタイル |
| disabled | boolean | false | 無効化 |
| loading | boolean | false | ローディング表示 |

### 使用画面
SC-001, SC-002, SC-005, ...
```

## エラー表示パターン

architecture-detail で定義されたエラー形式（RFC7807 等）に基づき、
UI での表示パターンを定義する。

| エラー種別 | HTTP | UI 表示 | コンポーネント |
|-----------|------|---------|--------------|
| 入力エラー | 400 | インライン | FormError |
| 認証エラー | 401 | モーダル | AuthErrorModal |
| 権限エラー | 403 | ページ | ErrorPage |
| 未発見 | 404 | ページ | NotFoundPage |
| サーバーエラー | 5xx | トースト | ErrorToast |

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| API 未定義参照 | P1 報告、api フェーズへ差し戻し |
| 画面一覧と不整合 | P1 報告、design-inventory 確認 |
| コンポーネント抽出漏れ | P2 報告、追加 |
| SC-ID ファイル不足 | 自動生成を試み、失敗したら P1 報告 |
