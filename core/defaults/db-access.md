# DB アクセス規約

## 基本方針

- **Repository パターン**: DB アクセスを Repository に閉じ込める。
- **ORM 依存は infra 層のみ**: domain/usecase から ORM を直接呼ばない。
- **トランザクション**: Contract の `implementation.transaction` に従う。

## Repository パターン

### Clean Architecture

```typescript
// domain/order/order.repository.ts（interface）
export interface OrderRepository {
  save(order: Order): Promise<Order>
  findById(id: string): Promise<Order | null>
  findByUserId(userId: string): Promise<Order[]>
}

// infra/order/order.repository.impl.ts（実装）
export class OrderRepositoryDrizzle implements OrderRepository {
  constructor(private readonly db: DrizzleDatabase) {}

  async save(order: Order): Promise<Order> {
    // Drizzle 固有のコード
  }
}
```

### Layered

```typescript
// services/order.service.ts
// サービス内で直接 DB アクセス（Repository 分離なし）
export class OrderService {
  constructor(private readonly db: DrizzleDatabase) {}

  async createOrder(input: CreateOrderInput): Promise<Order> {
    return this.db.insert(orders).values(input).returning()
  }
}
```

## トランザクション

Contract の `implementation.transaction: [2, 3, 4]` に対応:

```typescript
// トランザクションの実装パターン
await db.transaction(async (tx) => {
  // step 2, 3, 4 をこの中で実行
  const products = await tx.select().from(productsTable)...
  // ...
})
```

## ルール

| ルール | 理由 |
|--------|------|
| SELECT FOR UPDATE は notes に明記 | data_source.notes で指定された場合のみ使用 |
| バルク操作は batch で | 1 行ずつ INSERT しない |
| N+1 問題を避ける | JOIN or IN で一括取得 |
| マイグレーションは生成しない | スキーマ管理は /implement の範囲外 |
