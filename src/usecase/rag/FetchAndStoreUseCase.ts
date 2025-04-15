import type { LibSQLVector } from "@mastra/core/vector/libsql";
import { MDocument } from "@mastra/rag";
import type { EmbeddingModel } from "ai";
import { embedMany } from "ai";

// NOTE: The following error warns :(
// `llamaindex was already imported. This breaks constructor checks and will lead to issues!`
// https://github.com/mastra-ai/mastra/issues/2861

function extract_title(text: string, url: string) {
	const match = text.match(/<title>([^<]*)<\/title>/);
	if (!match || typeof match[1] !== "string") return url;
	return match[1];
}

export class FetchAndStoreUseCase {
	constructor(
		private vector: LibSQLVector,
		private model: EmbeddingModel<string>,
	) {}
	async execute(url: string) {
		const response = await fetch(url);
		if (!response.ok) {
			return "Fetch failed.";
		}
		const html = await response.text();
		const title = extract_title(html, url);

		const doc = MDocument.fromHTML(html);
		const chunks = await doc.chunk({
			strategy: "recursive",
		});
		const { embeddings } = await embedMany({
			model: this.model,
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
