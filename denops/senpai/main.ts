import type { Entrypoint } from "jsr:@denops/std@^7.0.0";
// import { weatherAgent } from "./weather.ts";
import * as emoji from "npm:node-emoji";

export const main: Entrypoint = (denops) => {
  denops.dispatcher = {
    async hello() {
      console.log(emoji.emojify(`:sauropod: :heart:  npm`));
      // await denops.cmd(`echo "Hello, Denops!"`);
      // const response = await weatherAgent.generate([
      //   { role: "user", content: "Tokyo" },
      // ]);
      // await denops.cmd(`echo "${response.text}"`);
    },
  };
};
