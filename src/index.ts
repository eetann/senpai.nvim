import { parseArgs } from "node:util";
import { swaggerUI } from "@hono/swagger-ui";
import { OpenAPIHono } from "@hono/zod-openapi";
import chat from "./presentation/chat";
import generateCommitMessage from "./presentation/generateCommitMessage";
import hello from "./presentation/hello";
import mcp from "./presentation/mcp";
import rag from "./presentation/rag";
import thread from "./presentation/thread";
import { GetMcpToolsUseCase } from "./usecase/GetMcpToolsUseCase";
import {
	GetProjectRules,
	type ProjectRule,
} from "./usecase/shared/GetProjectRules";

const { values } = parseArgs({
	args: Bun.argv,
	options: {
		port: {
			type: "string",
		},
		cwd: {
			type: "string",
		},
		mcp: {
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
let cwd = values.cwd;
if (!cwd || cwd === "") {
	cwd = process.cwd();
}
let mcpTools: Record<string, unknown> = { loading: {} };
// `await` slows down the server startup, so it should be done in IIFE
(async () => {
	mcpTools = await new GetMcpToolsUseCase(cwd).execute(values.mcp);
})();

const rules = await new GetProjectRules(cwd).execute();

type Variables = {
	cwd: string;
	mcpTools: Record<string, unknown>;
	rules: ProjectRule[];
};

const app = new OpenAPIHono<{ Variables: Variables }>();

app.use(async (c, next) => {
	c.set("cwd", cwd);
	c.set("mcpTools", mcpTools);
	c.set("rules", rules);
	await next();
});

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
app.route("/", rag);
app.route("/", mcp);

export default {
	idleTimeout: 60,
	port,
	fetch: app.fetch,
};
