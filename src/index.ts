import { Hono } from "hono";
import generateCommitMessage from "./presentation/generateCommitMessage";

const app = new Hono();

app.post("/hello", (c) => c.text("[senpai] Hello from Bun!"));
app.route("/", generateCommitMessage);

export default app;
