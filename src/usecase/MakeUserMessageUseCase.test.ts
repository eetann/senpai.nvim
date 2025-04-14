import { expect, test } from "bun:test";
import { MakeUserMessageUseCase } from "./MakeUserMessageUseCase";

test("extracts basic filename", () => {
	const input = "hello `@foo/bar/buz.txt` world";
	const result = new MakeUserMessageUseCase().execute(input);
	expect(result).toEqual(["foo/bar/buz.txt"]);
});

// Multiple filenames test
test("extracts multiple filenames", () => {
	const input = "hello `@foo/bar/buz.txt` `@foo/piyo.lua` world";
	const result = new MakeUserMessageUseCase().execute(input);
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
	const result = new MakeUserMessageUseCase().execute(input);
	expect(result).toEqual(["foo/bar/buz.txt"]);
});

// Empty input test
test("returns empty array for empty input", () => {
	const input = "";
	const result = new MakeUserMessageUseCase().execute(input);
	expect(result).toEqual([]);
});

// Special characters test
test("handles filenames with special characters", () => {
	const input = "Check this: `@path/with space/file-name_123.txt`";
	const result = new MakeUserMessageUseCase().execute(input);
	expect(result).toEqual(["path/with space/file-name_123.txt"]);
});

// Japanese characters test
test("handles filenames with Japanese characters", () => {
	const input = "日本語ファイル: `@フォルダ/ファイル名.txt`";
	const result = new MakeUserMessageUseCase().execute(input);
	expect(result).toEqual(["フォルダ/ファイル名.txt"]);
});

// Multiline text test
test("extracts filenames from multiline text", () => {
	const input = `
    First line \`@first/file.txt\`
    Second line
    Third line \`@third/file.js\`
  `;
	const result = new MakeUserMessageUseCase().execute(input);
	expect(result).toEqual(["first/file.txt", "third/file.js"]);
});
