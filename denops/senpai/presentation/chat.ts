import { assert, is } from "../deps.ts";
import { Denops, nvim, PredicateType } from "../deps.ts";
import { chatManager, isChatManagerCommand } from "./chatManager.ts";

const encoder = new TextEncoder();

const isChatCommand = is.ObjectOf({
  model: isChatManagerCommand,
  bufnr: is.Number,
  text: is.String,
});

export type ChatCommand = PredicateType<typeof isChatCommand>;

export async function chat(
  denops: Denops,
  command: unknown | ChatCommand,
): Promise<void> {
  assert(command, isChatCommand);
  const chat = chatManager.getOrCreateChat(command.model);
  const textStream = await chat.execute(command.text);

  const initialPosition = (await nvim.nvim_win_get_cursor(
    denops,
    0,
  )) as number[];
  let [row, col] = initialPosition;
  for await (const chunk of textStream) {
    const lines = chunk.split("\n");
    nvim.nvim_buf_set_text(
      denops,
      command.bufnr,
      row - 1,
      col,
      row - 1,
      col,
      lines,
    );
    const additional_row = lines.length - 1;
    row += additional_row;
    if (additional_row > 0) {
      col = 0;
    }
    col += encoder.encode(lines[additional_row]).length;
  }
  await nvim.nvim_win_set_cursor(denops, 0, [row, col]);
}
