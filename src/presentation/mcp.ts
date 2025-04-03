import { OpenAPIHono, createRoute, z } from "@hono/zod-openapi";

type Variables = {
	mcpTools: Record<string, unknown>;
};

const app = new OpenAPIHono<{ Variables: Variables }>().basePath("/mcp");

app.openapi(
	createRoute({
		method: "get",
		path: "/",
		responses: {
			200: {
				description: "current MCP tools",
				content: {
					"application/json": { schema: z.record(z.string(), z.any()) },
				},
			},
		},
	}),
	(c) => {
		const mcpTools = c.get("mcpTools");
		return c.json(mcpTools);
	},
);

export default app;
