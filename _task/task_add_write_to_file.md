# タスク
「write_to_fileツールの実装」のタスクを整理するためのチェックリストです。
チェックリストを作成したりタスクが増えたら、ユーザーの指示がなくても編集してください。
チェックリストのタスクが完了したらユーザーの指示がなくても編集してください。

## やりたいこと

- 追加したいツール `write_to_file`
- プロンプトは定義済み: src/usecase/agent/tool_prompt/getWriteToFilePrompt.ts
- 上記のプロンプトと doc/adding-tools.md に基づいて、ツールを追加したい
- Blockで描画するもの
    - UIなしで、単純に受け取った内容をチャットログにコードブロックで出力
        - コードブロックの言語部分の取得は lua/senpai/presentation/chat/replace_in_file_block.lua のように utils.get_filetype を使えばよい
    - action_buttonはreplace_in_file_blockと同じく`Accept`か`Reject`だけ
    - acceptなら次の通り
        - ディレクトリが存在しなければ作る
        - `vim.cmd("wincmd h")`
        - `edit そのファイルのパス`で新しいバッファを開く
        - フォーカスをもとに戻す
        - バッファに書き込む


## チェックリスト

`A: `のようにアルファベットのラベルをつけることで、参照しやすくする

### 1. タスク分解

- [x] A: タスク分解して2以降のチェックリストを書き換える

### 2. TypeScript側の実装（サーバー側）

- [ ] A: WriteToFileHandler.ts を作成（XMLパーサー）
    - タグ名: `write_to_file`、ツール名: `WriteToFile`
    - `<path>`と`<content>`サブタグの処理
    - 結果として`{ path: string, content: string }`を返す
- [ ] B: WriteToFileHandler.test.ts でテストを作成
- [ ] C: GetStreamProcessor.ts にハンドラーを登録
- [ ] D: ChatAgent.ts にgetWriteToFilePromptを追加

### 3. Lua側の実装（クライアント側）

- [ ] A: write_to_file_block.lua を作成
    - UIなし（`has_ui()`は`false`）
    - コードブロックとして表示
    - action_buttonsは`Accept`と`Reject`
    - Acceptの処理実装
- [ ] B: i_block.lua に`"write_to_file"`を型定義に追加
- [ ] C: message.lua に`senpai.chat.message.result.write_to_file`型を追加
- [ ] D: tool_result.lua にブロックを登録

### 4. テストとデバッグ

- [ ] A: test_render_message_write_to_file.lua でLuaテストを作成
- [ ] B: 全体的な動作確認（dev環境で実際に試す）
- [ ] C: バグ修正と調整
