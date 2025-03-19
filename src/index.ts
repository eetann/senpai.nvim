import { parseArgs } from "node:util";
import { OpenAPIHono } from "@hono/zod-openapi";
import chatController from "./presentation/chatController";
import generateCommitMessage from "./presentation/generateCommitMessage";
import hello from "./presentation/hello";
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

const app = new OpenAPIHono();

app.doc("/doc", {
	openapi: "3.0.0",
	info: {
		version: "0.0.1",
		title: "Senpai API",
	},
});
app.route("/", hello);
app.route("/", generateCommitMessage);
app.route("/", chatController);
app.route("/", historyController);

export default {
	port,
	fetch: app.fetch,
};
