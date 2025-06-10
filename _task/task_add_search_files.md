# タスク
「search_filesツールを実装する」のタスクを整理するためのチェックリストです。
チェックリストを作成したりタスクが増えたら、ユーザーの指示がなくても編集してください。
チェックリストのタスクが完了したらユーザーの指示がなくても編集してください。

## やりたいこと

- 追加したいツール `search_files`
- プロンプトは定義済み: src/usecase/agent/tool_prompt/getSearchFilesPrompt.ts
- 上記のプロンプトと doc/adding-tools.md に基づいて、ツールを追加したい
- blockで描画するもの
    - uiなしで、単純にパラメータをフォーマットして表示
        - "Senpai search for `bar` in directory `foo`:\n"という感じ
    - action_buttonはreplace_in_file_blockと同じく`accept`か`reject`だけ
    - acceptなら次の通り
        - サーバー側に実際に検索を実行をしてもらうリクエストを投げて結果を受けとる
            - lua/senpai/usecase/request/request_handler.lua の`request_without_callback`を使う
            - 参考: lua/senpai/usecase/request/get_thread_by_id.lua
        - サーバー側に結果を投げる
        - uiなしで、単純に受け取った内容をチャットログにコードブロックで出力
            - コードブロックの言語部分は`txt`で固定
- サーバー側の実際の検索の実行について
    - `/search_files`みたいなAPIで実行する
    - ripgrepがあればripgrepを使う。なければgrepを使う。
    - 500行以上あったら499行+`[truncated...]`とする

## チェックリスト

`A: `のようにアルファベットのラベルをつけることで、参照しやすくする

### 1. タスク分解

- [ ] A: タスク分解して2以降のチェックリストを書き換える

### 2. ここを書き換える

- [ ] A: ここを書き換える

### 3. ここを書き換える

- [ ] A: ここを書き換える...
