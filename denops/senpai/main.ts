import { type Entrypoint, autocmd } from "./deps.ts";
import { summarize } from "./presentation/summary.ts";

export const main: Entrypoint = (denops) => {
	denops.dispatcher = {
		async summarize(args) {
			await summarize(denops, args);
		},
	};
	autocmd.emit(denops, "User", "SenpaiInitEnd", { nomodeline: true });
};
