import { openai } from "@ai-sdk/openai";
import type { LibSQLVector } from "@mastra/core/vector/libsql";
import { MDocument } from "@mastra/rag";
import { embed, embedMany } from "ai";

// NOTE: The following error warns :(
// `llamaindex was already imported. This breaks constructor checks and will lead to issues!`
// https://github.com/mastra-ai/mastra/issues/2861

const embedModel = openai.embedding("text-embedding-3-small");

function formatValidIndexName(input: string): string {
	if (!input) return "_";

	let result = input;

	if (!/^[a-zA-Z_]/.test(result)) {
		result = `_${result}`;
	}

	result = result.replace(/[^a-zA-Z0-9_]/g, "_");

	return result;
}

function isValidUrl(url: string): boolean {
	try {
		new URL(url);
		return true;
	} catch (error) {
		return false;
	}
}

export class FetchAndStoreUseCase {
	constructor(private vector: LibSQLVector) {}
	async execute(url: string) {
		if (!isValidUrl(url)) {
			return `Not a valid URL: ${url}`;
		}
		// TODO: キャッシュ使うときはすでにデータがあるかチェック
		const indexName = formatValidIndexName(url);

		const response = await fetch(url);
		if (!response.ok) {
			return "Fetch failed.";
		}
		const text = await response.text();
		const doc = MDocument.fromText(text);
		const chunks = await doc.chunk({
			strategy: "recursive",
		});
		const { embeddings } = await embedMany({
			model: embedModel,
			values: chunks.map((chunk) => chunk.text),
		});

		// Create an index with dimension 1536 (for text-embedding-3-small)
		await this.vector.createIndex({
			indexName,
			dimension: 1536,
		});
		await this.vector.upsert({
			indexName,
			vectors: embeddings,
			metadata: chunks.map((chunk) => ({ text: chunk.text })),
		});
		return "";
	}
}

import { vector } from "@/infra/Vector";
async function main() {
	const url = "https://mastra.ai/docs/rag/overview";
	const message = await new FetchAndStoreUseCase(vector).execute(url);
	console.log(message);

	const { embedding: queryEmbedding } = await embed({
		model: embedModel,
		value: "Mastra’s RAGとは",
	});

	try {
		const searchResult = await vector.query({
			indexName: formatValidIndexName(url),
			queryVector: queryEmbedding,
		});
		console.log(searchResult);
	} catch (error) {
		console.log(error);
	}
}
main();
