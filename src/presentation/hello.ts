import { OpenAPIHono, createRoute } from "@hono/zod-openapi";
import { simulateReadableStream } from "ai";

const app = new OpenAPIHono().basePath("/hello");

const helloRoute = createRoute({
	method: "get",
	path: "/",
	responses: {
		200: {
			description: "For API communication check",
		},
	},
});

app.openapi(helloRoute, (c) => c.text("[senpai] Hello from Bun!"));

const helloStreamRoute = createRoute({
	method: "post",
	path: "/stream",
	responses: {
		200: {
			description: "For stream check",
		},
	},
});

app.openapi(helloStreamRoute, () => {
	return new Response(
		simulateReadableStream({
			chunks: [
				`f:{"messageId":"step_123"}\n`,
				`0:"[senpai] "\n`,
				`0:"Hello!\\nThis "\n`,
				`0:"is example."\n`,
				`e:{"finishReason":"stop","usage":{"promptTokens":20,"completionTokens":50},"isContinued":false}\n`,
				`d:{"finishReason":"stop","usage":{"promptTokens":20,"completionTokens":50}}\n`,
			],
			initialDelayInMs: 100,
			chunkDelayInMs: 1000,
		}).pipeThrough(new TextEncoderStream()),
		{
			status: 200,
			headers: {
				"X-Vercel-AI-Data-Stream": "v1",
				"Content-Type": "text/plain; charset=utf-8",
			},
		},
	);
});

export default app;
