import type { Memory } from "@mastra/memory";

export class GetThreadsUseCase {
	constructor(private memory: Memory) {}
	async execute() {
		return await this.memory.getThreadsByResourceId({
			resourceId: "senpai",
		});
	}
}
