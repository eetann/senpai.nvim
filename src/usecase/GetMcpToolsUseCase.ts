import path from "node:path";
import {
	mastraMCPConfigurationSchema,
	projectMCPConfigurationSchema,
} from "@/domain/MCPSchema";
import { MCPConfiguration, type MastraMCPServerDefinition } from "@mastra/mcp";

type Servers = Record<string, MastraMCPServerDefinition>;

let configuration: undefined | MCPConfiguration = undefined;

export class GetMcpToolsUseCase {
	private dir: string;
	constructor(cwd: string, prompts_dir = ".senpai") {
		this.dir = path.join(cwd, prompts_dir);
	}

	async execute(processArg?: string) {
		const file = Bun.file(path.join(this.dir, "mcp.json"));
		let projectServers = {};
		if (await file.exists()) {
			const projectConfigure = await file.text();
			projectServers = this.parse(projectConfigure, true);
		}
		const editorServers = this.parse(processArg);
		if (configuration) {
			await configuration.disconnect();
		}
		configuration = new MCPConfiguration({
			servers: <Servers>{ ...editorServers, ...projectServers },
		});
		return await configuration.getTools();
	}

	parse(text: string | null | undefined, isProjectConfigure = false) {
		if (!text) {
			return {};
		}
		let parsedJson = {};
		try {
			parsedJson = JSON.parse(text);
		} catch (error) {
			console.error(
				`[senpai] JSON parsing of MCP configuration failed: ${error}`,
			);
			return {};
		}
		if (isProjectConfigure) {
			const result = projectMCPConfigurationSchema.safeParse(parsedJson);
			if (!result.success) {
				console.error(
					`[senpai] parsing of project MCP configuration failed: ${result.error}`,
				);
				return {};
			}
			return result.data.mcpServers;
		}
		const result = mastraMCPConfigurationSchema.safeParse(parsedJson);
		if (!result.success) {
			console.error(
				`[senpai] parsing of editor MCP configuration failed: ${result.error}`,
			);
			return {};
		}
		return result.data;
	}
}
