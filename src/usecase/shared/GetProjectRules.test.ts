import { expect, test } from "bun:test";
import path from "node:path";
import { GetProjectRules } from "./GetProjectRules";

test("GetProjectRules parse works", async () => {
	const usecase = new GetProjectRules(process.cwd());

	const text = `\
---
description: "Front-end side of senpai.nvim"
globs: "lua/senpai/**/*.lua"
---

Ohayo!`;
	const result = await usecase.parse(text);
	expect(result).toEqual({
		frontmatter: {
			description: "Front-end side of senpai.nvim",
			globs: "lua/senpai/**/*.lua",
		},
		content: "Ohayo!\n",
	});
});

test("GetProjectRules When parsing fails", async () => {
	const usecase = new GetProjectRules(process.cwd());

	const text = `\
---
descriptioooooooooooooooon
---

Ohayo!`;
	const result = await usecase.parse(text);
	expect(result).toBeUndefined();
});
