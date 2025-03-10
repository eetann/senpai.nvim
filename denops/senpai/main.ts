import type { Entrypoint } from "./deps.ts";
import { weatherAgent } from "./weather.ts";
import { generateCommitMessage } from "./presentation/generateCommitMessage.ts";

export const main: Entrypoint = (denops) => {
  denops.dispatcher = {
    async hello() {
      const response = await weatherAgent.generate([
        { role: "user", content: "Tokyo" },
      ]);
      return response.text;
    },
    async generateCommitMessage(args) {
      return await generateCommitMessage(args);
    },
  };
  denops.cmd(`echo "Senpai: Ohayo!"`);
};
