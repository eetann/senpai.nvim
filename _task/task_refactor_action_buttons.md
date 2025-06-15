# タスク
「action buttonsの描画場所の移動」のタスクを整理するためのチェックリストです。
チェックリストを作成したりタスクが増えたら、ユーザーの指示がなくても編集してください。
チェックリストのタスクが完了したらユーザーの指示がなくても編集してください。

## やりたいこと

lua/senpai/presentation/chat/window.lua の _render_action_buttonsについて。

- 現在はチャットのログウィンドウの下部に表示している
- これを、 lua/senpai/domain/i_block.lua のsetupのrendererみたいに「指定した行に表示」に変更したい
- `Rows`で表示してるけど、Columns(横並び)で表示するように変更したい

## 実装内容

### 第1段階の実装
- action buttonsの表示位置を**ウィンドウ下部固定**から**チャットログ末尾**に変更
- レイアウトを**縦並び（Rows）**から**横並び（Columns）**に変更
- ボタン間に適切な間隔を設定

### 第2段階の実装（IBlockを継承）
- `ActionButtonsBlock`クラスを新規作成し、`IBlock`を継承
- ボタンレンダリングロジックを`window.lua`から`ActionButtonsBlock`に移動
- `StickyPopupManager`に統合して他のブロックと同じように管理
- `_render_action_buttons`と`hide_action_buttons`メソッドを削除


## チェックリスト

`A: `のようにアルファベットのラベルをつけることで、参照しやすくする

### 1. タスク分解

- [x] A: タスク分解して2以降のチェックリストを書き換える

### 2. 位置指定の実装

- [x] A: rendererの作成をwin-relativeからbuf-relativeに変更（チャットログ末尾に表示）
- [x] B: log_areaバッファの最終行番号を取得して位置指定に使用

### 3. レイアウトの変更

- [x] A: Rowsコンポーネント（縦並び）からColumnsコンポーネント（横並び）に変更
- [x] B: ボタン間にGapコンポーネントを追加して適切な間隔を設定

### 4. テストと確認

- [x] A: 指定した行にアクションボタンが表示されることを確認
- [x] B: 横並びレイアウトが異なるボタン数でも正しく表示されることを確認

### 5. IBlockを継承した実装（追加タスク）

- [x] A: ActionButtonsBlockクラスを新規作成
- [x] B: StickyPopupManagerにaction_buttonsタイプを追加
- [x] C: show_action_buttonsメソッドを修正してStickyPopupManagerを使用
- [x] D: _render_action_buttonsとhide_action_buttonsメソッドを削除
- [x] E: テストを修正して新しい実装に対応
- [x] F: 全テストが通ることを確認
