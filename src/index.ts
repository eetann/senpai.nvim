import { parseArgs } from "node:util";
import { swaggerUI } from "@hono/swagger-ui";
import { OpenAPIHono } from "@hono/zod-openapi";
import chat from "./presentation/chat";
import generateCommitMessage from "./presentation/generateCommitMessage";
import hello from "./presentation/hello";
import thread from "./presentation/thread";

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

app.doc31("/openapi.json", {
	openapi: "3.1.0",
	info: {
		version: "0.0.1",
		title: "Senpai API",
	},
});
app.get("/doc", swaggerUI({ url: "/openapi.json" }));
app.route("/", hello);
app.route("/", generateCommitMessage);
app.route("/", chat);
app.route("/", thread);

export default {
	port,
	fetch: app.fetch,
};
