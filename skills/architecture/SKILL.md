---
name: architecture
description: This skill should be used when the user asks to "design system architecture", "create ADR", "plan infrastructure", "design security", "define caching strategy", "select technology stack", or "document architecture decisions". Designs system architecture, security controls, infrastructure, and caching strategies.
version: 1.0.0
---

# Architecture Skill

システムアーキテクチャ・セキュリティ・インフラ・キャッシュを設計するスキル。
システム構成設計、技術選定、セキュリティ対策、キャッシュレイヤー定義、
インフラ構成の文書化に使用する。技術選定はADRとして記録する。

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| docs/02_requirements/non_functional_requirements.md | ○ | NFR（パフォーマンス要件等） |
| docs/02_requirements/functional_requirements.md | △ | 機能規模の把握 |

## 出力ファイル

| ファイル | テンプレート | 説明 |
|---------|-------------|------|
| docs/03_architecture/architecture.md | {baseDir}/references/architecture.md | システム構成 |
| docs/03_architecture/adr.md | {baseDir}/references/adr.md | 技術選定記録 |
| docs/03_architecture/security.md | {baseDir}/references/security.md | セキュリティ設計 |
| docs/03_architecture/infrastructure.md | {baseDir}/references/infrastructure.md | インフラ構成 |
| docs/03_architecture/cache_strategy.md | {baseDir}/references/cache_strategy.md | キャッシュ戦略 |

## 依存関係

| 種別 | 対象 |
|------|------|
| 前提スキル | requirements |
| 後続スキル | implementation |

## ADR ID採番ルール

| 項目 | ルール |
|------|--------|
| 形式 | ADR-XXXX（4桁ゼロパディング） |
| 開始 | 0001 |

## ワークフロー

```
1. 非機能要件・技術制約を読み込み
2. アーキテクチャパターンを選定
3. 技術スタックを決定（ADRとして記録）
4. システム構成図を作成（Mermaid）
5. セキュリティ設計
6. キャッシュ戦略設計
7. インフラ設計
```

## アーキテクチャパターン

| タイプ | パターン |
|--------|---------|
| webapp | SPA + BFF |
| mobile | Client-Server |
| api | Microservices / Modular Monolith |
| batch | Event-Driven |

## ADRテンプレート

```markdown
### ADR-0001: [タイトル]

#### コンテキスト
[背景・課題]

#### 決定
[決定内容]

#### 理由
[決定理由]

#### 代替案
| 代替案 | 却下理由 |
|--------|----------|

#### 影響
[影響・トレードオフ]
```

## セキュリティ設計

### 認証

| 項目 | 推奨 |
|------|------|
| 方式 | JWT (RS256) |
| アクセストークン | 15分 |
| リフレッシュトークン | 7日 |

### 脆弱性対策

| 脅威 | 対策 |
|------|------|
| XSS | CSP, サニタイズ |
| CSRF | SameSite Cookie |
| SQL Injection | パラメータ化クエリ |

## 認証パターン実装例

**重要**: 以下のパターンは「そのまま採用」されやすいため、前提条件を必ず確認すること。

### 前提：脅威モデルの明確化

実装前に以下を決定し、ADR に記録する:

| 項目 | 選択肢 | セキュリティ影響 |
|------|--------|-----------------|
| アプリ種別 | SPA / SSR / ネイティブ | トークン保存戦略が変わる |
| 同一サイト | 同一ドメイン / サブドメイン / クロスサイト | Cookie の SameSite 設定 |
| 攻撃者モデル | XSS / CSRF / MitM / 内部犯行 | 防御優先度 |

### JWT認証フロー

```
┌─────────┐     ┌─────────┐     ┌─────────┐
│ Client  │     │   API   │     │  Auth   │
└────┬────┘     └────┬────┘     └────┬────┘
     │ 1. Login      │               │
     │──────────────>│ 2. Validate   │
     │               │──────────────>│
     │               │ 3. Tokens     │
     │               │<──────────────│
     │ 4. Access + Refresh Token     │
     │<──────────────│               │
     │               │               │
     │ 5. API Request (Bearer Token) │
     │──────────────>│               │
     │ 6. Response   │               │
     │<──────────────│               │
```

