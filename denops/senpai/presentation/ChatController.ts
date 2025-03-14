import { assert, Denops, is, nvim, PredicateType } from "../deps.ts";
import {
  chatManager,
  ChatManagerCommand,
  isChatManagerCommand,
} from "./ChatManager.ts";
import { writePlainTextToBuffer, writeTextStreamToBuffer } from "./utils.ts";

const isChatControllerCommand = is.ObjectOf({
  model: isChatManagerCommand,
  winid: is.Number,
  bufnr: is.Number,
  text: is.String,
});

export type ChatControllerCommand = PredicateType<
  typeof isChatControllerCommand
>;

export class ChatController {
  private _denops: Denops;
  private _model: ChatManagerCommand;
  private _winid: number;
  private _bufnr: number;
  private _text: string;

  constructor(denops: Denops, command: ChatControllerCommand | unknown) {
    assert(command, isChatControllerCommand);
    this._denops = denops;
    this._model = command.model;
    this._winid = command.winid;
    this._bufnr = command.bufnr;
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
          this._winid,
          this._bufnr,
          initialText,
        );
      }
      await this.writeUserInputToBuffer();
      const textStream = await chat.execute(this._text);
      await writeTextStreamToBuffer(
        this._denops,
        this._winid,
        this._bufnr,
        textStream,
      );
    } catch (error) {
      console.log(error);
    }
  }
  private async writeUserInputToBuffer(): Promise<void> {
    const userInput = `
<SenpaiUserInput>

${this._text}

</SenpaiUserInput>
`;
    // 1-based
    const { row } = await writePlainTextToBuffer(
      this._denops,
      this._winid,
      this._bufnr,
      userInput,
    );

    const lines = userInput.split("\n");
    const namespace = await nvim.nvim_create_namespace(
      this._denops,
      "sepnai-chat",
    );

    const topBorderIndex = row + 2 - 1; // 0 based
    const bottomBorderIndex = row + lines.length - 3 - 1; // 0 based
    // NOTE: I want to use only virt_text to put indent,
    // but it shifts during `set wrap`, so I also use sign_text.
    await nvim.nvim_buf_set_extmark(
      this._denops,
      this._bufnr,
      namespace,
      topBorderIndex, // 0-based
      0,
      {
        sign_text: "╭",
        sign_hl_group: "NonText",
        virt_text: [["─".repeat(150), "NonText"]],
        virt_text_pos: "overlay",
        virt_text_hide: true,
      },
    );

    for (let i = topBorderIndex + 1; i < bottomBorderIndex; i++) {
      await nvim.nvim_buf_set_extmark(
        this._denops,
        this._bufnr,
        namespace,
        i, // 0-based
        0,
        {
          sign_text: "│",
          sign_hl_group: "NonText",
        },
      );
    }

    await nvim.nvim_buf_set_extmark(
      this._denops,
      this._bufnr,
      namespace,
      bottomBorderIndex, // 0-based
      0,
      {
        virt_text: [["─".repeat(150), "NonText"]],
        virt_text_pos: "overlay",
        virt_text_hide: true,
        sign_text: "╰",
        sign_hl_group: "NonText",
      },
    );
    return;
  }
}
