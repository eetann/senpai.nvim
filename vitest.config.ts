import { defineConfig } from "vitest/config";

export default defineConfig({
	test: {
		alias: {
			"@/": `${__dirname}/src/`,
		},
		include: ["src/**/*.test.ts"],
	},
});