### トークン管理戦略

| トークン | 保存場所 | 有効期限 | 用途 |
|---------|---------|---------|------|
| Access Token | メモリ（推奨）/ httpOnly Cookie | 15分 | API認証 |
| Refresh Token | httpOnly Cookie（Secure, SameSite=Strict） | 7日 | Access Token再発行 |

### トークン保存の推奨/非推奨

| 方法 | 推奨度 | 理由 |
|------|--------|------|
| **メモリ（変数）** | ✅ 推奨 | XSS でも直接アクセス困難、ただしリロードで消失 |
| **httpOnly Cookie** | ✅ 推奨 | JS からアクセス不可、ただし CSRF 対策必須 |
| **localStorage** | ⚠️ 非推奨 | XSS で容易に窃取される（永続化が必要な場合のみ） |
| **sessionStorage** | ⚠️ 条件付き | タブごとに分離、XSS リスクは localStorage と同等 |

**httpOnly Cookie 使用時の CSRF 対策:**
- `SameSite=Strict` または `SameSite=Lax` を設定
- 状態変更 API には CSRF トークン検証を追加
- `Origin` / `Referer` ヘッダーの検証

### JWT 署名検証（サーバーサイド必須）

```typescript
// lib/auth/jwtVerify.ts
import { jwtVerify, JWTVerifyOptions } from 'jose';

const JWT_OPTIONS: JWTVerifyOptions = {
  algorithms: ['RS256'],        // アルゴリズム固定（alg: "none" 攻撃防止）
  issuer: 'https://auth.example.com',
  audience: 'https://api.example.com',
  clockTolerance: 30,           // 時刻ずれ許容（秒）
};

async function verifyAccessToken(token: string): Promise<JWTPayload> {
  const { payload } = await jwtVerify(token, publicKey, JWT_OPTIONS);

  // 追加検証
  if (!payload.sub) throw new AuthError('MISSING_SUBJECT');
  if (payload.exp && payload.exp < Date.now() / 1000) {
    throw new AuthError('TOKEN_EXPIRED');
  }

  return payload;
}
```

**検証項目チェックリスト:**
- [ ] `alg` を許可リストで固定（`none`, `HS256` の誤用防止）
- [ ] `iss` (発行者) の完全一致
- [ ] `aud` (対象者) の完全一致
- [ ] `exp` (有効期限) + clock skew 考慮
- [ ] `nbf` (有効開始) の検証（あれば）

### 鍵管理とローテーション

| 項目 | 推奨 |
|------|------|
| 鍵の種類 | RS256（公開鍵暗号）、HS256 は共有シークレット漏洩リスク |
| 鍵識別子 | `kid` ヘッダーで鍵を特定 |
| JWK 取得 | `/.well-known/jwks.json` から取得、キャッシュ + 定期更新 |
| ローテーション | 古い鍵は猶予期間後に無効化、新しい鍵を先に配布 |

### トークン失効戦略

| 戦略 | メリット | デメリット |
|------|----------|-----------|
| 短命トークン + リフレッシュ | シンプル、DB 不要 | 即時失効不可 |
| ブラックリスト | 即時失効可能 | DB 参照コスト、スケール困難 |
| バージョニング | ユーザー単位で一括失効 | 全デバイスログアウト |

**推奨**: 短命（15分）+ リフレッシュトークンローテーション

### リフレッシュフロー実装例

```typescript
// lib/auth/tokenRefresh.ts
async function refreshTokens(): Promise<Tokens> {
  const response = await fetch('/api/auth/refresh', {
    method: 'POST',
    credentials: 'include', // Cookie送信
  });

  if (!response.ok) {
    // リフレッシュ失敗 → 再ログイン誘導
    throw new AuthError('SESSION_EXPIRED');
  }

  return response.json();
}

// Axios インターセプター例
axios.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401 && !error.config._retry) {
      error.config._retry = true;
      await refreshTokens();
      return axios(error.config);
    }
    return Promise.reject(error);
  }
);
```

### OAuth2連携パターン

