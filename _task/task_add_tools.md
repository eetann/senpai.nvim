# タスク
「AIコーディングエージェントに別のツールの追加」のタスクを整理するためのチェックリストです。
チェックリストを作成したりタスクが増えたら、ユーザーの指示がなくても編集してください。
チェックリストのタスクが完了したらユーザーの指示がなくても編集してください。

## やりたいこと

AIコーディングエージェントで、「プロンプトで指示した形式のXMLタグ」を返したらツールとみなしてパースし、そのToolResultとして返す。フロント側ではそのToolResultに対応したブロックを表示する。このツールで新たに追加したい物がある。

- 追加したいツール `ask_followup_question`
- プロンプトは定義済み: src/usecase/agent/tool_prompt/getAskFollowupQuestionPrompt.ts
- 上記のプロンプトに基づいてサーバー側のパーサー、フロント側のブロックを実装したい
- 参考
    - パーサーの抽象クラス: src/usecase/getStreamProcessor/AbstractHandler.ts
    - パーサー: src/usecase/getStreamProcessor/ExecuteCommandHandler.ts
        - `Part.toolResult`としてタグの内容を返す
    - パーサーのテスト: src/usecase/getStreamProcessor/ExecuteCommandHandler.test.ts
    - フロント側のtool_result受取: lua/senpai/usecase/message/tool_result.lua
    - ブロックの抽象クラス・型: lua/senpai/domain/i_block.lua
    - Blockの実装: lua/senpai/presentation/chat/execute_command_block.lua
    - ※ replace_in_fileはほかよりも複雑で関係する実装が多岐にわたるので、execute_commandを参考にする
- 他にもツールを実装予定なので、まずは「ツール」はどうやって実装するのかをドキュメントとして英語でまとめておきたい
    - 他の開発者が見ても分かるようなドキュメントを書きたい
    - 処理の流れ(AIから受け取ったものをパーサーで処理して……から始まるような感じ)
    - 定義するディレクトリの場所
    - 参考になるファイル(上記に記述したようなファイル群)


## チェックリスト

`A: `のようにアルファベットのラベルをつけることで、参照しやすくする

### 1. タスク分解

- [x] A: タスク分解して2以降のチェックリストを書き換える

### 2. ドキュメント作成

- [x] A: ツール実装の全体的な流れをドキュメント化（英語）
- [x] B: 実装に必要なファイルとディレクトリ構造の説明を追加
- [x] C: 参考になるファイル一覧と役割の説明を追加
- [x] D: 新しいツールを追加する際のステップバイステップガイドを作成

### 3. ask_followup_question ツールの実装（サーバー側）

- [ ] A: getAskFollowupQuestionPrompt.tsの内容を確認してXMLタグ名を特定
- [ ] B: AskFollowupQuestionHandler.tsを作成（AbstractHandlerを継承）
- [ ] C: AskFollowupQuestionHandler.test.tsでユニットテストを作成
- [ ] D: GetStreamProcessor.tsにハンドラーを登録
- [ ] E: messageSchema.tsに必要な型定義を追加（必要に応じて）

### 4. ask_followup_question ツールの実装（フロント側）

- [ ] A: ask_followup_question_block.luaを作成（IBlockを継承）
- [ ] B: i_block.luaにblock_typeと型定義を追加
- [ ] C: tool_result.luaにask_followup_questionの処理を追加
- [ ] D: UIデザインとアクションボタンの実装
- [ ] E: Luaテストファイルを作成（test_render_message_ask_followup_question.lua）

### 5. 統合テストと動作確認

- [ ] A: 開発サーバーを起動して動作確認
- [ ] B: AIがask_followup_questionタグを生成することを確認
- [ ] C: UIブロックが正しく表示されることを確認
- [ ] D: アクションボタンが期待通りに動作することを確認
- [ ] E: エッジケースのテスト（エラー処理、空の内容など）
