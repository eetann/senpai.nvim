import { parseArgs } from "node:util";
import { Hono } from "hono";
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

const port = Number(values.port);
if (Number.isNaN(port)) {
	console.error("[senpai] Failed because port is wrong");
	process.exit(1);
}

const app = new Hono();

app.post("/hello", (c) => c.text("[senpai] Hello from Bun!"));
app.route("/", generateCommitMessage);

export default {
	port,
	fetch: app.fetch,
};
