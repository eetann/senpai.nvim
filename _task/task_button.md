# タスク
「アクションボタンを横並びから縦並びへ変更する」のタスクを整理するためのチェックリストです。
チェックリストを作成したりタスクが増えたら、ユーザーの指示がなくても編集してください。
チェックリストのタスクが完了したらユーザーの指示がなくても編集してください。

## やりたいこと

- lua/senpai/presentation/chat/window.lua の `_render_action_buttons`で表示するボタンを縦並びにしたい
    - `Columns`じゃなくて`Rows`を使えばよさそう
- 今までは1行だったから`row = vim.api.nvim_win_get_height(self.log_area.winid) - 1`だった
    - これからは今までのrowから更に「ボタンの数」を引いてほしい


## チェックリスト

`A: `のようにアルファベットのラベルをつけることで、参照しやすくする

### 1. タスク分解

- [x] A: タスク分解して2以降のチェックリストを書き換える

### 2. window.luaにRowsをrequireする

- [ ] B: `local Rows = require("nui-components.rows")` を追加する

### 3. _render_action_buttonsでColumnsをRowsに変更

- [ ] C: 427行目の `Columns` を `Rows` に変更する

### 4. レイアウト調整（rowとheight）

- [ ] D: row計算を「ウィンドウ高さ - 1 - ボタン数」に変更する
- [ ] E: heightをボタン数に変更する
