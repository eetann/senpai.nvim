import { z } from "@hono/zod-openapi";
import type { LibSQLVector } from "@mastra/core/vector/libsql";
import { type EmbeddingModel, embed } from "ai";

export const ragSourcesSchema = z.array(
	z.object({ source: z.string(), title: z.string() }),
);

type RagSources = z.infer<typeof ragSourcesSchema>;

export class GetRagSourcesUseCase {
	constructor(
		private vector: LibSQLVector,
		private model: EmbeddingModel<string>,
	) {}
	async execute(): Promise<RagSources> {
		const { embedding } = await embed({
			model: this.model,
			value: ".",
		});
		const indexes = await this.vector.query({
			indexName: "store",
			queryVector: embedding,
			topK: 10000,
		});
		const records: Record<string, string> = {};
		for (const index of indexes) {
			const source = index.metadata.source;
			if (!records[source]) {
				records[source] = index.metadata.title;
			}
		}
		const result: RagSources = [];
		for (const [source, title] of Object.entries(records)) {
			result.push({ source, title });
		}
		return result;
	}
}
