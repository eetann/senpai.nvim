import { Denops, fn, nvim } from "../deps.ts";

export async function writeTextStreamToBuffer(
  denops: Denops,
  winnr: number,
  bufnr: number,
  textStream: AsyncIterable<string>,
): Promise<void> {
  const encoder = new TextEncoder();
  // 1 based
  let row = await fn.line(denops, "$", winnr);
  let col = await denops.call("col", [row, "$"], winnr) as number;
  for await (const chunk of textStream) {
    const lines = chunk.split("\n");
    // 0 based
    nvim.nvim_buf_set_text(
      denops,
      bufnr,
      row - 1,
      col - 1,
      row - 1,
      col - 1,
      lines,
    );
    const additional_row = lines.length - 1;
    row += additional_row;
    if (additional_row > 0) {
      col = 0;
    }
    col += encoder.encode(lines[additional_row]).length;
  }
}
