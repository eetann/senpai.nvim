import { mastraMCPConfigurationSchema } from "@/domain/MCPSchema";
import { MCPConfiguration, type MastraMCPServerDefinition } from "@mastra/mcp";

type Servers = Record<string, MastraMCPServerDefinition>;

export class GetMcpToolsUseCase {
	async execute(processArg?: string) {
		const servers = this.parse(processArg);
		const mcp = new MCPConfiguration({
			servers: <Servers>servers,
		});
		return await mcp.getTools();
	}

	parse(processArg?: string) {
		if (!processArg) {
			return {};
		}
		let parsedJson = {};
		try {
			parsedJson = JSON.parse(processArg);
		} catch (error) {
			console.error(
				`[senpai] JSON parsing of MCP configuration failed: ${error}`,
			);
			return {};
		}
		const result = mastraMCPConfigurationSchema.safeParse(parsedJson);
		if (!result.success) {
			console.error(
				`[senpai] parsing of MCP configuration failed${result.error}`,
			);
			return {};
		}
		return result.data;
	}
}