| 項目 | 推奨設定 | 非推奨（なぜ危険か） |
|------|---------|---------------------|
| 認可フロー | Authorization Code + PKCE | Implicit Flow（トークンがURLに露出） |
| スコープ | 最小権限の原則 | 全スコープ要求（過剰な権限） |
| State パラメータ | 必須（CSRF対策） | 省略（CSRF攻撃に脆弱） |
| Nonce | ID Token 検証時に必須 | 省略（リプレイ攻撃に脆弱） |
| リダイレクトURI | 完全一致で検証 | ワイルドカード許可（オープンリダイレクト） |
| トークン保存 | サーバーサイドセッション | クライアント localStorage |

### OAuth2 セキュリティチェックリスト

**認可リクエスト時:**
- [ ] `state` をセッションに保存し、コールバックで検証
- [ ] `nonce` を生成し、ID Token の `nonce` クレームと照合
- [ ] `code_verifier` を生成し、`code_challenge` を送信（PKCE）
- [ ] `redirect_uri` を環境変数から取得（ハードコードしない）

**コールバック処理時:**
- [ ] `state` の一致を最初に検証（CSRF防止）
- [ ] `code` を `code_verifier` と共にトークンエンドポイントへ送信
- [ ] ID Token の署名、`iss`, `aud`, `exp`, `nonce` を検証
- [ ] トークンはサーバーサイドセッションに保存

### Refresh Token ローテーション

```typescript
// lib/auth/refreshWithRotation.ts
async function refreshWithRotation(oldRefreshToken: string): Promise<Tokens> {
  const response = await fetch('/api/auth/refresh', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refresh_token: oldRefreshToken }),
  });

  if (!response.ok) {
    // リフレッシュトークンが無効 → 全セッション無効化を検討
    if (response.status === 401) {
      throw new AuthError('REFRESH_TOKEN_REVOKED');
    }
    throw new AuthError('REFRESH_FAILED');
  }

  const { access_token, refresh_token } = await response.json();

  // 新しいリフレッシュトークンを保存（古いものは即座に無効化される）
  return { accessToken: access_token, refreshToken: refresh_token };
}
```

**ローテーションのメリット:**
- リフレッシュトークン漏洩時の被害を限定
- 古いトークンの再利用を検出可能（不正アクセスの兆候）

```typescript
// lib/auth/crypto.ts - セキュリティユーティリティ
function generateSecureRandom(length = 32): string {
  const array = new Uint8Array(length);
  crypto.getRandomValues(array);
  return Array.from(array, (b) => b.toString(16).padStart(2, '0')).join('');
}

function generateCodeVerifier(): string {
  return generateSecureRandom(32); // 43-128文字のランダム文字列
}

function generateCodeChallenge(verifier: string): string {
  const encoder = new TextEncoder();
  const data = encoder.encode(verifier);
  // SHA-256 ハッシュ → Base64URL エンコード
  return crypto.subtle.digest('SHA-256', data).then((hash) =>
    btoa(String.fromCharCode(...new Uint8Array(hash)))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/, '')
  );
}

// OAuth2 認可URL生成例
function buildAuthUrl(provider: 'google' | 'github'): string {
  const state = generateSecureRandom();
  const codeVerifier = generateCodeVerifier();
  const codeChallenge = generateCodeChallenge(codeVerifier);

  // セッションに保存（検証用）
  session.set('oauth_state', state);
  session.set('code_verifier', codeVerifier);

  return buildUrl(OAUTH_CONFIG[provider].authorizationEndpoint, {
    client_id: OAUTH_CONFIG[provider].clientId,
    redirect_uri: OAUTH_CONFIG[provider].redirectUri,
    response_type: 'code',
    scope: OAUTH_CONFIG[provider].scopes.join(' '),
    state,
    code_challenge: codeChallenge,
    code_challenge_method: 'S256',
  });
}
```

### ログアウト・トークン無効化戦略

| 操作 | クライアント側 | サーバー側 |
|------|--------------|-----------|
| ログアウト | メモリ上のトークン削除 | Refresh Token を無効化リストに追加 |
| セッション終了 | Cookie クリア | セッションストアから削除 |
| 強制ログアウト | - | 全デバイスの Refresh Token を無効化 |

