import { OpenAPIHono, createRoute, z } from "@hono/zod-openapi";
import {
	type AgentSettings,
	agentSettingsSchema,
} from "../domain/agentSettingsSchema";
import {
	loadProjectAgentSettings,
	mergeAgentSettings,
	checkAutoApproval,
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
	tool_type: z.enum(["replace_in_file", "execute_command"]),
	path: z.string().optional(),
	command: z.string().optional(),
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

			default:
				return c.json({ auto_approve: false });
		}
	},
);

export default app;

