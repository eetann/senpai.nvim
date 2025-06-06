# タスク
「stickyを限定的に使う実装への変更」のタスクを整理するためのチェックリストです。
チェックリストを作成したりタスクが増えたら、ユーザーの指示がなくても編集してください。
チェックリストのタスクが完了したらユーザーの指示がなくても編集してください。

## やりたいこと

- lua/senpai/presentation/chat/execute_command_block.lua でbodyとrendererが要らなくなった
- でもこれを管理してる lua/senpai/presentation/chat/sticky_popup_manager.lua はそれがある前提で作ってる
- 継承元である lua/senpai/domain/i_block.lua も同様に前提で作ってる
- なので、body・rendererというnui-componentsによるpopupが不要なblockも作れるようにしたい
- lua/senpai/presentation/chat/replace_in_file_block.lua のように引き続き必要なやつはある


## チェックリスト

`A: `のようにアルファベットのラベルをつけることで、参照しやすくする

### 1. タスク分解

- [x] A: タスク分解して2以降のチェックリストを書き換える

### 2. 現状分析と設計決定

- [x] A: execute_command_blockの本当の要件を確認する（UIレスにしたい理由を明確化）
  - window.luaがget_action_buttons()とhandle_action()を使ってボタンを描画
  - 最後のAIメッセージのツールだけボタン表示するロジックあり
- [x] B: UIを持つブロックと持たないブロックの具体的な使い分けを決める
  - UIレス: アクションボタンのみ（execute_command_block）
  - UI付き: 常時表示UI必要（replace_in_file_block）
- [x] C: 既存のブロック（replace_in_file_block等）への影響を評価する
  - UIレスブロックはvirtual_blank_line不要（早期リターン）
  - sticky_popup_managerにUIチェック追加で対応可能
  - replace_in_file_blockへの影響なし（低リスク）

### 3. インターフェース設計

- [x] A: has_ui()メソッドをi_block.luaに追加する
  - デフォルトtrueで後方互換性確保
- [x] B: UI関連メソッドをオプショナルにする実装を追加
  - setup、mount、unmount、show、hide、focus、is_focused、map、set_size、get_widthにガード追加
- [-] C: 基本インターフェース(IBlockBase)とUI付きインターフェース(IUIBlock)の分離を検討
  - 現時点では不要と判断（has_ui()で十分）

### 4. sticky_popup_managerの修正

- [x] A: update_float_position()にUI存在チェックを追加
  - UIレスブロックはスキップ
  - add_virtual_blank_lineもUIありの時のみ実行
- [x] B: find_row_index_by_winid()の修正
  - UIレスブロックはスキップ
- [x] C: jump_to_next()/jump_to_prev()の修正
  - UIレスブロックはfocusしない
  - find_next/prev_popup_rowもUIレスブロックをスキップ
- [ ] D: テストケースの追加・修正（後回し）

### 5. execute_command_blockのリファクタリング

- [x] A: UIレス実装の詳細設計
  - has_ui()をfalseでオーバーライド
  - setup_body()を空実装に
  - open_result_popup()は削除（window.lua側で処理）
  - execute_command_in_term()、get_action_buttons()、handle_action()は保持
- [x] B: 実装とテスト
  - has_ui()をfalse返却に実装
  - UIコンポーネント関連のコード削除
  - コマンド実行とアクション処理は保持
- [ ] C: 他の部分との統合テスト

### 6. ドキュメント更新とクリーンアップ

- [ ] A: 変更内容のドキュメント化
- [ ] B: 不要になったコードの削除
- [ ] C: 最終テスト