```typescript
// lib/auth/logout.ts
async function logout(): Promise<void> {
  // 1. サーバーにログアウト通知（Refresh Token 無効化）
  await fetch('/api/auth/logout', {
    method: 'POST',
    credentials: 'include',
  });

  // 2. クライアント側のトークンをクリア
  tokenStore.clear();

  // 3. ログイン画面へリダイレクト
  window.location.href = '/login';
}

// サーバー側: Refresh Token 無効化
async function handleLogout(req: Request): Promise<Response> {
  const refreshToken = req.cookies.get('refresh_token');

  if (refreshToken) {
    // 無効化リスト（Redis等）に追加、または DB から削除
    await tokenBlacklist.add(refreshToken, { expiresAt: TOKEN_EXPIRY });
  }

  return new Response(null, {
    status: 204,
    headers: {
      'Set-Cookie': 'refresh_token=; Max-Age=0; HttpOnly; Secure; SameSite=Strict',
    },
  });
}
```

## キャッシュ戦略設計

### レイヤー別キャッシュ

| レイヤー | 技術 | 用途 |
|---------|------|------|
| ブラウザ | Cache-Control, ETag | 静的アセット |
| CDN | CloudFront, Cloudflare | 静的ファイル、API応答 |
| アプリケーション | Redis, Memcached | セッション、APIレスポンス |
| データベース | クエリキャッシュ | 頻繁なクエリ結果 |

### キャッシュ無効化戦略

| 戦略 | 用途 |
|------|------|
| TTL（時間ベース） | 定期更新データ |
| イベント駆動 | データ変更時の即時反映 |
| バージョニング | 静的アセットの更新 |

## インフラ設計

| 項目 | 目標 |
|------|------|
| 稼働率 | 99.9% |
| RTO | 1時間 |
| RPO | 5分 |

## エラーハンドリング設計

システム全体のエラーハンドリング戦略を定義する。
UIレイヤー（design/error_patterns.md）と整合させる。

### HTTPエラーレスポンス戦略

| エラー種別 | HTTPステータス | レスポンス戦略 | UI表示パターン |
|-----------|---------------|---------------|---------------|
| 入力エラー | 400 Bad Request | フィールド別エラー詳細返却 | インラインバリデーション |
| 認証エラー | 401 Unauthorized | リフレッシュトークンフロー | 再認証誘導 |
| 権限エラー | 403 Forbidden | 権限不足の詳細メッセージ | エラーページ/モーダル |
| リソース不在 | 404 Not Found | リソース種別の明示 | 代替候補の提示 |
| 業務ルール違反 | 422 Unprocessable Entity | ルール違反詳細 | ガイダンス表示 |
| サーバーエラー | 5xx | エラーID + 簡潔メッセージ | リトライ誘導 |

### リトライ戦略

| 対象 | 戦略 | 設定 |
|------|------|------|
| 冪等操作（GET, PUT, DELETE） | 自動リトライ | 最大3回、Exponential Backoff |
| 非冪等操作（POST） | 手動リトライ | ユーザー確認後のみ |
| ネットワークエラー | 自動リトライ | 最大3回、指数バックオフ |
| タイムアウト | 条件付きリトライ | 冪等性に応じて判断 |

### エラーロギング・監視

| 項目 | 内容 |
|------|------|
| エラーID | UUID形式でリクエストを一意に識別 |
| ログレベル | 4xx: WARN, 5xx: ERROR |
| アラート | 5xxエラー率が閾値超過時 |

## コンテキスト更新

```yaml
phases:
  architecture:
    status: completed
    files:
      - docs/03_architecture/architecture.md
      - docs/03_architecture/adr.md
      - docs/03_architecture/security.md
      - docs/03_architecture/infrastructure.md
      - docs/03_architecture/cache_strategy.md
id_registry:
  adr: [ADR-0001, ADR-0002, ...]
```

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| NFR 不在 | デフォルト推奨値で設計、WARNING を記録 |
| 技術スタック未定義 | ヒアリング結果から推測、ADR で記録 |
| 矛盾するNFR | トレードオフを ADR に記録 |
