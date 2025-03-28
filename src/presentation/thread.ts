import { messageSchema } from "@/domain/messageSchema";
import { providerSchema } from "@/infra/GetModel";
import { memory } from "@/infra/Memory";
import { DeleteThreadsUseCase } from "@/usecase/DeleteThreadsUseCase";
import { GetMessagesUseCase } from "@/usecase/GetMessagesUseCase";
import { GetThreadByIdUseCase } from "@/usecase/GetThreadByIdUseCase";
import { GetThreadsUseCase } from "@/usecase/GetThreadsUseCase";
import { OpenAPIHono, createRoute, z } from "@hono/zod-openapi";

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
		const threads = await new GetThreadsUseCase(memory).execute();
		return c.json(threads);
	},
);

app.openapi(
	createRoute({
		method: "get",
		path: "/{id}",
		request: {
			params: z.object({ id: z.string() }),
		},
		responses: {
			200: {
				description: "a thread",
				content: {
					"application/json": {
						schema: threadSchema,
					},
				},
			},
		},
	}),
	async (c) => {
		const { id } = c.req.valid("param");
		const thread = await new GetThreadByIdUseCase(memory).execute(id);
		return c.json(thread);
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
	const threads = await new GetMessagesUseCase(memory).execute(thread_id);
	return c.json(threads);
});

app.openapi(
	createRoute({
		method: "delete",
		path: "/{id}",
		request: {
			params: z.object({ id: z.string() }),
		},
		responses: {
			204: {
				description: "delete thread",
			},
		},
	}),
	async (c) => {
		const { id } = c.req.valid("param");
		await new DeleteThreadsUseCase(memory).execute(id);
		return new Response(undefined, { status: 204 });
	},
);

export default app;
