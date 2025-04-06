import { embeddingModel, getModel, providerSchema } from "@/infra/GetModel";
import { memory } from "@/infra/Memory";
import { vector } from "@/infra/Vector";
import { ChatAgent } from "@/usecase/agent/ChatAgent";
import { OpenAPIHono, createRoute, z } from "@hono/zod-openapi";

type Variables = {
	mcpTools: Record<string, unknown>;
};

const app = new OpenAPIHono<{ Variables: Variables }>().basePath("/chat");

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
				headers: {
					"Transfer-Encoding": {
						schema: {
							type: "string",
						},
						description: "chunked",
					},
					"X-Vercel-AI-Data-Stream": {
						schema: {
							type: "string",
							example: "v1",
						},
					},
				},
				description: "chat",
			},
		},
	}),
	async (c) => {
		const command = c.req.valid("json");
		const model = getModel(command.provider);
		const mcpTools = c.get("mcpTools");
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
				onFinish: async () => {
					if (isFirstMessage) {
						// insert metadata
						const thread = await memory.getThreadById({
							threadId: command.thread_id,
						});
						await memory.updateThread({
							id: command.thread_id,
							title: thread.title,
							metadata: {
								provider: command.provider,
								system_prompt: command.system_prompt ?? "",
							},
						});
					}
				},
			},
		);
		return agentStream.toDataStreamResponse();
	},
);

export default app;
