// env: TAG, VERSION, VERSION_CODE, GITHUB_REPOSITORY
import { execFileSync } from "node:child_process";
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import process from "node:process";

function fail(message: string): never {
    console.error(`make-update: ${message}`);
    process.exit(1);
}

function requireEnv(name: string): string {
    const value = process.env[name];
    if (value === undefined || value === "") {
        fail(`缺少环境变量 ${name}`);
    }
    return value;
}

const tag = requireEnv("TAG");
const version = requireEnv("VERSION");
const versionCode = Number(requireEnv("VERSION_CODE"));
const repo = requireEnv("GITHUB_REPOSITORY");
const outDir = process.env.OUT_DIR ?? "update-out";
const branch = process.env.UPDATE_BRANCH ?? "update";

if (!Number.isInteger(versionCode) || versionCode <= 0) {
    fail(`VERSION_CODE 不是正整数：${process.env.VERSION_CODE}`);
}

// 直接问 GitHub 要本次 release 的 asset 与正文，省得自己拼 URL
const release = JSON.parse(
    execFileSync("gh", ["release", "view", tag, "--json", "assets,body"], {
        encoding: "utf8",
    }),
) as {
    assets?: { name?: string; url?: string }[];
    body?: string;
};

const zipAsset = (release.assets ?? []).find(
    a => typeof a.name === "string" && a.name.toLowerCase().endsWith(".zip") && typeof a.url === "string" && a.url !== "",
);

if (zipAsset?.url == null) {
    const names = (release.assets ?? []).map(a => a.name).join(", ") || "(无)";
    fail(`release ${tag} 里找不到 zip 资源；现有资源：${names}`);
}

const zipUrl = zipAsset.url;
if (zipUrl === undefined || zipUrl === "") {
    fail(`release ${tag} 里找不到 zip 资源`);
}

const update = {
    version,
    versionCode,
    zipUrl,
    changelog: `https://raw.githubusercontent.com/${repo}/${branch}/changelog.md`,
};

mkdirSync(outDir, { recursive: true });
writeFileSync(join(outDir, "update.json"), `${JSON.stringify(update, null, 2)}\n`);
writeFileSync(join(outDir, "changelog.md"), `${(release.body ?? "").trim()}\n`);

console.log(`make-update: 已写入 ${outDir}/update.json 与 ${outDir}/changelog.md`);
console.log(JSON.stringify(update, null, 2));
