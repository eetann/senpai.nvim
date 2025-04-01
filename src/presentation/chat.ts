import { embeddingModel, getModel, providerSchema } from "@/infra/GetModel";
import { memory } from "@/infra/Memory";
import { vector } from "@/infra/Vector";
import { ChatAgent } from "@/usecase/agent/ChatAgent";
import { OpenAPIHono, createRoute, z } from "@hono/zod-openapi";
import { MCPConfiguration } from "@mastra/mcp";

const app = new OpenAPIHono().basePath("/chat");

const chatControllerSchema = z.object({
	thread_id: z.string(),
	provider: providerSchema,
	system_prompt: z.optional(z.string()),
	text: z.string(),
});

app.openapi(
	createRoute({
		method: "post",
		path: "/",
		request: {
			body: {
				required: true,
				content: {
					"application/json": {
						schema: chatControllerSchema,
					},
				},
			},
		},
		responses: {
			200: {
				description: "chat",
			},
		},
	}),
	async (c) => {
		const command = c.req.valid("json");
		const model = getModel(command.provider);
		const mcp = new MCPConfiguration({
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
		const mcpTools = await mcp.getTools();
		const agent = new ChatAgent(
			memory,
			vector,
			model,
			embeddingModel,
			mcpTools,
			command.system_prompt,
		);
		const thread = await memory.getThreadById({ threadId: command.thread_id });
		let isFirstMessage = false;
		if (thread == null) {
			isFirstMessage = true;
		}
		const agentStream = await agent.stream(
			[
				{
					role: "user",
					content: command.text,
				},
			],
			{
				threadId: command.thread_id,
				resourceId: "senpai",
			},
		);
		if (isFirstMessage) {
			const thread = await memory.getThreadById({
				threadId: command.thread_id,
			});
			await memory.updateThread({
				id: command.thread_id,
				title: thread.title,
				metadata: {
					provider: command.provider,
					system_prompt: command.system_prompt,
				},
			});
		}
		return agentStream.toDataStreamResponse();
	},
);

export default app;
