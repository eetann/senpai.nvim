import type { Entrypoint } from "jsr:@denops/std@^7.0.0";
import { weatherAgent } from "./weather.ts";
import { generateCommitMessage } from "./usecase/generateCommitMessage.ts";
import { GitDiff } from "./infra/GitDiff.ts";
import { getModel, isProviderConfig } from "./infra/Model.ts";
import { assert, is } from "jsr:@core/unknownutil@^4.3.0";

export const main: Entrypoint = (denops) => {
  denops.dispatcher = {
    async hello() {
      const response = await weatherAgent.generate([
        { role: "user", content: "Tokyo" },
      ]);
      return response.text;
    },
    async generateCommitMessage(provider: unknown, provider_config: unknown) {
      assert(provider, is.String);
      assert(provider_config, isProviderConfig);
      const model = getModel(provider, provider_config);
      return await generateCommitMessage(model, GitDiff);
    },
  };
  denops.cmd(`echo "Senpai: Ohayo!"`);
};
