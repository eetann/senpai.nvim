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
	expect(result).toEqual({
		frontmatter: {},
		content: "Ohayo!\n",
	});
});

test("GetProjectRules parse with good expression", async () => {
	const usecase = new GetProjectRules(process.cwd());

	const text = `\
---
description: "Front-end side of senpai.nvim"
globs: "lua/senpai/**/*.lua"
---

export const foo = "Ohayo"

{foo}!`;
	const result = await usecase.parse(text);
	expect(result).toEqual({
		frontmatter: {
			description: "Front-end side of senpai.nvim",
			globs: "lua/senpai/**/*.lua",
		},
		content: "Ohayo!\n",
	});
});

test("GetProjectRules parse with bad expression", async () => {
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
		content: "",
	});
});

test("GetProjectRules execute", async () => {
	const usecase = new GetProjectRules(process.cwd());

	const text = await Bun.file(
		path.join(process.cwd(), ".senpai/prompts/front_end.mdx"),
	).text();
	const result = await usecase.parse(text);
	expect(result).toEqual({
		frontmatter: {
			description: "Front-end side of senpai.nvim",
			globs: "lua/senpai/**/*.lua",
		},
		content: "baaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
	});
});
