import { openai } from "@ai-sdk/openai";
import type { LibSQLVector } from "@mastra/core/vector/libsql";
import { embed } from "ai";

export class DeleteFromRagUseCase {
	constructor(private vector: LibSQLVector) {}
	async execute(source: string) {
		const { embedding } = await embed({
			model: openai.embedding("text-embedding-3-small"),
			value: ".",
		});
		const indexes = await this.vector.query({
			indexName: "store",
			queryVector: embedding,
			topK: 10000,
			filter: {
				source,
			},
		});
		for (const index of indexes) {
			try {
				await this.vector.deleteIndexById("store", index.id);
			} catch (error) {
				console.log(`[senpai] delete failed: id ${index.id}`);
			}
		}
	}
}
