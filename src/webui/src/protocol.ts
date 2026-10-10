// 和 shell 脚本之间的约定：脚本输出里既有人看的日志，也有 k=v 结果行。
// 只认单行、小写 key 的 k=v；多行内容（更新日志）用重复的 note= 逐行给出。

export type Entries = Map<string, string[]>;

export function parseKV(text: string): Entries {
    const map: Entries = new Map();
    for (const line of text.split("\n")) {
        const m = /^([a-z_][a-z0-9_]*)=(.*)$/.exec(line);
        if (!m) {
            continue;
        }
        const list = map.get(m[1]) ?? [];
        list.push(m[2]);
        map.set(m[1], list);
    }
    return map;
}

export function first(map: Entries, key: string, fallback = ""): string {
    return map.get(key)?.[0] ?? fallback;
}
