import { fn } from "../deps.ts";
import { assertEquals, simulateReadableStream, test } from "../test_deps.ts";
import { writeTextStreamToBuffer } from "./utils.ts";

test({
  mode: "nvim",
  name: "writeTextStreamToBuffer",
  fn: async (denops) => {
    await denops.call("has", "nvim");
    const textStream = simulateReadableStream({
      chunks: ["This ", "is ", "Test.\n", "Hello!\n", "Hello world!"],
    });
    await writeTextStreamToBuffer(denops, 0, 0, textStream);
    assertEquals(await fn.getline(denops, 1, "$"), [
      "This is Test.",
      "Hello!",
      "Hello world!",
    ]);
  },
});
