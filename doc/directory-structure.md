# ディレクトリ構成

```
.
│
├── src/ # エージェントのメインロジック(TypeScript)
│   ├── domain/
│   ├── usecase/
│   ├── infra/
│   ├── presentation/
│   └── index.ts
│
├── lua/senpai # neovimのプラグイン(Lua)
│   ├── domain/
│   ├── usecase/
│   ├── infra/
│   ├── presentation/
│   └── init.lua
│
├── /tests # Neovimを使ったE2Eテスト(Lua)
│
├── /doc   # 設計仕様や技術的な文書
└── README.md
```


## 説明
- **srcディレクトリ**:
  - **domain**: ドメイン知識を表現
  - **usecase**: アプリケーションロジックを実装
  - **infra**: データアクセス・外部サービスを抽象化
  - **presentation**: ユーザーインターフェースの実装
