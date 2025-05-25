import { expect, test } from "vitest";
import { GetApplicableRules } from "./GetApplicableRules";
import type { ProjectRule } from "./shared/GetProjectRules";

const rules: ProjectRule[] = [
	{
		content: "all",
		frontmatter: { description: "" },
	},
	{ content: "Hello lua", frontmatter: { globs: "**/*.lua", description: "" } },
	{
		content: "Hello TypeScript",
		frontmatter: { globs: ["**/*.ts"], description: "" },
	},
];

test("GetApplicableRules works with string glob", async () => {
	const usecase = new GetApplicableRules(rules);

	const result = await usecase.execute(["foo/bar.lua"]);
	expect(result).toEqual("all\nHello lua");
});

test("GetApplicableRules works with array glob", async () => {
	const usecase = new GetApplicableRules(rules);

	const result = await usecase.execute(["foo/bar.ts"]);
	expect(result).toEqual("all\nHello TypeScript");
});

test("GetApplicableRules works with multiple filepaths", async () => {
	const usecase = new GetApplicableRules(rules);

	const result = await usecase.execute(["foo/bar.lua", "baz/qux.ts"]);
	expect(result).toEqual("all\nHello lua\nHello TypeScript");
});

test("GetApplicableRules returns only 'all' when no specific rules match", async () => {
	const usecase = new GetApplicableRules(rules);

	const result = await usecase.execute(["foo/bar.js"]);
	expect(result).toEqual("all");
});

test("GetApplicableRules doesn't add duplicate content for the same rule", async () => {
	const usecase = new GetApplicableRules(rules);

	const result = await usecase.execute(["foo/bar.lua", "baz/qux.lua"]);
	expect(result).toEqual("all\nHello lua");
});
