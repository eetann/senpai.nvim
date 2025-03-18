import { memory } from "@/infra/Memory";
import { GetHistoryUseCase } from "@/usecase/GetHistoryUseCase";
import { Hono } from "hono";

const app = new Hono();

app.post("/get-history", async (c) => {
	const threads = await new GetHistoryUseCase(memory).execute();
	return c.json(threads);
});

export default app;
