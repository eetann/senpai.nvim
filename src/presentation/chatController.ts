import { GetFiles } from "@/infra/GetFiles";
import { getModel, providerConfigSchema } from "@/infra/GetModel";
import { memory } from "@/infra/Memory";
import { ChatAgent } from "@/usecase/agent/ChatAgent";
import { zValidator } from "@hono/zod-validator";
import { Hono } from "hono";
import { z } from "zod";

const app = new Hono();

const chatControllerCommandSchema = z.object({
	thread_id: z.string(),
	provider: z.optional(z.string()),
	provider_config: z.optional(providerConfigSchema),
	system_prompt: z.optional(z.string()),
	text: z.string(),
});

export type ChatControllerCommand = z.infer<typeof chatControllerCommandSchema>;

app.post(
	"/chat",
	zValidator("json", chatControllerCommandSchema),
	async (c) => {
		const command = c.req.valid("json");
		const model = getModel(command.provider, command.provider_config);
		const agent = new ChatAgent(memory, GetFiles, model, command.system_prompt);
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
		return agentStream.toDataStreamResponse();
	},
);

export default app;
