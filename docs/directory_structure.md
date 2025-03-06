# ディレクトリ構成案（TypeScriptプロジェクト）

```
/senmai.nvim
│
├── /src
│   ├── /domain              # ドメインロジックを含む
│   ├── /usecase             # ユースケースを実現するためのアプリケーションロジック
│   ├── /infrastructure      # インフラ関連（データベース、外部APIなどの接続）
│   ├── /presentation        # ユーザーとのインターフェースを扱う
│   └── main.ts              # メインエントリーポイント
│
├── /tests                   # テストコードとフィクスチャ
│   └── example.test.ts      # テストファイル例
│
├── /docs                    # 設計仕様や技術的な文書
└── README.md                # プロジェクトの概要とセットアップガイド
```

## 説明
- **srcディレクトリ**:
  - **domain**: ドメインロジックをTypeScriptで表現。
  - **usecase**: アプリケーションロジックを実装。
  - **infrastructure**: データアクセス・外部サービスを抽象化。
  - **presentation**: ユーザーインターフェースの実装。
