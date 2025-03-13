import { fn } from "../deps.ts";
import { assertEquals, simulateReadableStream, test } from "../test_deps.ts";
import { writeTextStreamToBuffer } from "./utils.ts";

test({
  mode: "nvim",
  name: "writeTextStreamToBuffer",
  fn: async (denops) => {
    await denops.call("has", "nvim");
    const textStream = simulateReadableStream({
      chunks: ["This ", "is ", "Test.\n", "こんにちは\n世界！", "Hello world!"],
    });
    const winid = await fn.win_getid(denops);
    await writeTextStreamToBuffer(denops, winid, 0, textStream);
    assertEquals(await fn.getline(denops, 1, "$"), [
      "This is Test.",
      "こんにちは",
      "世界！Hello world!",
    ]);
  },
});
