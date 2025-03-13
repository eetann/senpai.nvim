import { assert, is } from "../deps.ts";
import { Denops, PredicateType } from "../deps.ts";
import {
  chatManager,
  ChatManagerCommand,
  isChatManagerCommand,
} from "./ChatManager.ts";
import {
  writePlainTextToBuffer,
  writeTextStreamToBuffer,
  writeUserInputToBuffer,
} from "./writeToChat.ts";

const isChatControllerCommand = is.ObjectOf({
  model: isChatManagerCommand,
  bufnr: is.Number,
  winnr: is.Number,
  text: is.String,
});

export type ChatControllerCommand = PredicateType<
  typeof isChatControllerCommand
>;

export class ChatController {
  private _denops: Denops;
  private _model: ChatManagerCommand;
  private _bufnr: number;
  private _winnr: number;
  private _text: string;

  constructor(denops: Denops, command: ChatControllerCommand | unknown) {
    assert(command, isChatControllerCommand);
    this._denops = denops;
    this._model = command.model;
    this._bufnr = command.bufnr;
    this._winnr = command.winnr;
    this._text = command.text;
  }

  async execute(): Promise<void> {
    try {
      const { chat, isNew } = chatManager.getOrCreateChat(this._model);
      if (isNew) {
        const initialText = `\
---
provider: "${this._model.provider}"
model: "${this._model.provider_config?.model ?? ""}"
---
`;
        await writePlainTextToBuffer(
          this._denops,
          this._winnr,
          this._bufnr,
          initialText,
        );
      }
      await writeUserInputToBuffer(
        this._denops,
        this._winnr,
        this._bufnr,
        this._text,
      );
      const textStream = await chat.execute(this._text);
      await writeTextStreamToBuffer(
        this._denops,
        this._winnr,
        this._bufnr,
        textStream,
      );
    } catch (error) {
      console.log(error);
    }
  }
}
