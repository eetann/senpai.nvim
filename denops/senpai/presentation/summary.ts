import { SummarizeUseCase } from "../usecase/summarize.ts";
import { getModel, isProviderConfig } from "../infra/Model.ts";
import { assert, is } from "jsr:@core/unknownutil@^4.3.0";
import { Denops, nvim, PredicateType } from "../deps.ts";

const isSummarizeCommand = is.ObjectOf({
  provider: is.String,
  provider_config: isProviderConfig,
  text: is.String,
});

export type SummarizeCommand = PredicateType<typeof isSummarizeCommand>;

export async function summarize(
  denops: Denops,
  command: unknown | SummarizeCommand,
): Promise<string> {
  assert(command, isSummarizeCommand);
  const model = getModel(command.provider, command.provider_config);
  const textStream = await new SummarizeUseCase(model).execute(command.text);

  for await (const chunk of textStream) {
    nvim.nvim_notify(denops, chunk, 1, {});
  }

  return "";
}
