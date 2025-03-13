import { assert, Denops, fn, is, nvim, PredicateType } from "../deps.ts";
import {
  chatManager,
  ChatManagerCommand,
  isChatManagerCommand,
} from "./ChatManager.ts";

type position1based = { row: number; col: number };

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
        await this.writePlainTextToBuffer(initialText);
      }
      await this.writeUserInputToBuffer();
      const textStream = await chat.execute(this._text);
      await this.writeTextStreamToBuffer(textStream);
    } catch (error) {
      console.log(error);
    }
  }

  private async buf_set_text(
    row: number, // 1-based
    col: number, // 1-based
    lines: string[],
  ): Promise<void> {
    // 0 based
    await nvim.nvim_buf_set_text(
      this._denops,
      this._bufnr,
      row - 1,
      col - 1,
      row - 1,
      col - 1,
      lines,
    );
  }

  private async get_end_position(): Promise<position1based> {
    const row = await fn.line(this._denops, "$", this._winnr);
    const col = await this._denops.call(
      "col",
      [row, "$"],
      this._winnr,
    ) as number;
    return { row, col };
  }

  // return 1-based position
  private async writePlainTextToBuffer(
    text: string,
  ): Promise<position1based> {
    const { row, col } = await this.get_end_position();
    const lines = text.split("\n");
    await this.buf_set_text(row, col, lines);
    return { row, col };
  }

  private async writeTextStreamToBuffer(
    textStream: AsyncIterable<string>,
  ): Promise<void> {
    const encoder = new TextEncoder();
    let { row, col } = await this.get_end_position();
    for await (const chunk of textStream) {
      const lines = chunk.split("\n");
      await this.buf_set_text(row, col, lines);
      const additional_row = lines.length - 1;
      row += additional_row;
      if (additional_row > 0) {
        col = 0;
      }
      col += encoder.encode(lines[additional_row]).length;
    }
    await this.buf_set_text(row, col, [""]);
  }

  private async writeUserInputToBuffer(): Promise<void> {
    const userInput = `\
<SenpaiUserInput>
${this._text}
</SenpaiUserInput>
`;
    // 1-based
    const { row } = await this.writePlainTextToBuffer(userInput);

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
