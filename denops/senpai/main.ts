import type { Entrypoint } from "jsr:@denops/std@^7.0.0";
import { weatherAgent } from "./weather.ts";
import { commitMessageGenerator } from "./commitMessage.ts";

export const main: Entrypoint = (denops) => {
  denops.dispatcher = {
    async hello() {
      const response = await weatherAgent.generate([
        { role: "user", content: "Tokyo" },
      ]);
      return response.text;
    },
    async generateCommitMessage() {
      return await commitMessageGenerator();
    },
  };
  denops.cmd(`echo "Senpai: Ohayo!"`);
};
