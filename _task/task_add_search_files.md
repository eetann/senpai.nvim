# タスク
「search_filesツールを実装する」のタスクを整理するためのチェックリストです。
チェックリストを作成したりタスクが増えたら、ユーザーの指示がなくても編集してください。
チェックリストのタスクが完了したらユーザーの指示がなくても編集してください。

## やりたいこと

- 追加したいツール `search_files`
- プロンプトは定義済み: src/usecase/agent/tool_prompt/getSearchFilesPrompt.ts
- 上記のプロンプトと doc/adding-tools.md に基づいて、ツールを追加したい
- blockで描画するもの
    - uiなしで、単純にパラメータを文章としてフォーマットして表示
        - "\nSenpai search for `bar` in directory `foo`:\n"という感じ
    - action_buttonはreplace_in_file_blockと同じく`accept`か`reject`だけ
    - acceptなら次の通り
        - サーバー側に実際に検索を実行をしてもらうリクエストを投げて結果を受けとる
            - lua/senpai/usecase/request/request_handler.lua の`request_without_callback`を使う
            - 参考: lua/senpai/usecase/request/get_thread_by_id.lua
        - サーバー側に結果を投げる(lua/senpai/usecase/message/action_result_renderer.luaで描画)
- サーバー側の実際の検索の実行について
    - `/search_files`みたいなAPIで実行する
    - ripgrepがあればripgrepを使う。なければgrepを使う。
    - 500行以上あったら499行+`[truncated...]`とする

## チェックリスト

`A: `のようにアルファベットのラベルをつけることで、参照しやすくする

### 1. タスク分解

- [x] A: タスク分解して2以降のチェックリストを書き換える

### 2. TypeScript側の実装

- [x] A: SearchFilesHandlerを作成 (src/usecase/getStreamProcessor/SearchFilesHandler.ts)
- [x] B: SearchFilesHandlerのテストを作成 (src/usecase/getStreamProcessor/SearchFilesHandler.test.ts)
- [x] C: GetStreamProcessorにSearchFilesHandlerを登録
- [x] D: /search_filesのAPIエンドポイントを作成 (src/presentation/chat.ts)
- [x] E: messageSchemaに型定義を追加

### 3. Lua側の実装

- [x] A: search_files_blockを作成 (lua/senpai/presentation/chat/search_files_block.lua)
- [x] B: i_block.luaにblock_type "search_files"を追加
- [x] C: message.luaにsenpai.chat.message.result.search_filesの型定義を追加
- [x] D: tool_result.luaにsearch_files用の処理を追加
- [x] E: sticky_popup_manager.luaにsearch_files_blockの登録を追加

### 4. Agent設定への追加

- [x] A: agent.luaの設定にsearch_filesを追加
- [x] B: agentSettingsSchema.tsにsearch_filesを追加
- [x] C: ChatAgent.tsでsearch_filesプロンプトを有効化

### 5. テスト

- [x] A: test_render_message_search_files.luaを作成
- [x] B: 統合テストの実行と確認
- [x] C: 実際にsearch_filesツールが動作することを確認

## 完了！

search_filesツールの実装が完了しました！

### 実装した内容

1. **TypeScript側**
   - SearchFilesHandler: XMLパーサーでsearch_filesタグを処理
   - テスト: XMLパースのテストケース6個
   - API: /chat/search_filesエンドポイント（ripgrep/grep対応、500行制限）
   - 型定義: search_files用のメッセージスキーマ

2. **Lua側**
   - search_files_block: UIレスブロック（accept/reject機能付き）
   - 型定義: search_files用のブロックと結果の型
   - tool_result: search_filesの結果表示処理
   - sticky_popup_manager: search_filesブロックの登録

3. **Agent設定**
   - Lua設定: auto_acceptでsearch_filesを設定可能
   - TypeScript設定: 自動承認のバリデーション処理
   - プロンプト: ChatAgentでsearch_filesプロンプトを有効化

4. **テスト**
   - TypeScript: SearchFilesHandlerの単体テスト
   - Lua: 4つのレンダリングテストケース

### 使用方法

AIエージェントは以下のような形でsearch_filesツールを使用できます：

```xml
<search_files>
<path>src</path>
<regex>function.*test</regex>
<file_pattern>*.ts</file_pattern>
</search_files>
```

ユーザーはaccept/rejectボタンで検索実行を制御でき、結果は最大499行で表示されます。
