import type { Memory } from "@mastra/memory";

export class GetMessagesUseCase {
	constructor(private memory: Memory) {}
	async execute(threadId: string) {
		return (
			await this.memory.query({
				threadId,
			})
		).messages;
	}
}
