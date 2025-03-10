import { SummarizeUseCase } from "../usecase/summarize.ts";
import { getModel, isProviderConfig } from "../infra/Model.ts";
import { assert, is } from "jsr:@core/unknownutil@^4.3.0";
import { Denops, nvim, PredicateType } from "../deps.ts";

const isSummarizeCommand = is.ObjectOf({
  provider: is.String,
  provider_config: isProviderConfig,
  bufnr: is.Number,
  text: is.String,
});

export type SummarizeCommand = PredicateType<typeof isSummarizeCommand>;

export async function summarize(
  denops: Denops,
  command: unknown | SummarizeCommand,
): Promise<void> {
  assert(command, isSummarizeCommand);
  const model = getModel(command.provider, command.provider_config);
  const textStream = await new SummarizeUseCase(model).execute(command.text);

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
    col += lines[additional_row].length;
  }
  await nvim.nvim_win_set_cursor(denops, 0, [row, col]);
}
