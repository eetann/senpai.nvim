import type { LibSQLVector } from "@mastra/core/vector/libsql";
import { type EmbeddingModel, embed } from "ai";

export class CheckHasCacheUseCase {
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
			topK: 1,
			filter: {
				source,
			},
		});
		if (indexes.length === 0) {
			return false;
		}
		return true;
	}
}
