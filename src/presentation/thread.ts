import { providerSchema } from "@/infra/GetModel";
import { memory } from "@/infra/Memory";
import { GetHistoryUseCase } from "@/usecase/GetHistoryUseCase";
import { GetThreadUseCase } from "@/usecase/GetThreadUseCase";
import { z } from "@hono/zod-openapi";
import { OpenAPIHono, createRoute } from "@hono/zod-openapi";

const app = new OpenAPIHono().basePath("/thread");

const threadSchema = z.object({
	id: z.string().openapi({ example: "/home/eetann/workspace-20250318163153" }),
	resourceId: z.string().openapi({ example: "senpai" }),
	title: z.optional(
		z.string().openapi({ example: "how to develop Neovim plugin" }),
	),
	createdAt: z.string().openapi({ example: "2025-03-18T07:32:02.912Z" }),
	updatedAt: z.string().openapi({ example: "2025-03-18T07:32:02.912Z" }),
	metadata: z.optional(z.object({ provider: providerSchema }).partial()),
});

// import { CoreMessage } from "ai";
// type CoreMessage
const messageSchema = z.discriminatedUnion("role", [
	z.object({ role: z.literal("system"), content: z.string() }),
	z.object({
		role: z.literal("user"),
		content: z.union([z.string(), z.array(z.any())]),
	}),
	z.object({
		role: z.literal("assistant"),
		content: z.union([z.string(), z.any()]),
	}),
	z.object({ role: z.literal("tool"), content: z.array(z.any()) }),
]);

app.openapi(
	createRoute({
		method: "get",
		path: "/",
		responses: {
			200: {
				description: "List of threads",
				content: {
					"application/json": {
						schema: z.array(threadSchema),
					},
				},
			},
		},
	}),
	async (c) => {
		const threads = await new GetHistoryUseCase(memory).execute();
		return c.json(threads);
	},
);

const route = createRoute({
	method: "post",
	path: "/messages",
	request: {
		body: {
			required: true,
			content: {
				"application/json": {
					schema: z.object({
						thread_id: z.string({ description: "thread id" }),
					}),
				},
			},
		},
	},
	responses: {
		200: {
			description: "List of messages in the specified thread",
			content: {
				"application/json": {
					schema: z.array(messageSchema),
				},
			},
		},
	},
});

app.openapi(route, async (c) => {
	const { thread_id } = c.req.valid("json");
	const threads = await new GetThreadUseCase(memory).execute(thread_id);
	return c.json(threads);
});

export default app;
