import { Glob } from "bun";
import type { ProjectRule } from "./shared/GetProjectRules";

export class GetApplicableRules {
	constructor(private rules: ProjectRule[]) {}
	// TODO: ルール再読み込みも実装したい

	async execute(filepaths: string[]): Promise<string> {
		const addedRules = new Set<string>();
		for (const rule of this.rules) {
			if (addedRules.has(rule.content)) {
				continue;
			}
			if (!rule.frontmatter?.globs) {
				addedRules.add(rule.content);
				continue;
			}
			const globs =
				typeof rule.frontmatter.globs === "string"
					? [rule.frontmatter.globs]
					: rule.frontmatter.globs;

			let matched = false;
			for (const glob_string of globs) {
				if (matched) break;
				for (const filepath of filepaths) {
					if (new Glob(glob_string).match(filepath)) {
						addedRules.add(rule.content);
						matched = true;
						break;
					}
				}
			}
		}
		return Array.from(addedRules).join("\n");
	}
}
