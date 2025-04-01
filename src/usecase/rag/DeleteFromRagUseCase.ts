import type { LibSQLVector } from "@mastra/core/vector/libsql";
import { type EmbeddingModel, embed } from "ai";

export class DeleteFromRagUseCase {
	constructor(
		private vector: LibSQLVector,
		private model: EmbeddingModel<string>,
	) {}
	async execute(source: string) {
		const { embedding } = await embed({
			model: this.model,
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
