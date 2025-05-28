import { spawnSync } from "node:child_process";
import { unlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, relative } from "node:path";
import { AbstractHandler, Part, type WriteFunction } from "./AbstractHandler";

export type DiffText = {
	search: string;
	replace: string;
	diff: string;
};

/**
 * Handler for <replace_in_file> tag.
 */
export class ReplaceInFileHandler extends AbstractHandler {
	tagName = "replace_in_file";
	toolName = "ReplaceInFile";

	path = "";
	diffs: DiffText[] = [];

	cwd: string;

	constructor(writeFunction: WriteFunction, cwd: string) {
		super(writeFunction);
		this.cwd = cwd;
		// Register handlers for each tag
		this.handlers.set("<path>.*</path>", this.pathTag.bind(this));
		this.handlers.set("<diff>", this.startDiffTag.bind(this));
		this.handlers.set("</diff>", this.endDiffTag.bind(this));
	}

	startTag(): void {
		this.currentTag = "replace_in_file";
		this.currentContent = "";
	}

	endTag(): void {
		this.writeFunction(Part.toolCall, {
			toolCallId: `${this.toolName}-${Date.toString()}`,
			toolName: this.toolName,
			result: {
				diffs: this.diffs,
			},
		});
		this.currentTag = null;
		this.currentContent = "";
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
		this.writeFunction(Part.toolCall, {
			toolCallId: `${this.toolName}-${Date.toString()}`,
			toolName: this.toolName,
			args: {
				path: this.path,
			},
		});
	}

	private startDiffTag(): void {
		this.currentTag = "diff";
		this.currentContent = "";
	}

	private endDiffTag(chunk?: string): void {
		if (chunk) this.currentContent += chunk;
		const content = this.currentContent.replace(/\n<\/diff>\n?$/, "");
		this.diffs = parseConflictDiffBlocks(content);
		this.currentTag = null;
	}
}

/**
 * コンフリクトマーカーで区切られたdiffブロックをパースしてDiffText[]に変換
 */
function parseConflictDiffBlocks(content: string): DiffText[] {
	const blocks = content
		.split(/(?=^<<<<<<< SEARCH)/m)
		.filter((b) => b.startsWith("<<<<<<< SEARCH"));
	const result: DiffText[] = [];
	for (const block of blocks) {
		const match = block.match(
			/^<<<<<<< SEARCH\s*([\s\S]*?)^=======\s*([\s\S]*?)^>>>>>>> REPLACE/m,
		);
		if (match) {
			const search = match[1].replace(/\n$/, "");
			const replace = match[2].replace(/\n$/, "");
			const diff = getDiffText(search, replace);
			result.push({ search, replace, diff });
		}
	}
	return result;
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
