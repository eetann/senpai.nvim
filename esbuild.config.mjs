import process from "node:process";
import esbuild from "esbuild";

const prod = process.argv[2] === "production";

const context = await esbuild.context({
	entryPoints: ["src/index.ts"],
	format: "esm",
	banner: {
		// commonjs用ライブラリをESMプロジェクトでbundleする際に生じることのある問題への対策
		js: `
import { createRequire } from "module";
import url from "url";
const require = createRequire(import.meta.url);
const __filename = url.fileURLToPath(import.meta.url);
const __dirname = url.fileURLToPath(new URL(".", import.meta.url));
`,
	},
	bundle: true,
	logLevel: "info",
	sourcemap: true,
	platform: "node",
	treeShaking: true,
	outdir: "./dist",
	outExtension: {
		".js": ".mjs",
	},
	external: ["esbuild"],
});

if (prod) {
	await context.rebuild();
	process.exit(0);
} else {
	await context.watch();
}
