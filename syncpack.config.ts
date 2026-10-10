import type { RcFile } from "syncpack";
import { readFileSync } from "node:fs";

// Node 版本以 .nvmrc 为唯一来源，@types/node 跟着它走
const nodeVersion = readFileSync(new URL("./.nvmrc", import.meta.url), "utf8").trim();

export default {
    // 1. 所有依赖均使用精准包
    semverGroups: [
        {
            range: "",
            dependencies: ["**"],
        },
    ],
    // 2. 把 @types/node 锁定在 26.4.0
    versionGroups: [
        {
            dependencies: ["@types/node"],
            packages: ["**"],
            pinVersion: nodeVersion,
        },
        {
            dependencies: ["typescript"],
            packages: ["**"],
            pinVersion: "6.0.3",
        },
    ],
} satisfies RcFile;
