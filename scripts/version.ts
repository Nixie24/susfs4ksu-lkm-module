import { readFileSync } from "node:fs";
import process from "node:process";

const pkg = JSON.parse(
    readFileSync(new URL("../package.json", import.meta.url), "utf8"),
) as { version?: string };
const version = String(pkg.version);

const match = /^(\d+)\.(\d+)\.(\d+)$/.exec(version);
if (!match) {
    console.error(`version.ts: package.json version 必须是 A.B.C，当前: ${pkg.version}`);
    process.exit(1);
}

// versionCode = 主版本 * 10000 + 次版本 * 100 + 修订号
const major = Number(match[1]);
const minor = Number(match[2]);
const patch = Number(match[3]);
console.log(`${version} ${major * 10000 + minor * 100 + patch}`);
