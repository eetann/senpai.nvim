import { parseArgs } from "node:util";
import { Hono } from "hono";
import { streamText } from "hono/streaming";
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
	return streamText(c, async (stream) => {
		await stream.writeln("[senpai] ");
		await stream.sleep(1000);
		await stream.writeln("Hello ");
		await stream.sleep(1000);
		await stream.write("Stream!");
	});
});
app.route("/", generateCommitMessage);
app.route("/", chatController);

export default {
	port,
	fetch: app.fetch,
};
