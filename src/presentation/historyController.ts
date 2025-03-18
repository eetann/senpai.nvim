import { memory } from "@/infra/Memory";
import { GetHistoryUseCase } from "@/usecase/GetHistoryUseCase";
import { GetThreadUseCase } from "@/usecase/GetThreadUseCase";
import { zValidator } from "@hono/zod-validator";
import { Hono } from "hono";
import { z } from "zod";

const app = new Hono();

app.post("/get-history", async (c) => {
	const threads = await new GetHistoryUseCase(memory).execute();
	return c.json(threads);
});

const getThreadSchema = z.string();

app.post("/get-thread", zValidator("json", getThreadSchema), async (c) => {
	const threadId = c.req.valid("json");
	const threads = await new GetThreadUseCase(memory).execute(threadId);
	return c.json(threads);
});

export default app;
