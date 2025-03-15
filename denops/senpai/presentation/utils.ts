import { Denops, fn, nvim } from "../deps.ts";

export type Position1based = { row: number; col: number };

export async function get_end_position1based(
  denops: Denops,
  winid: number,
): Promise<Position1based> {
  const row = await fn.line(denops, "$", winid);
  const col = (await denops.call("col", [row, "$"], winid)) as number;
  return { row, col };
}

export async function buf_set_text(
  denops: Denops,
  bufnr: number,
  position1based: Position1based,
  lines: string[],
): Promise<void> {
  // 0 based
  await nvim.nvim_buf_set_text(
    denops,
    bufnr,
    position1based.row - 1,
    position1based.col - 1,
    position1based.row - 1,
    position1based.col - 1,
    lines,
  );
}

// return 1-based position
export async function writePlainTextToBuffer(
  denops: Denops,
  winid: number,
  bufnr: number,
  text: string,
): Promise<Position1based> {
  const position1based = await get_end_position1based(denops, winid);
  const lines = text.split("\n");
  await buf_set_text(denops, bufnr, position1based, lines);
  return position1based;
}

export async function writeTextStreamToBuffer(
  denops: Denops,
  winid: number,
  bufnr: number,
  textStream: AsyncIterable<string>,
): Promise<void> {
  const encoder = new TextEncoder();
  let { row, col } = await get_end_position1based(denops, winid);
  for await (const chunk of textStream) {
    const lines = chunk.split("\n");
    await buf_set_text(denops, bufnr, { row, col }, lines);
    const rowLength = lines.length;
    row += rowLength - 1;
    if (rowLength > 1) {
      col = 1;
    }
    col += encoder.encode(lines[rowLength - 1]).length;
  }
  await buf_set_text(denops, bufnr, { row, col }, [""]);
}
