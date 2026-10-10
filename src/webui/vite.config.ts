import { defineConfig } from "vite";

export default defineConfig({
    // WebUI 是从本地路径打开的，资源必须用相对路径
    base: "./",
    build: {
        outDir: "dist",
        emptyOutDir: true,
    },
});
