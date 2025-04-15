import { expect, test } from "bun:test";
import path from "node:path";
import { MakeUserMessageUseCase } from "./MakeUserMessageUseCase";

test("extracts basic filename", () => {
	const input = "hello [buz.txt](/foo/bar/buz.txt) world";
	const result = new MakeUserMessageUseCase(process.cwd()).extractFiles(input);
	expect(result[0]).toEqual({ language: "text", filename: "/foo/bar/buz.txt" });
});

// Multiple filenames test
test("extracts multiple filenames", () => {
	const input =
		"hello [buz.txt](/foo/bar/buz.txt) [piyo.lua](./piyo.lua) world";
	const result = new MakeUserMessageUseCase(process.cwd()).extractFiles(input);
	expect(result[0]).toEqual({ language: "text", filename: "/foo/bar/buz.txt" });
	expect(result[1]).toEqual({ language: "lua", filename: "./piyo.lua" });
});

// Invalid patterns test
test("ignores invalid patterns", () => {
	const input = `
    hello [buz.txt](/foo/bar/buz.txt)
    [invalid](no-slash-prefix.txt)
    [example](https://example.com)
    [empty]() ← this has nothing in the parentheses
  `;
	const result = new MakeUserMessageUseCase(process.cwd()).extractFiles(input);
	expect(result[0]).toEqual({ language: "text", filename: "/foo/bar/buz.txt" });
});

// Empty input test
test("returns empty array for empty input", () => {
	const input = "";
	const result = new MakeUserMessageUseCase(process.cwd()).extractFiles(input);
	expect(result).toEqual([]);
});

// Special characters test
test("handles filenames with special characters", () => {
	const input =
		"Check this: [file-name_123.txt](/path/with space/file-name_123.txt)";
	const result = new MakeUserMessageUseCase(process.cwd()).extractFiles(input);
	expect(result[0]).toEqual({
		language: "text",
		filename: "/path/with space/file-name_123.txt",
	});
});

// Japanese characters test
test("handles filenames with Japanese characters", () => {
	const input = "日本語ファイル: [ファイル名.txt](/フォルダ/ファイル名.txt)";
	const result = new MakeUserMessageUseCase(process.cwd()).extractFiles(input);
	expect(result[0]).toEqual({
		language: "text",
		filename: "/フォルダ/ファイル名.txt",
	});
});

// Multiline text test
test("extracts filenames from multiline text", () => {
	const input = `
    First line [file.txt](/first/file.txt)
    Second line
    Third line [file.js](./third/file.js)
  `;
	const result = new MakeUserMessageUseCase(process.cwd()).extractFiles(input);
	expect(result[0]).toEqual({ language: "text", filename: "/first/file.txt" });
	expect(result[1]).toEqual({
		language: "javascript",
		filename: "./third/file.js",
	});
});

test("execute adds file content to user message", async () => {
	const testDir = process.cwd();
	const filename = "./biome.json";
	const gitignorePath = path.join(testDir, filename);

	const useCase = new MakeUserMessageUseCase(testDir);

	const result = await useCase.execute(
		`Tell me about [${filename}](${filename})`,
	);
	const testContent = await Bun.file(gitignorePath).text();

	expect(result.role).toBe("user");
	expect(result.content).toBe(`Tell me about [${filename}](${filename})
---

Reference
\`\`\`json title="${filename}"
${testContent}
\`\`\`
`);
});

test("execute handles non-existent files gracefully", async () => {
	const useCase = new MakeUserMessageUseCase(process.cwd());
	const result = await useCase.execute(
		"Check this file [non-existent-file.txt](./non-existent-file.txt)",
	);

	expect(result.role).toBe("user");
	expect(result.content).toBe(
		"Check this file [non-existent-file.txt](./non-existent-file.txt)\n---\n\nReference",
	);
});
