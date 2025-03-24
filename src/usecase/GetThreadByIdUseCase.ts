import type { Memory } from "@mastra/memory";

export class GetThreadByIdUseCase {
	constructor(private memory: Memory) {}
	async execute(thread_id: string) {
		return await this.memory.getThreadById({
			threadId: thread_id,
		});
	}
}
