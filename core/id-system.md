# ID 採番規約

## ID プレフィックス一覧

| プレフィックス | 用途 | 形式 | 採番元フェーズ | 例 |
|---------------|------|------|-------------|-----|
| FR | 機能要件 | FR-XXX (3桁) | web-requirements | FR-001, FR-042 |
| NFR | 非機能要件 | NFR-{CAT}-XXX | web-requirements | NFR-PERF-001 |
| SC | 画面 | SC-XXX (3桁) | design-inventory | SC-001 |
| API | API リソース | API-XXX (3桁) | api | API-001 |
| ENT | エンティティ | ENT-{PascalCase} | database | ENT-User, ENT-OrderItem |
| ADR | 設計決定記録 | ADR-XXXX (4桁) | architecture-skeleton/detail | ADR-0001 |

## NFR カテゴリ

| カテゴリ | コード | 例 |
|---------|--------|-----|
| パフォーマンス | PERF | NFR-PERF-001 |
| セキュリティ | SEC | NFR-SEC-001 |
| 可用性 | AVL | NFR-AVL-001 |
| スケーラビリティ | SCL | NFR-SCL-001 |
| 保守性 | MNT | NFR-MNT-001 |
| 運用 | OPR | NFR-OPR-001 |
| 互換性 | CMP | NFR-CMP-001 |
| アクセシビリティ | ACC | NFR-ACC-001 |

## 採番ルール

1. **名前空間分離**: 各フェーズが担当する ID プレフィックスは重複しない
2. **連番**: 同一プレフィックス内で連番（欠番なし）
3. **不変性**: 一度採番された ID は変更・再利用しない
4. **参照整合性**: ID を参照する際は必ず採番元フェーズの出力に存在することを確認

## Blackboard での ID 管理

```yaml
id_registry:
  fr:
    next: 1          # 次に採番する番号
    allocated: []     # 採番済みリスト
  nfr:
    next: 1
    allocated: []
  sc:
    next: 1
    allocated: []
  api:
    next: 1
    allocated: []
  ent:
    allocated: []     # PascalCase なので next 不要
  adr:
    next: 1
    allocated: []
```
