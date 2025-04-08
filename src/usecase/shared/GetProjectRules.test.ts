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
		content: "Ohayo!",
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
		content: "Ohayo!",
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
		content: "Ohayo!",
	});
});

test("GetProjectRules parse with bad expression", async () => {
	const usecase = new GetProjectRules(process.cwd(), "");

	const text = `\
---
description: "Front-end side of senpai.nvim"
globs: "lua/senpai/**/*.lua"
---

const foo = "Ohayo"

{foo}!`;
	const result = await usecase.parse(text);
	expect(result).toEqual({
		frontmatter: {},
		content: "",
	});
});

test("GetProjectRules execute", async () => {
	const dir = path.join(process.cwd(), "src/usecase/shared");
	const usecase = new GetProjectRules(dir, "");

	const text = await Bun.file(path.join(dir, "rule_test.mdx")).text();
	const result = await usecase.parse(text);
	expect(result).toEqual({
		frontmatter: {
			description: "test",
			globs: "lua/senpai/**/*.lua",
		},
		content:
			'When you refer to this file, greet it with "Foooooooo!"\n\nYou are a professional Neovim plugin developer and are familiar with Lua.',
	});
});
