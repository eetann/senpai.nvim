import { MCPConfiguration } from "@mastra/mcp";

export const mcp = new MCPConfiguration({
	servers: {
		sequential: {
			command: "bunx",
			args: ["-y", "@modelcontextprotocol/server-sequential-thinking"],
		},
		mastra: {
			command: "bunx",
			args: ["-y", "@mastra/mcp-docs-server@latest"],
		},
	},
});
