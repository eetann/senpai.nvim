# ディレクトリ構成案（TypeScriptプロジェクト）

```
.
│
├── denops/senpai/ # エージェントのメインロジック
│   ├── domain/
│   ├── usecase/
│   ├── infrastructure/
│   ├── presentation/
│   └── main.ts
│
├── lua/senpai # neovimのプラグイン
│   ├── domain/
│   ├── usecase/
│   ├── infrastructure/
│   ├── presentation/
│   └── init.lua
│
├── /tests # Neovimを使ったE2Eテスト
│
├── /doc   # 設計仕様や技術的な文書
└── README.md
```

## 説明
- **srcディレクトリ**:
  - **domain**: ドメインロジックをTypeScriptで表現。
  - **usecase**: アプリケーションロジックを実装。
  - **infrastructure**: データアクセス・外部サービスを抽象化。
  - **presentation**: ユーザーインターフェースの実装。
