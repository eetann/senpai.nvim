import { Denops, fn, nvim } from "../deps.ts";

async function buf_set_text(
  denops: Denops,
  bufnr: number,
  row: number, // 1 based
  col: number, // 1 based
  lines: string[],
): Promise<void> {
  // 0 based
  await nvim.nvim_buf_set_text(
    denops,
    bufnr,
    row - 1,
    col - 1,
    row - 1,
    col - 1,
    lines,
  );
}

// 1 based
async function get_end_position(
  denops: Denops,
  winnr: number,
): Promise<number[]> {
  const row = await fn.line(denops, "$", winnr);
  const col = await denops.call("col", [row, "$"], winnr) as number;
  return [row, col];
}

export async function writePlainTextToBuffer(
  denops: Denops,
  winnr: number,
  bufnr: number,
  text: string,
) {
  const [row, col] = await get_end_position(denops, winnr);
  const lines = text.split("\n");
  await buf_set_text(denops, bufnr, row, col, lines);
}

export async function writeTextStreamToBuffer(
  denops: Denops,
  winnr: number,
  bufnr: number,
  textStream: AsyncIterable<string>,
): Promise<void> {
  const encoder = new TextEncoder();
  let [row, col] = await get_end_position(denops, winnr);
  for await (const chunk of textStream) {
    const lines = chunk.split("\n");
    await buf_set_text(denops, bufnr, row, col, lines);
    const additional_row = lines.length - 1;
    row += additional_row;
    if (additional_row > 0) {
      col = 0;
    }
    col += encoder.encode(lines[additional_row]).length;
  }
  await buf_set_text(denops, bufnr, row, col, [""]);
}
