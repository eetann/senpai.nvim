import { parseArgs } from "node:util";
import { simulateReadableStream } from "ai";
import { Hono } from "hono";
import chatController from "./presentation/chatController";
import generateCommitMessage from "./presentation/generateCommitMessage";
import historyController from "./presentation/historyController";

const { values } = parseArgs({
	args: Bun.argv,
	options: {
		port: {
			type: "string",
		},
	},
	strict: true,
	allowPositionals: true,
});

let port = Number(values.port);
if (Number.isNaN(port)) {
	port = 0;
}

const app = new Hono();

app.post("/hello", (c) => c.text("[senpai] Hello from Bun!"));
app.post("/helloStream", (c) => {
	return new Response(
		simulateReadableStream({
			chunks: [
				`f:{"messageId":"step_123"}\n`,
				`0:"[senapi] "\n`,
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
app.route("/", generateCommitMessage);
app.route("/", chatController);
app.route("/", historyController);

export default {
	port,
	fetch: app.fetch,
};
