import { openai } from "@ai-sdk/openai";
import { z } from "@hono/zod-openapi";
import type { LibSQLVector } from "@mastra/core/vector/libsql";
import { embed } from "ai";

export const ragSourcesSchema = z.record(
	z.string().describe("source name"),
	z.string().describe("title"),
);

type RagSources = z.infer<typeof ragSourcesSchema>;

export class GetRagSourcesUseCase {
	constructor(private vector: LibSQLVector) {}
	async execute(): Promise<RagSources> {
		const { embedding } = await embed({
			model: openai.embedding("text-embedding-3-small"),
			value: ".",
		});
		const indexes = await this.vector.query({
			indexName: "store",
			queryVector: embedding,
			topK: 10000,
		});
		const result: RagSources = {};
		for (const index of indexes) {
			const source = index.metadata.source;
			if (!result[source]) {
				result[source] = index.metadata.title;
			}
		}
		return result;
	}
}
