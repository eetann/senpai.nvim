# タスク
「replace_in_fileの後にLSPやLinterのdiagnocticsが出るまでまって、なにか出たらそれをAIに送る」のタスクを整理するためのチェックリストです。
チェックリストを作成したりタスクが増えたら、ユーザーの指示がなくても編集してください。
チェックリストのタスクが完了したらユーザーの指示がなくても編集してください。

## やりたいこと

- 現状の replace_in_fileのファイル
    - lua/senpai/presentation/chat/replace_in_file_block.lua
    - `handle_action`の`vim.cmd("write")`の後にすぐに成功メッセージを送る
- やりたい流れ
    - `write`して、その後に走るLSPやLinterのdiagnocticsの走査が終わるまでまち、もしエラーがでたら`success: true`だけど`message`としてなにか送る
- 疑問
    - Neovimで、`diagnoctics`の走査を待つにはどういった処理をすればいいのか？

## 調査結果

### 他のAIプラグインの実装調査

#### yetone/avante.nvim
- **DiagnosticChangedイベントは使用していない**
- `Utils.lsp.get_diagnostics_from_filepath()` で必要時に診断を取得
- プル型アプローチ: 必要な時だけ `vim.diagnostic.get()` を呼び出し
- `lua/avante/diff.lua` でコンフリクト検出時の診断管理を実装
- コンフリクト時に診断を一時無効化→解決後に再有効化

#### olimorris/codecompanion.nvim  
- **DiagnosticChangedイベントは使用していない**
- `helpers/actions.lua` の `get_diagnostics` 関数で診断取得
- `checktime` コマンドでバッファ更新を強制
- 診断説明機能: ユーザーが明示的に要求した時のみ診断を処理
- プル型アプローチ: リアルタイム監視ではなく要求時取得

### 診断API調査結果

#### vim.diagnostic API
- `vim.diagnostic.get(bufnr)` で診断情報を取得
- `DiagnosticChanged` イベントが診断更新時に発火
- 診断レベル: ERROR, WARNING, INFO, HINT

#### 診断待機の課題
- LSPサーバーによって診断更新タイミングが異なる
- 保存後すぐには診断が更新されないことがある（数秒かかる場合も）
- 複数ファイル同時編集時の競合状態

### 実装方針の検討結果

**主流のアプローチ**: 他の主要AIプラグインは皆「DiagnosticChangedイベントを使った待機処理」を**していない**

**推奨方針**: **シンプルな遅延取得**
```lua
-- ファイル保存後
vim.cmd("write")

-- 短時間待機してから診断を取得
vim.defer_fn(function()
  local diagnostics = vim.diagnostic.get(self.origin_bufnr, {
    severity = { min = vim.diagnostic.severity.ERROR }
  })
  
  if #diagnostics > 0 then
    local error_messages = {}
    for _, diag in ipairs(diagnostics) do
      table.insert(error_messages, string.format(
        "Line %d: %s", diag.lnum + 1, diag.message
      ))
    end
    -- エラー情報をメッセージに含める
    local message = "Successfully applied changes to " .. self.path .. 
                   "\n\nFound errors:\n" .. table.concat(error_messages, "\n")
  end
end, 500) -- 500ms待機
```

**メリット**:
- シンプルで既存コードへの影響最小
- 500ms程度で大部分のLSPが診断完了
- 他のAIプラグインと一貫したアプローチ
- 複雑な非同期処理を回避


## チェックリスト

`A: `のようにアルファベットのラベルをつけることで、参照しやすくする

### 1. タスク分解

- [x] A: タスク分解して2以降のチェックリストを書き換える

### 2. 実装方針の検討

- [x] A: diagnostics待機処理の実装方法を決定
    - ~~DiagnosticChangedイベントを使用する方法~~ → **使用しない**（他のAIプラグインと同様）
    - **決定**: シンプルな遅延取得（500ms待機→診断取得）
    - エラーメッセージのフォーマット: `message`に診断情報を文字列として含める
- [x] B: サーバー側との通信プロトコルの設計
    - **決定**: 既存の`message`フィールドに診断情報を追記
    - 新しいメッセージタイプは不要（既存のaction_resultで対応）

### 3. 実装手順の詳細化

- [x] A: replace_in_file_block.luaの修正箇所を特定
    - handle_action関数の修正（`vim.cmd("write")`の後に診断取得処理を追加）
    - diagnostics待機処理の追加（`vim.defer_fn`を使用）
    - ~~結果をサーバーに送る処理~~ → **不要**（同期的にmessageを返すだけ）
- [x] B: サーバー側の受信処理の設計
    - **決定**: 新しいメッセージタイプは不要
    - **決定**: 既存のaction_result系で対応可能

### 4. エラーハンドリングの設計

- [x] A: タイムアウト処理の実装方針
    - **決定**: 500ms待機（他のAIプラグインを参考）
    - **決定**: タイムアウト時は通常の成功メッセージを返す
- [x] B: 複数ファイルを同時に保存した場合の対応
    - **決定**: バッファごとに独立して処理（`self.origin_bufnr`で特定）
    - **決定**: 遅延実行なので競合状態は発生しにくい

### 5. ユーザー体験の考慮

- [x] A: 待機中の表示方法
    - **決定**: 500ms程度なので特別な表示は不要
    - **決定**: キャンセル機能は実装しない（短時間のため）
- [x] B: diagnostics結果の表示方法
    - **決定**: エラーレベルのみ対象（WARNING、INFOは除外）
    - **決定**: "Line X: エラーメッセージ"形式で表示

### 6. 実装タスク

- [ ] P: まだエラーが拾えてないので修正

- [ ] A: handle_action関数の非同期化対応
    - 現在の同期的な戻り値を非同期に変更する必要があるか検討
    - `vim.defer_fn`内で結果を返す方法を調査
- [ ] B: 実装の詳細
    - replace_in_file_block.lua:222-239のhandle_action関数を修正
    - 診断取得ロジックの実装
    - エラーメッセージのフォーマット処理
- [ ] C: テストケースの検討
    - 診断エラーがある場合のテスト
    - 診断エラーがない場合のテスト
    - タイムアウト時の動作確認
