import { Agent, type AgentConfig, type ToolsInput } from "@mastra/core/agent";
import { LIBSQL_PROMPT, type LibSQLVector } from "@mastra/libsql";
import type { Memory } from "@mastra/memory";
import type { EmbeddingModel } from "ai";
import { z } from "zod";
import { VectorQueryTool } from "../tool/VectorQueryTool";
import { getBasePrompt } from "./getBasePrompt";

export const ChatSchema = z.string();

export class ChatAgent extends Agent {
	constructor(
		cwd: string,
		memory: Memory,
		vector: LibSQLVector,
		model: AgentConfig["model"],
		embeddingModel: EmbeddingModel<string>,
		mcpTools: Record<string, unknown>,
		system_prompt: string,
		useRag: boolean,
	) {
		const tools = mcpTools as ToolsInput;
		let prompt = getBasePrompt(cwd);
		if (useRag) {
			console.log("user RAG!");
			prompt += `\n### VectorQueryTool\n${LIBSQL_PROMPT}`;
			tools.VectorQueryTool = VectorQueryTool(vector, embeddingModel);
		}
		prompt += `\n${system_prompt}`;
		super({
			name: "chat agent",
			instructions: prompt,
			model,
			tools,
			memory,
		});
	}
}
