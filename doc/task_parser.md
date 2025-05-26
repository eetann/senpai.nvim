# タスク
LuaからTypeScriptへのコード変換のタスクを整理するためのチェックリストです。
チェックリストを作成したりタスクが増えたら、ユーザーの指示がなくても編集してください。
チェックリストのタスクが完了したらユーザーの指示がなくても編集してください。

## プロジェクト概要

このリポジトリはNeovimのプラグイン"senpai.nvim"のプロジェクト。
NeovimプラグインはMastraを使って実装するAIエージェント。
コード内のコメントは英語で書くこと。

## やりたいこと
- ストリーミング形式で受け取るXMLのパースをLuaからTypeScriptへ移植したい
- 対象ファイル: lua/senpai/usecase/message/replace_file_handler.lua
- 新しく作成するファイル: src/usecase/getStreamProcessor/ReplaceFileHandler.ts
- 対象となるXMLはこんな感じのスキーマ

```xml
<replace_file>
<path>src/main.js</path>
<search>
  return a - b;
</search>
<replace>
  return a + b;
</replace>
</replace_file>
```

- 移行したい内容
    - XMLで指定したタグの中身を取得
    - `self.chat`、`self.diff_block`に関係する箇所は不要
    - これ以外にもタグの処理はあるので、`lua/senpai/domain/message_render.lua`のように抽象的なhandlerクラスを定義してから実装したい
- その他メモ
    - `utils.get_relative_path`は相対パスの取得

## 使用技術

- Mastra
- Vercel AI SDK
- TypeScript(バックエンド)
- Lua(フロントエンド)

## チェックリスト

1. タスク分解をする
    - [x] タスク分解をしてチェックリストを編集

2. TypeScript用抽象ハンドラの設計
    - [x] IAssistantHandler相当の抽象クラス/インターフェースを作成

3. ReplaceFileHandlerの実装
    - [x] ReplaceFileHandlerクラスを実装
    - [x] get_diff_text相当の関数を実装
    - [x] utils.get_relative_path相当の関数を実装

4. XMLストリームパーサの実装
    - 参考: lua/senpai/usecase/message/assistant.lua
    - [ ] ストリーミングXMLパーサを実装
    - [ ] タグごとにハンドラを呼び出す仕組みを実装

5. ユニットテストの作成
    - [ ] 代表的なXMLでテストを作成
    - [ ] Lua側の tests/test_render_message_replace_file.lua も参考にする

6. チェックリストの更新
    - [ ] タスク完了時にチェックリストを更新
