import type { Entrypoint } from "jsr:@denops/std@^7.0.0";

export const main: Entrypoint = (denops) => {
  console.log("Hello, Denops from TypeScript!");
  denops.dispatcher = {
    async hello() {
      await denops.cmd(`echo "Hello, Denops!"`);
    },
  };
};
