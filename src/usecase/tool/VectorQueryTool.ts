import { createTool } from "@mastra/core/tools";
import type { LibSQLVector } from "@mastra/core/vector/libsql";
import {
	defaultVectorQueryDescription,
	queryTextDescription,
} from "@mastra/rag";
import { type EmbeddingModel, embed } from "ai";
import { z } from "zod";

const inputSchema = z.object({
	queryText: z.string().describe(queryTextDescription),
});

export const VectorQueryTool = (
	vector: LibSQLVector,
	model: EmbeddingModel<string>,
) =>
	createTool({
		id: "VectorQuery libsql store Tool",
		description: defaultVectorQueryDescription(),
		inputSchema,
		outputSchema: z.object({
			relevantContext: z.any(),
		}),

		execute: async ({ context: { queryText } }) => {
			const indexName = "store";
			const topK = 10;

			const { embedding } = await embed({
				value: queryText,
				model,
				maxRetries: 2,
			});

			try {
				const results = await vector.query({
					indexName,
					queryVector: embedding,
					topK,
				});

				const relevantChunks = results.map((result) => result?.metadata);
				return {
					relevantContext: relevantChunks,
				};
			} catch (error) {
				console.log(`[senpai] failed vector query: ${error}`);
				return {};
			}
		},
	});

// import { embeddingModel } from "@/infra/GetModel";
// import { vector } from "@/infra/Vector";
// async function main() {
// 	const vectorQueryTool = VectorQueryTool(vector, embeddingModel);
// 	const result = await vectorQueryTool.execute({
// 		context: { queryText: "Mastra" },
// 	});
// 	console.log(result);
// }
// main();
