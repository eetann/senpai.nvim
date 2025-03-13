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

// return 1 based position
async function get_end_position(
  denops: Denops,
  winnr: number,
): Promise<number[]> {
  const row = await fn.line(denops, "$", winnr);
  const col = await denops.call("col", [row, "$"], winnr) as number;
  return [row, col];
}

// return 1 based position
export async function writePlainTextToBuffer(
  denops: Denops,
  winnr: number,
  bufnr: number,
  text: string,
): Promise<{ row: number; col: number }> {
  const [row, col] = await get_end_position(denops, winnr);
  const lines = text.split("\n");
  await buf_set_text(denops, bufnr, row, col, lines);
  return { row, col };
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

export async function writeUserInputToBuffer(
  denops: Denops,
  winnr: number,
  bufnr: number,
  text: string,
): Promise<void> {
  const userInput = `\
<SenpaiUserInput>
${text}
</SenpaiUserInput>
`;
  // 1 based
  const { row } = await writePlainTextToBuffer(
    denops,
    winnr,
    bufnr,
    userInput,
  );

  const lines = userInput.split("\n");
  const namespace = await nvim.nvim_create_namespace(denops, "sepnai-chat");

  await nvim.nvim_buf_set_extmark(
    denops,
    bufnr,
    namespace,
    row - 1, // 0-based
    0,
    {
      virt_text: [[
        `    ╭${"─".repeat(100)}`,
        "NonText",
      ]],
      virt_text_pos: "overlay",
      virt_text_hide: true,
    },
  );

  for (let i = 1; i < lines.length - 2; i++) {
    // 0 based
    await nvim.nvim_buf_set_extmark(
      denops,
      bufnr,
      namespace,
      (row - 1) + i,
      0,
      {
        virt_text: [["    │", "NonText"]],
        virt_text_pos: "inline",
      },
    );
  }
  await nvim.nvim_buf_set_extmark(
    denops,
    bufnr,
    namespace,
    (row - 1) + lines.length - 2, // 0-based
    0,
    {
      virt_text: [[
        `    ╰${"─".repeat(100)}`,
        "NonText",
      ]],
      virt_text_pos: "overlay",
      virt_text_hide: true,
    },
  );
  return;
}
