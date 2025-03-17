import { beforeAll, expect, spyOn, test } from "bun:test";
import type { BunFile } from "bun";
import { getFiles } from "./GetFiles";

beforeAll(() => {
	spyOn(global.Bun, "file").mockImplementation((path, options) => {
		let bytes = "foo";
		if (path === "foo.txt") {
			bytes = "hello";
		} else if (path === "piyo.txt") {
			return {
				exists: () => Promise.resolve(false),
				bytes: () => Promise.resolve(""),
				type: "text/plain; charset=UTF-8",
			} as unknown as BunFile;
		} else if (path === "bar/piyo.txt") {
			bytes = "world";
		}
		return {
			exists: () => Promise.resolve(true),
			bytes: () => Promise.resolve(bytes),
			type: "text/plain; charset=UTF-8",
		} as unknown as BunFile;
	});
});

test("works", async () => {
	const glob = async (_: string) => {
		return ["bar/piyo.txt"];
	};

	const result = await getFiles(glob, ["foo.txt", "piyo.txt"]);
	expect(result).toEqual([
		{
			type: "file",
			data: "hello",
			mimeType: "text/plain; charset=UTF-8",
		},
		{
			type: "file",
			data: "world",
			mimeType: "text/plain; charset=UTF-8",
		},
	]);
});
