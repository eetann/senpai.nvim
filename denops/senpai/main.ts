import { type Entrypoint, autocmd } from "./deps.ts";
import { ChatController } from "./presentation/ChatController.ts";
import { summarize } from "./presentation/summary.ts";

export const main: Entrypoint = (denops) => {
	denops.dispatcher = {
		async chat(args) {
			await new ChatController(denops, args).execute();
		},
		async summarize(args) {
			await summarize(denops, args);
		},
	};
	autocmd.emit(denops, "User", "SenpaiInitEnd", { nomodeline: true });
};
