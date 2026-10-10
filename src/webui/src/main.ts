import { toast } from "kernelsu";
import { applyUpdate, checkUpdate, moduleVersion, readStatus } from "./api";
import { bindThemeButton, initTheme } from "./theme";
import "./stylesheet.css";

const VIEWS = ["view-idle", "view-busy", "view-available", "view-uptodate", "view-failed", "view-note"] as const;
type ViewId = (typeof VIEWS)[number];

function el<T extends HTMLElement = HTMLElement>(id: string): T {
    const node = document.getElementById(id);
    if (!node) {
        throw new Error(`缺少节点 #${id}`);
    }
    return node as T;
}

function show(view: ViewId): void {
    for (const id of VIEWS) {
        el(id).hidden = id !== view;
    }
}

function setBusy(text: string): void {
    el("busy-text").textContent = text;
    show("view-busy");
}

function setNote(text: string): void {
    el("note-text").textContent = text;
    show("view-note");
}

function on(id: string, handler: () => void): void {
    el(id).addEventListener("click", handler);
}

function formatSize(bytes: string): string {
    let n = Number.parseInt(bytes, 10);
    if (!Number.isFinite(n) || n <= 0) {
        return "-";
    }
    const units = ["B", "KB", "MB", "GB"];
    let i = 0;
    while (n >= 1024 && i < units.length - 1) {
        n /= 1024;
        i++;
    }
    return `${i === 0 ? n : n.toFixed(1)} ${units[i]}`;
}

async function refreshStatus(): Promise<void> {
    const badge = el("status-badge");
    try {
        const s = await readStatus();
        badge.textContent = `● ${s.label}`;
        badge.classList.toggle("ok", s.loaded);
        badge.classList.toggle("fail", !s.loaded);
        el("status-kernel").textContent = s.kernel;
        el("status-variant").textContent = s.variant;
        el("status-susfs").textContent = s.susfs;
        el("status-size").textContent = formatSize(s.size);
    }
    catch (error) {
        badge.textContent = "读取失败";
        badge.classList.remove("ok");
        badge.classList.add("fail");
        toast(`读取状态失败：${(error as Error).message}`);
    }
}

async function detectUpdate(): Promise<void> {
    setBusy("正在查询上游…");
    try {
        const info = await checkUpdate();
        if (!info.tag) {
            setNote("上游没有可用的发布，请检查网络。");
            return;
        }
        if ((await readStatus()).susfs === info.tag) {
            el("uptodate-tag").textContent = info.tag;
            show("view-uptodate");
        }
        else {
            el("available-tag").textContent = info.tag;
            show("view-available");
        }
    }
    catch (error) {
        setNote(`检测失败：${(error as Error).message}`);
    }
}

const FAIL_REASONS: Record<string, string> = {
    download: "无法从上游下载匹配的驱动，请检查网络。",
    load: "驱动下载成功但内核拒绝加载，可能不是受支持的 GKI 变体。",
};

async function doUpdate(): Promise<void> {
    setBusy("正在下载并加载…");
    const result = await applyUpdate();

    if (result.ok) {
        toast(`已更新到 ${result.tag}`);
        await refreshStatus();
        setNote("更新完成，状态已刷新。");
        return;
    }

    toast("更新失败");
    el("failed-reason").textContent = FAIL_REASONS[result.reason] ?? "更新脚本执行失败。";
    el("failed-log").textContent = result.log;
    show("view-failed");
}

function main(): void {
    initTheme();
    bindThemeButton();

    const version = moduleVersion();
    if (version) {
        el("module-version").textContent = version;
    }

    if (!("ksu" in globalThis)) {
        const badge = el("status-badge");
        badge.classList.add("fail");
        throw new Error(badge.textContent = "未在 ksu 环境运行");
    }

    on("refresh-btn", () => void refreshStatus());
    on("check-btn", () => void detectUpdate());
    on("recheck-btn", () => void detectUpdate());
    on("do-update-btn", () => void doUpdate());
    on("retry-btn", () => void doUpdate());

    show("view-idle");
    void refreshStatus();
}

main();
