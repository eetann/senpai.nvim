import process from "node:process";
import esbuild from "esbuild";

const prod = process.argv[2] === "production";

const context = await esbuild.context({
	entryPoints: ["src/index.ts"],
	format: "esm",
	bundle: true,
	logLevel: "info",
	sourcemap: true,
	platform: "node",
	treeShaking: true,
	outfile: "dist/index.js",
});

if (prod) {
	await context.rebuild();
	process.exit(0);
} else {
	await context.watch();
}
