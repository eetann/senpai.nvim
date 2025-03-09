import { GenerateCommitMessageUseCase } from "../usecase/generateCommitMessage.ts";
import { GitDiff } from "../infra/GitDiff.ts";
import { getModel, isProviderConfig } from "../infra/Model.ts";
import { assert, is } from "jsr:@core/unknownutil@^4.3.0";
import { PredicateType } from "../deps.ts";

const isGenerateCommitMessageCommand = is.ObjectOf({
  provider: is.String,
  provider_config: isProviderConfig,
  language: is.String,
});

export type GenerateCommitMessageCommand = PredicateType<
  typeof isGenerateCommitMessageCommand
>;

export async function generateCommitMessage(
  command: unknown | GenerateCommitMessageCommand,
) {
  assert(command, isGenerateCommitMessageCommand);
  const model = getModel(command.provider, command.provider_config);
  return await new GenerateCommitMessageUseCase(model, GitDiff).execute(
    command.language,
  );
}
