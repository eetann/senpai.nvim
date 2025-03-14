import { assertEquals, prepareVirtualFile } from "../test_deps.ts";
import { getFiles } from "./GetFiles.ts";

Deno.test("works", async () => {
  const encoder = new TextEncoder();
  prepareVirtualFile(".gitignore", new Uint8Array(encoder.encode("*.mp4")));
  const contentFoo = new Uint8Array(encoder.encode("hello"));
  prepareVirtualFile("foo.txt", contentFoo);
  const contentPiyo = new Uint8Array(encoder.encode("world!"));
  prepareVirtualFile("bar/piyo.txt", contentPiyo);
  prepareVirtualFile("ignore.mp4");
  // deno-lint-ignore require-await
  const glob = async function (_: string) {
    return ["bar/piyo.txt"];
  };

  const result = await getFiles(glob, ["foo.txt", "piyo.txt"]);
  assertEquals(result, [{
    type: "file",
    data: contentFoo,
    mimeType: "text/plain; charset=UTF-8",
  }, {
    type: "file",
    data: contentPiyo,
    mimeType: "text/plain; charset=UTF-8",
  }]);
});
