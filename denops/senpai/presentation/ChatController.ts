import { assert, Denops, is, nvim, PredicateType } from "../deps.ts";
import {
  chatManager,
  ChatManagerCommand,
  isChatManagerCommand,
} from "./ChatManager.ts";
import { writePlainTextToBuffer, writeTextStreamToBuffer } from "./utils.ts";

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
      await this.writeUserInputToBuffer();
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
  private async writeUserInputToBuffer(): Promise<void> {
    const userInput = `\
<SenpaiUserInput>
${this._text}
</SenpaiUserInput>
`;
    // 1-based
    const { row } = await writePlainTextToBuffer(
      this._denops,
      this._winnr,
      this._bufnr,
      userInput,
    );

    const lines = userInput.split("\n");
    const namespace = await nvim.nvim_create_namespace(
      this._denops,
      "sepnai-chat",
    );

    await nvim.nvim_buf_set_extmark(
      this._denops,
      this._bufnr,
      namespace,
      row - 1, // 0-based
      0,
      {
        virt_text: [[`    ╭${"─".repeat(100)}`, "NonText"]],
        virt_text_pos: "overlay",
        virt_text_hide: true,
      },
    );

    for (let i = 1; i < lines.length - 2; i++) {
      await nvim.nvim_buf_set_extmark(
        this._denops,
        this._bufnr,
        namespace,
        (row - 1) + i, // 0-based
        0,
        {
          virt_text: [["    │", "NonText"]],
          virt_text_pos: "inline",
        },
      );
    }

    await nvim.nvim_buf_set_extmark(
      this._denops,
      this._bufnr,
      namespace,
      (row - 1) + lines.length - 2, // 0-based
      0,
      {
        virt_text: [[`    ╰${"─".repeat(100)}`, "NonText"]],
        virt_text_pos: "overlay",
        virt_text_hide: true,
      },
    );
    return;
  }
}
