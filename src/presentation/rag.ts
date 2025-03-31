import { vector } from "@/infra/Vector";
import { DeleteRagUrlUseCase } from "@/usecase/DeleteRagUrlUseCase";
import { FetchAndStoreUseCase } from "@/usecase/FetchAndStoreUseCase";
import { OpenAPIHono, createRoute, z } from "@hono/zod-openapi";

const app = new OpenAPIHono().basePath("/rag");

const ragSchema = z.discriminatedUnion("type", [
	z.object({
		type: z.literal("url"),
		url: z.string().url(),
	}),
]);

app.openapi(
	createRoute({
		method: "get",
		path: "/",
		responses: {
			200: {
				description: "get all RAG",
				content: {
					"application/json": {
						schema: z.array(z.string()),
					},
				},
			},
		},
	}),
	async (c) => {
		const indexes = await vector.listIndexes();
		return c.json(indexes);
	},
);

app.openapi(
	createRoute({
		method: "post",
		path: "/",
		request: {
			body: {
				required: true,
				content: {
					"application/json": {
						schema: ragSchema,
					},
				},
			},
		},
		responses: {
			200: {
				description: "fetch url and store as vector",
				content: {
					"application/json": {
						schema: z.object({
							message: z.string(),
						}),
					},
				},
			},
		},
	}),
	async (c) => {
		const content = c.req.valid("json");
		let message = "";
		if (content.type === "url") {
			message = await new FetchAndStoreUseCase(vector).execute(content.url);
		}
		return c.json({ message });
	},
);

app.openapi(
	createRoute({
		method: "delete",
		path: "/{indexName}",
		request: {
			params: z.object({ indexName: z.string() }),
		},
		responses: {
			204: {
				description: "delete specific index from RAG",
			},
			404: {
				description:
					"faild. Maybe you are specifying a resource that doesn't exist.",
			},
		},
	}),
	async (c) => {
		const { indexName } = c.req.valid("param");
		const result = await new DeleteRagUrlUseCase(vector).execute(indexName);
		if (result) {
			return new Response(undefined, { status: 204 });
		}
		return new Response(undefined, { status: 404 });
	},
);

export default app;
