import { OpenAPIHono, createRoute, z } from "@hono/zod-openapi";
import {
	type AgentSettings,
	agentSettingsSchema,
} from "../domain/agentSettingsSchema";
import {
	loadProjectAgentSettings,
	mergeAgentSettings,
} from "../usecase/agent/AgentSettingsUseCase";

type Variables = {
	cwd: string;
	agentSettings: AgentSettings;
};

const app = new OpenAPIHono<{ Variables: Variables }>().basePath("/agent");
// Update agent settings endpoint
app.openapi(
	createRoute({
		method: "post",
		path: "/settings",
		request: {
			body: {
				content: {
					"application/json": { schema: agentSettingsSchema },
				},
			},
		},
		responses: {
			200: {
				description: "Agent settings updated",
				content: {
					"application/json": {
						schema: z.object({
							success: z.boolean(),
							settings: agentSettingsSchema,
						}),
					},
				},
			},
		},
	}),
	async (c) => {
		const pluginSettings = c.req.valid("json");

		const cwd = c.get("cwd");
		const projectSettings = loadProjectAgentSettings(cwd);

		const mergedSettings = mergeAgentSettings(pluginSettings, projectSettings);
		c.set("agentSettings", mergedSettings);

		return c.json({ success: true, settings: mergedSettings });
	},
);

// Tool auto approval request schema
const toolAutoRequestSchema = z.object({
	tool_type: z.enum(["replace_in_file", "execute_command", "search_files"]),
	path: z.string().optional(),
	command: z.string().optional(),
	regex: z.string().optional(),
	filePattern: z.string().optional(),
});

// Auto approval check endpoint
app.openapi(
	createRoute({
		method: "post",
		path: "/auto",
		request: {
			body: {
				content: {
					"application/json": { schema: toolAutoRequestSchema },
				},
			},
		},
		responses: {
			200: {
				description: "Auto approval check result",
				content: {
					"application/json": {
						schema: z.object({
							auto_approve: z.boolean(),
						}),
					},
				},
			},
		},
	}),
	async (c) => {
		const { tool_type, ...params } = c.req.valid("json");

		const agentSettings = c.get("agentSettings");
		if (!agentSettings?.auto_accept) {
			return c.json({ auto_approve: false });
		}

		const autoAccept = agentSettings.auto_accept;

		switch (tool_type) {
			case "replace_in_file": {
				const { path } = params;
				if (!path) {
					return c.json({ auto_approve: false });
				}

				const config = autoAccept.replace_in_file;
				if (config === undefined || config === false) {
					return c.json({ auto_approve: false });
				}

				if (config === true) {
					return c.json({ auto_approve: true });
				}

				// Check if path matches any of the patterns
				const patterns = config as string[];
				const matches = patterns.some((pattern) => {
					if (pattern.includes("*")) {
						// Simple glob pattern matching
						const regex = new RegExp(`^${pattern.replace(/\*/g, ".*")}$`);
						return regex.test(path);
					}
					return path.includes(pattern);
				});

				return c.json({ auto_approve: matches });
			}

			case "execute_command": {
				const { command } = params;
				if (!command) {
					return c.json({ auto_approve: false });
				}

				const config = autoAccept.execute_command;
				if (config === undefined || config === false) {
					return c.json({ auto_approve: false });
				}

				if (config === true) {
					return c.json({ auto_approve: true });
				}

				// Check if command matches any of the patterns
				const patterns = config as string[];
				const matches = patterns.some((pattern) => pattern === command);

				return c.json({ auto_approve: matches });
			}

			case "search_files": {
				const { path } = params;
				if (!path) {
					return c.json({ auto_approve: false });
				}

				const config = autoAccept.search_files;
				if (config === undefined || config === false) {
					return c.json({ auto_approve: false });
				}

				if (config === true) {
					return c.json({ auto_approve: true });
				}

				// Check if path matches any of the patterns
				const patterns = config as string[];
				const matches = patterns.some((pattern) => {
					if (pattern.includes("*")) {
						// Simple glob pattern matching
						const regex = new RegExp(`^${pattern.replace(/\*/g, ".*")}$`);
						return regex.test(path);
					}
					return path.includes(pattern);
				});

				return c.json({ auto_approve: matches });
			}

			default:
				return c.json({ auto_approve: false });
		}
	},
);

// Search files endpoint schema
const searchFilesRequestSchema = z.object({
	path: z.string(),
	regex: z.string(),
	filePattern: z.string().default("*"),
});

const searchFilesResponseSchema = z.object({
	results: z.string(),
});

// Search files endpoint for agent tools
app.openapi(
	createRoute({
		method: "post",
		path: "/search_files",
		request: {
			body: {
				required: true,
				content: {
					"application/json": {
						schema: searchFilesRequestSchema,
					},
				},
			},
		},
		responses: {
			200: {
				description: "Search results",
				content: {
					"application/json": {
						schema: searchFilesResponseSchema,
					},
				},
			},
			500: {
				description: "Server error",
				content: {
					"application/json": {
						schema: z.object({
							error: z.string(),
						}),
					},
				},
			},
		},
	}),
	async (c) => {
		const { path, regex, filePattern } = c.req.valid("json");
		const cwd = c.get("cwd");

		try {
			// Check if ripgrep is available
			const { spawnSync } = await import("node:child_process");
			const rgCheck = spawnSync("which", ["rg"], { encoding: "utf8" });
			const hasRipgrep = rgCheck.status === 0;

			let results = "";
			let count = 0;

			if (hasRipgrep) {
				// Use ripgrep
				const rgResult = spawnSync(
					"rg",
					[
						"--no-heading",
						"--line-number",
						"--with-filename",
						"--color=never",
						"-g",
						filePattern,
						regex,
						path,
					],
					{
						cwd,
						encoding: "utf8",
						maxBuffer: 1024 * 1024 * 10, // 10MB
					},
				);

				if (rgResult.error) {
					throw new Error(`ripgrep error: ${rgResult.error.message}`);
				}

				results = rgResult.stdout || "";
			} else {
				// Use grep as fallback
				const grepResult = spawnSync("grep", ["-r", "-n", "-E", regex, path], {
					cwd,
					encoding: "utf8",
					maxBuffer: 1024 * 1024 * 10, // 10MB
				});

				if (grepResult.error) {
					throw new Error(`grep error: ${grepResult.error.message}`);
				}

				results = grepResult.stdout || "";

				// Filter by file pattern if using grep
				if (filePattern !== "*") {
					const lines = results.split("\n");
					const pattern = new RegExp(`^${filePattern.replace(/\*/g, ".*")}`);
					results = lines
						.filter((line) => {
							const match = line.match(/^([^:]+):/);
							if (match) {
								return pattern.test(match[1]);
							}
							return false;
						})
						.join("\n");
				}
			}

			// Count and truncate results
			const lines = results.split("\n").filter((line) => line.trim() !== "");
			count = lines.length;

			if (count > 499) {
				results = `${lines.slice(0, 499).join("\n")}\n[truncated...]`;
			}

			return c.json({ results }, 200);
		} catch (error) {
			return c.json(
				{ error: error instanceof Error ? error.message : "Unknown error" },
				500,
			);
		}
	},
);

export default app;
