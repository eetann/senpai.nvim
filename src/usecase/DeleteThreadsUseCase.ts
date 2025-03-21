import type { Memory } from "@mastra/memory";

export class DeleteThreadsUseCase {
	constructor(private memory: Memory) {}
	async execute(threadId: string) {
		await this.memory.deleteThread(threadId);
	}
}
