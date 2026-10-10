// 和模块里的 shell 脚本打交道。界面相关的东西一概不放在这里。
import { exec, moduleInfo } from "kernelsu";
import { first, parseKV } from "./protocol";

const MODDIR = "/data/adb/modules/susfs4ksu_lkm";

export interface Status {
    label: string;
    kernel: string;
    variant: string;
    susfs: string;
    size: string;
    loaded: boolean;
}

export interface UpdateInfo {
    tag: string;
    variant: string;
}

export interface UpdateResult {
    ok: boolean;
    reason: string;
    log: string;
    tag: string;
}

async function run(command: string): Promise<string> {
    const { errno, stdout, stderr } = await exec(command);
    if (errno !== 0) {
        throw new Error((stderr || stdout || `命令失败 (errno ${errno})`).trim());
    }
    return stdout;
}

export async function readStatus(): Promise<Status> {
    const m = parseKV(await run(`sh ${MODDIR}/status.sh`));
    return {
        label: first(m, "state_label", "未知"),
        kernel: first(m, "kernel", "未知"),
        variant: first(m, "variant", "-"),
        susfs: first(m, "susfs", "未知"),
        size: first(m, "size", "0"),
        loaded: first(m, "loaded") === "1",
    };
}

export async function checkUpdate(): Promise<UpdateInfo> {
    const m = parseKV(await run(`sh ${MODDIR}/check.sh`));
    return { tag: first(m, "tag"), variant: first(m, "variant") };
}

export async function applyUpdate(): Promise<UpdateResult> {
    const { errno, stdout, stderr } = await exec(`sh ${MODDIR}/update.sh`);
    const log = `${stdout}${stderr}`.trim();
    const m = parseKV(log);
    return {
        ok: errno === 0 && first(m, "result") === "ok",
        reason: first(m, "reason"),
        log,
        tag: first(m, "tag"),
    };
}

// 模块自身的版本，从管理器拿；拿不到就返回空串
export function moduleVersion(): string {
    try {
        const info = JSON.parse(moduleInfo()) as { version?: string };
        return info.version ?? "";
    }
    catch {
        return "";
    }
}
