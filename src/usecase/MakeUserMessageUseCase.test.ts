import { expect, test } from "bun:test";
import path from "node:path";
import { file } from "valibot";
import { MakeUserMessageUseCase } from "./MakeUserMessageUseCase";

test("extracts basic filename", () => {
	const input = "hello `@foo/bar/buz.txt` world";
	const matches = new MakeUserMessageUseCase(process.cwd()).extractFiles(input);
	const result = matches.map((match) => match[1]);
	expect(result).toEqual(["foo/bar/buz.txt"]);
});

// Multiple filenames test
test("extracts multiple filenames", () => {
	const input = "hello `@foo/bar/buz.txt` `@foo/piyo.lua` world";
	const matches = new MakeUserMessageUseCase(process.cwd()).extractFiles(input);
	const result = matches.map((match) => match[1]);
	expect(result).toEqual(["foo/bar/buz.txt", "foo/piyo.lua"]);
});

// Invalid patterns test
test("ignores invalid patterns", () => {
	const input = `
    hello \`@foo/bar/buz.txt\`
    @this is not a filename
    \`john@example.com\`
    \`@\` ← this has nothing after @ so it's not a filename
  `;
	const matches = new MakeUserMessageUseCase(process.cwd()).extractFiles(input);
	const result = matches.map((match) => match[1]);
	expect(result).toEqual(["foo/bar/buz.txt"]);
});

// Empty input test
test("returns empty array for empty input", () => {
	const input = "";
	const matches = new MakeUserMessageUseCase(process.cwd()).extractFiles(input);
	const result = matches.map((match) => match[1]);
	expect(result).toEqual([]);
});

// Special characters test
test("handles filenames with special characters", () => {
	const input = "Check this: `@path/with space/file-name_123.txt`";
	const matches = new MakeUserMessageUseCase(process.cwd()).extractFiles(input);
	const result = matches.map((match) => match[1]);
	expect(result).toEqual(["path/with space/file-name_123.txt"]);
});

// Japanese characters test
test("handles filenames with Japanese characters", () => {
	const input = "日本語ファイル: `@フォルダ/ファイル名.txt`";
	const matches = new MakeUserMessageUseCase(process.cwd()).extractFiles(input);
	const result = matches.map((match) => match[1]);
	expect(result).toEqual(["フォルダ/ファイル名.txt"]);
});

// Multiline text test
test("extracts filenames from multiline text", () => {
	const input = `
    First line \`@first/file.txt\`
    Second line
    Third line \`@third/file.js\`
  `;
	const matches = new MakeUserMessageUseCase(process.cwd()).extractFiles(input);
	const result = matches.map((match) => match[1]);
	expect(result).toEqual(["first/file.txt", "third/file.js"]);
});

test("execute adds file content to user message", async () => {
	const testDir = process.cwd();
	const filename = "biome.json";
	const gitignorePath = path.join(testDir, filename);

	const useCase = new MakeUserMessageUseCase(testDir);

	const result = await useCase.execute(`Tell me about \`@${filename}\``);
	const testContent = await Bun.file(gitignorePath).text();

	expect(result.role).toBe("user");
	expect(result.content).toBe(`Tell me about \`@${filename}\`
\`\`\`json title="${filename}"
${testContent}
\`\`\`
`);
});

test("execute handles non-existent files gracefully", async () => {
	const useCase = new MakeUserMessageUseCase(process.cwd());
	const result = await useCase.execute(
		"Check this file `@non-existent-file.txt`",
	);

	expect(result.role).toBe("user");
	expect(result.content).toBe("Check this file `@non-existent-file.txt`");
});
