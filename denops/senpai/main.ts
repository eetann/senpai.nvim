import { autocmd, type Entrypoint } from "./deps.ts";
import { weatherAgent } from "./weather.ts";
import { generateCommitMessage } from "./presentation/generateCommitMessage.ts";
import { summarize } from "./presentation/summary.ts";
import { ChatController } from "./presentation/ChatController.ts";
import { GetHistory } from "./usecase/GetHistory.ts";

export const main: Entrypoint = (denops) => {
  denops.dispatcher = {
    async chat(args) {
      await new ChatController(denops, args).execute();
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
      await new GetHistory().execute();
      // await summarize(denops, args);
    },
  };
  autocmd.emit(denops, "User", "SenpaiInitEnd", { nomodeline: true });
};
