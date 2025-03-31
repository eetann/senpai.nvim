import { openai } from "@ai-sdk/openai";
import type { LibSQLVector } from "@mastra/core/vector/libsql";
import { MDocument } from "@mastra/rag";
import { embedMany } from "ai";

// NOTE: The following error warns :(
// `llamaindex was already imported. This breaks constructor checks and will lead to issues!`
// https://github.com/mastra-ai/mastra/issues/2861

const embedModel = openai.embedding("text-embedding-3-small");

function extract_title(text: string, url: string) {
	const match = text.match(/<title>([^<]*)<\/title>/);
	if (!match || typeof match[1] !== "string") return url;
	return match[1];
}

export class FetchAndStoreUseCase {
	constructor(private vector: LibSQLVector) {}
	async execute(url: string) {
		// TODO: キャッシュ使うときはすでにデータがあるかチェック
		const response = await fetch(url);
		if (!response.ok) {
			return "Fetch failed.";
		}
		const html = await response.text();
		const title = extract_title(html, url);

		const doc = MDocument.fromHTML(html);
		// TODO: 拡張子で変えたい
		const chunks = await doc.chunk({
			strategy: "recursive",
		});
		const { embeddings } = await embedMany({
			model: embedModel,
			values: chunks.map((chunk) => chunk.text),
		});

		// Create an index with dimension 1536 (for text-embedding-3-small)
		await this.vector.createIndex({
			indexName: "store",
			dimension: 1536,
		});
		await this.vector.upsert({
			indexName: "store",
			vectors: embeddings,
			metadata: chunks.map((chunk) => ({
				source: url,
				title,
				text: chunk.text,
			})),
		});
		return "";
	}
}

// import { vector } from "@/infra/Vector";
// async function main() {
// 	const url = "https://mastra.ai/docs/rag/overview";
// 	const message = await new FetchAndStoreUseCase(vector).execute(url);
// 	console.log(message);
//
// 	const { embedding: queryEmbedding } = await embed({
// 		model: embedModel,
// 		value: "Mastra’s RAGとは",
// 	});
//
// 	try {
// 		const searchResult = await vector.query({
// 			indexName: formatValidIndexName(url),
// 			queryVector: queryEmbedding,
// 		});
// 		console.log(searchResult);
// 	} catch (error) {
// 		console.log(error);
// 	}
// }
// main();
