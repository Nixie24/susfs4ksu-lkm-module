// 主题：在 <html> 上挂/摘 .dark，选择记在 localStorage。
// 没存过就跟随系统第一次的偏好，之后以用户的选择为准。

const KEY = "theme";
const BTN = "theme-btn";

type Mode = "dark" | "light";

function stored(): Mode | null {
    try {
        const value = localStorage.getItem(KEY);
        return value === "dark" || value === "light" ? value : null;
    }
    catch {
        // 隐私模式等场合读不了，当作没存过
        return null;
    }
}

function save(mode: Mode): void {
    try {
        localStorage.setItem(KEY, mode);
    }
    catch {
        // 存不了就算了，本次会话内仍然生效
    }
}

function systemPrefers(): Mode {
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
}

function apply(mode: Mode): void {
    document.documentElement.classList.toggle("dark", mode === "dark");

    const btn = document.getElementById(BTN);
    if (btn) {
        // 图标显示的是"点一下会切到哪"
        btn.textContent = mode === "dark" ? "☀️" : "🌙";
        btn.title = mode === "dark" ? "切换到浅色" : "切换到深色";
    }
}

function current(): Mode {
    return document.documentElement.classList.contains("dark") ? "dark" : "light";
}

export function initTheme(): void {
    apply(stored() ?? systemPrefers());
}

export function bindThemeButton(): void {
    const btn = document.getElementById(BTN);
    if (!btn) {
        return;
    }
    btn.addEventListener("click", () => {
        const next: Mode = current() === "dark" ? "light" : "dark";
        apply(next);
        save(next);
    });
}
