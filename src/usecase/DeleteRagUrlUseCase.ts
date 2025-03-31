import type { LibSQLVector } from "@mastra/core/vector/libsql";
import { formatValidIndexName } from "./shared/utils";

export class DeleteRagUrlUseCase {
	constructor(private vector: LibSQLVector) {}
	async execute(url: string) {
		const indexName = formatValidIndexName(url);
		try {
			await this.vector.deleteIndex(indexName);
			return true;
		} catch (error) {
			return false;
		}
	}
}
