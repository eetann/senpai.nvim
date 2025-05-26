import { spawnSync } from "node:child_process";
import { unlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, relative } from "node:path";
import { AbstractHandler } from "./AbstractHandler";

/**
 * Handler for <replace_in_file> tag.
 */
export class ReplaceInFileHandler extends AbstractHandler {
	tagName = "replace_in_file";

	path = "";
	searchText = "";
	replaceText = "";
	diffText = "";

	cwd: string;

	constructor(cwd: string) {
		super();
		this.cwd = cwd;
		// Register handlers for each tag
		this.handlers.set("<path>", this.pathTag.bind(this));
		this.handlers.set("<search>", this.startSearchTag.bind(this));
		this.handlers.set("</search>", this.endSearchTag.bind(this));
		this.handlers.set("<replace>", this.startReplaceTag.bind(this));
		this.handlers.set("</replace>", this.endReplaceTag.bind(this));
	}

	startTag(): void {
		this.currentTag = "replace_in_file";
		this.currentContent = "";
	}

	endTag(): void {
		this.diffText = getDiffText(this.searchText, this.replaceText);
		this.currentTag = null;
	}

	contentLine(chunk: string): void {
		this.currentContent += chunk;
	}

	private pathTag(_chunk?: string, line?: string): void {
		if (!line) return;
		this.path = getRelativePath(
			this.cwd,
			line.replace(/<\/?path>/g, "").trim(),
		);
		this.currentContent = "";
	}

	private startSearchTag(): void {
		this.currentTag = "search";
		this.currentContent = "";
	}

	private endSearchTag(chunk?: string): void {
		if (chunk) this.currentContent += chunk;
		this.searchText = this.currentContent.replace(/\n<\/search>\n?$/, "");
		this.currentTag = null;
	}

	private startReplaceTag(): void {
		this.currentTag = "replace";
		this.currentContent = "";
	}

	private endReplaceTag(chunk?: string): void {
		if (chunk) this.currentContent += chunk;
		this.replaceText = this.currentContent.replace(/\n<\/replace>\n?$/, "");
		this.currentTag = null;
	}
}

/**
 * Returns the relative path from cwd to path.
 * If cwd or path is empty, returns path as is.
 */
function getRelativePath(cwd: string, path: string): string {
	if (!cwd || !path) return path;
	return relative(cwd, path);
}

/**
 * Returns the diff between two strings using `git diff --no-index`.
 */
function getDiffText(search: string, replace: string): string {
	if (search === replace) return "";
	const tmp1 = join(tmpdir(), `senpai_diff1_${Date.now()}_${Math.random()}`);
	const tmp2 = join(tmpdir(), `senpai_diff2_${Date.now()}_${Math.random()}`);
	try {
		writeFileSync(tmp1, search, "utf8");
		writeFileSync(tmp2, replace, "utf8");
		const result = spawnSync("git", ["diff", "--no-index", tmp1, tmp2], {
			encoding: "utf8",
		});
		const output = result.stdout || "";
		const lines = output.split("\n");
		let text = "";
		if (lines.length >= 6) {
			text = lines.slice(5).join("\n");
		}
		return text;
	} catch (e) {
		return "";
	} finally {
		try {
			unlinkSync(tmp1);
		} catch {}
		try {
			unlinkSync(tmp2);
		} catch {}
	}
}
