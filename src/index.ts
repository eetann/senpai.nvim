import { parseArgs } from "node:util";
import { simulateReadableStream } from "ai";
import { Hono } from "hono";
import { stream } from "hono/streaming";
import chatController from "./presentation/chatController";
import generateCommitMessage from "./presentation/generateCommitMessage";

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
	return stream(c, async (stream) => {
		// Write a process to be executed when aborted.
		stream.onAbort(() => {
			console.log("Aborted!");
		});
		const textStream = simulateReadableStream({
			chunks: ["[senpai]\n", "Hello ", "Stream!\nbreak ", "test."],
			initialDelayInMs: 100,
			chunkDelayInMs: 1000,
		});
		await stream.pipe(textStream);
	});
});
app.route("/", generateCommitMessage);
app.route("/", chatController);

export default {
	port,
	fetch: app.fetch,
};
