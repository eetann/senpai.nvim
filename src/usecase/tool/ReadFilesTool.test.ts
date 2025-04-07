import { beforeAll, expect, spyOn, test } from "bun:test";
import type { BunFile } from "bun";
import { getFiles } from "./ReadFilesTool";

beforeAll(() => {
	spyOn(global.Bun, "file").mockImplementation((path, _) => {
		let bytes = "foo";
		if (path === "/workspace/foo.txt") {
			bytes = "hello";
		} else if (path === "/workspace/piyo.txt") {
			return {
				exists: () => Promise.resolve(false),
				bytes: () => Promise.resolve(""),
				type: "text/plain; charset=UTF-8",
			} as unknown as BunFile;
		} else if (path === "/workspace/bar/piyo.txt") {
			bytes = "world";
		}
		return {
			exists: () => Promise.resolve(true),
			bytes: () => Promise.resolve(bytes),
			type: "text/plain; charset=UTF-8",
		} as unknown as BunFile;
	});
	spyOn(global.Bun, "resolveSync").mockImplementation((moduleId, cwd) => {
		return `${cwd}/${moduleId.replace(/^\.\//, "")}`;
	});
});

test("works", async () => {
	const glob = async (cwd: string, path: string) => {
		if (path === "foo.txt") {
			return ["foo.txt"];
		}
		return ["bar/piyo.txt"];
	};

	const result = await getFiles("/workspace", glob, ["foo.txt", "piyo.txt"]);
	expect(result).toEqual([
		{
			filepath: "/workspace/foo.txt",
			type: "file",
			data: "hello",
			mimeType: "text/plain; charset=UTF-8",
		},
		{
			filepath: "/workspace/bar/piyo.txt",
			type: "file",
			data: "world",
			mimeType: "text/plain; charset=UTF-8",
		},
	]);
});
