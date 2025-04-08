import { expect, test } from "bun:test";
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
		content: "\nOhayo!\n",
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
	expect(result).toEqual({
		frontmatter: {},
		content: "\nOhayo!\n",
	});
});

test("GetProjectRules parse with expression", async () => {
	const usecase = new GetProjectRules(process.cwd());

	const text = `\
---
description: "Front-end side of senpai.nvim"
globs: "lua/senpai/**/*.lua"
---

const foo = "Ohayo"

{foo}!`;
	const result = await usecase.parse(text);
	expect(result).toEqual({
		frontmatter: {
			description: "Front-end side of senpai.nvim",
			globs: "lua/senpai/**/*.lua",
		},
		content: "\nOhayo!\n",
	});
});
