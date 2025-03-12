import { autocmd, type Entrypoint } from "./deps.ts";
import { weatherAgent } from "./weather.ts";
import { generateCommitMessage } from "./presentation/generateCommitMessage.ts";
import { summarize } from "./presentation/summary.ts";
import { ChatController } from "./presentation/ChatController.ts";

export const main: Entrypoint = (denops) => {
  denops.dispatcher = {
    async chat(args) {
      await ChatController(denops, args);
    },
    async hello() {
      const response = await weatherAgent.generate([
        { role: "user", content: "Tokyo" },
      ]);
      return response.text;
    },
    async generateCommitMessage(args) {
      return await generateCommitMessage(args);
    },
    async summarize(args) {
      await summarize(denops, args);
    },
  };
  autocmd.emit(denops, "User", "SenpaiInitEnd", { nomodeline: true });
};
