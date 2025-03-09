import { GenerateCommitMessageUseCase } from "../usecase/generateCommitMessage.ts";
import { GitDiff } from "../infra/GitDiff.ts";
import { getModel, isProviderConfig } from "../infra/Model.ts";
import { assert, is } from "jsr:@core/unknownutil@^4.3.0";

export async function generateCommitMessage(
  provider: unknown,
  provider_config: unknown,
) {
  assert(provider, is.String);
  assert(provider_config, isProviderConfig);
  const model = getModel(provider, provider_config);
  return await new GenerateCommitMessageUseCase(model, GitDiff).execute();
}

