export function formatValidIndexName(input: string): string {
	if (!input) return "_";

	let result = input;

	if (!/^[a-zA-Z_]/.test(result)) {
		result = `_${result}`;
	}

	result = result.replace(/[^a-zA-Z0-9_]/g, "_");

	return result;
}
