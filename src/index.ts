import { Hono } from "hono";
import generateCommitMessage from "./presentation/generateCommitMessage";

const app = new Hono();

app.get("/hello", (c) => c.text("[senpai] Hello!"));
app.route("/", generateCommitMessage);

export default app;
