import antfu, { parserPlain } from "@antfu/eslint-config";

export default antfu({
    formatters: {
        css: "prettier",
        markdown: "prettier",
        prettierOptions: {
            plugins: ["prettier-plugin-css-order"],
        },
    },

    stylistic: {
        /*
         * 基础风格：
         *
         * - 4 空格
         * - 双引号
         * - 保留分号
         * - else/catch 独立换行
         */
        indent: 4,
        quotes: "double",
        semi: true,
        braceStyle: "stroustrup",

        overrides: {
            /* ---------- 引号 / 分号 / 括号 ---------- */

            "style/quote-props": ["warn", "as-needed"],
            "style/jsx-quotes": ["warn", "prefer-double"],
            "style/template-curly-spacing": ["warn", "never"],

            "style/object-curly-spacing": ["warn", "always"],
            "style/array-bracket-spacing": ["warn", "never"],
            "style/computed-property-spacing": ["warn", "never"],

            /* ---------- 逗号 ---------- */

            "style/comma-spacing": ["warn", {
                before: false,
                after: true,
            }],

            "style/comma-dangle": ["warn", {
                arrays: "always-multiline",
                objects: "always-multiline",
                imports: "always-multiline",
                exports: "always-multiline",
                functions: "always-multiline",
                generics: "always-multiline",
                tuples: "always-multiline",
                enums: "always-multiline",
            }],

            /* ---------- 分号相关 ---------- */

            "style/member-delimiter-style": ["warn", {
                multiline: {
                    delimiter: "semi",
                    requireLast: true,
                },
                singleline: {
                    delimiter: "semi",
                    requireLast: false,
                },
                multilineDetection: "brackets",
            }],

            /* ---------- 换行 ---------- */

            "style/function-paren-newline": ["warn", "consistent"],
            "style/object-curly-newline": ["warn", {
                ObjectExpression: {
                    multiline: true,
                    consistent: true,
                },
                ObjectPattern: {
                    multiline: true,
                    consistent: true,
                },
                ImportDeclaration: {
                    multiline: true,
                    consistent: true,
                },
                ExportDeclaration: {
                    multiline: true,
                    consistent: true,
                },
            }],
            "style/object-property-newline": ["warn", {
                allowAllPropertiesOnSameLine: true,
            }],
            "style/array-bracket-newline": ["warn", "consistent"],
            "style/array-element-newline": ["warn", "consistent"],
            "style/implicit-arrow-linebreak": ["warn", "beside"],
            "style/nonblock-statement-body-position": ["warn", "below"],
            "style/operator-linebreak": ["warn", "before", {
                overrides: {
                    "=": "after",
                },
            }],
            "style/multiline-ternary": ["warn", "always-multiline"],

            /* ---------- 点位置 / 箭头 ---------- */

            "style/dot-location": ["warn", "property"],
            "style/arrow-parens": ["warn", "as-needed"],
            "style/space-before-function-paren": ["warn", {
                anonymous: "never",
                named: "never",
                asyncArrow: "always",
            }],

            /* ---------- 空行 / 尾随空格 ---------- */

            "style/no-multiple-empty-lines": ["warn", {
                max: 1,
                maxBOF: 0,
                maxEOF: 0,
            }],
            "style/no-trailing-spaces": "warn",
            "style/eol-last": ["warn", "always"],

            /* ---------- 冗余 / 混用 ---------- */

            // "style/no-mixed-operators": "warn",
            "style/no-extra-parens": "warn",
        },
    },

    typescript: {
        tsconfigPath: "tsconfig.json",
        overrides: {
            /* ---------- 类型定义 ---------- */

            "ts/consistent-type-definitions": ["warn", "interface"],
            "ts/consistent-type-imports": ["warn", {
                prefer: "type-imports",
                fixStyle: "separate-type-imports",
                disallowTypeAnnotations: false,
            }],
            "ts/consistent-type-assertions": ["warn", {
                assertionStyle: "as",
            }],

            /* ---------- 类型排序 ---------- */

            "perfectionist/sort-interfaces": "off",
            "perfectionist/sort-object-types": "off",
            "perfectionist/sort-union-types": "off",
            "perfectionist/sort-intersection-types": "off",
            "perfectionist/sort-classes": "off",
            "perfectionist/sort-objects": "off",
            "perfectionist/sort-enums": ["warn", {
                type: "alphabetical",
            }],

            /* ---------- 命名约定 ---------- */

            "ts/naming-convention": ["warn", {
                selector: "default",
                format: ["camelCase", "PascalCase"],
                leadingUnderscore: "allow",
            }, {
                selector: "property",
                format: null,
            }, {
                selector: "method",
                format: null,
            }, {
                selector: "variable",
                format: ["camelCase", "PascalCase", "UPPER_CASE"],
                leadingUnderscore: "allow",
            }, {
                selector: "function",
                format: ["camelCase", "PascalCase"],
            }, {
                selector: "typeLike",
                format: ["PascalCase"],
            }, {
                selector: "typeParameter",
                format: ["PascalCase"],
            }, {
                selector: "enumMember",
                format: ["camelCase", "PascalCase"],
            }],

            /* ---------- Promise / Async ---------- */

            "ts/no-redeclare": "warn",
        },

        /*
         * 类型感知规则必须写在这里。写在 overrides 里时，
         * 它们会落到没有 ignores 保护的规则块上，
         * markdown 代码块（虚拟 .ts 文件）没有类型信息，直接崩溃。
         */
        overridesTypeAware: {
            "ts/no-unnecessary-type-assertion": "warn",
            "ts/non-nullable-type-assertion-style": "warn",
            "ts/no-floating-promises": "warn",
            "ts/no-misused-promises": "warn",
            "ts/promise-function-async": "off",
            "ts/switch-exhaustiveness-check": "off",
        },
    },

    jsonc: {
        overrides: {
            "jsonc/indent": ["warn", 4],
            "jsonc/quotes": ["warn", "double"],
            "jsonc/comma-style": ["warn", "last"],
            "jsonc/no-comments": "warn",
            "jsonc/sort-keys": "warn",
        },
    },

    yaml: {
        overrides: {
            "yaml/indent": ["warn", 2],
            "yaml/quotes": ["warn", { prefer: "double" }],
        },
    },

    toml: {
        overrides: {
            "toml/indent": ["warn", 2],
            "toml/quoted-keys": ["warn", { prefer: "as-needed" }],
        },
    },

    test: true,

    jsdoc: true,

    imports: {
        overrides: {
            "import/no-duplicates": "off",
            "import/consistent-type-specifier-style": "off",
            "import/newline-after-import": "warn",
            "import/first": "warn",
            "perfectionist/sort-imports": "warn",
            "perfectionist/sort-named-exports": "warn",
        },
    },
}, {
    files: ["**/*.{js,jsx,ts,tsx,cjs,mjs,cts,mts,vue}"],

    rules: {
        /* ---------- antfu 自定义规则 ---------- */

        /*
         * 与 object-property-newline 冲突，关闭以保证稳定。
         */
        "antfu/consistent-list-newline": "off",

        /*
         * 链式调用换行一致性。
         */
        "antfu/consistent-chaining": "warn",

        /*
         * if 后必须换行。
         */
        "antfu/if-newline": "warn",

        /*
         * 顶层函数优先 function 声明。
         */
        "antfu/top-level-function": "warn",

        /* ---------- 函数 / 对象 ---------- */

        "prefer-arrow-callback": "warn",
        "arrow-body-style": ["warn", "as-needed"],
        "object-shorthand": "warn",
        "func-style": "off",

        /* ---------- 变量声明 ---------- */

        "one-var": ["warn", "never"],
        "one-var-declaration-per-line": ["warn", "always"],
        "prefer-const": "warn",
        "no-var": "warn",

        /* ---------- 命名 ---------- */

        camelcase: "warn",
        "new-cap": "warn",
        "no-underscore-dangle": "off",
        "no-shadow": "warn",

        /* ---------- 无用 / 重复 ---------- */

        "no-unused-vars": ["warn", {
            varsIgnorePattern: "^_",
            argsIgnorePattern: "^_",
            caughtErrorsIgnorePattern: "^_",
        }],
        "unused-imports/no-unused-imports": "warn",
        "no-redeclare": "warn",
        "no-dupe-args": "warn",
        "no-dupe-class-members": "warn",
        "no-dupe-else-if": "warn",
        "no-dupe-keys": "warn",
        "no-duplicate-case": "warn",
        "no-duplicate-imports": ["warn", { allowSeparateTypeImports: true }],

        /* ---------- 三元 / 布尔 ---------- */

        "no-nested-ternary": "warn",

        /* ---------- Catch ---------- */

        "unicorn/prefer-optional-catch-binding": "warn",

        /* ---------- String ---------- */

        "prefer-template": "warn",
        "unicorn/prefer-string-raw": "warn",
        "unicorn/prefer-string-replace-all": "warn",
        "unicorn/prefer-string-slice": "warn",

        /* ---------- Array ---------- */

        "unicorn/prefer-includes": "warn",
        "unicorn/no-array-reduce": "warn",
        "unicorn/no-array-push-push": "warn",
        "unicorn/no-array-reverse": "warn",
        "unicorn/prefer-array-find": "warn",
        "unicorn/prefer-array-flat": "warn",
        "unicorn/prefer-array-flat-map": "warn",
        "unicorn/prefer-array-index-of": "warn",
        "unicorn/prefer-array-some": "warn",
        "unicorn/prefer-set-has": "warn",

        /* ---------- Loop ---------- */

        "unicorn/no-for-loop": "warn",

        /* ---------- Promise / Async ---------- */

        "no-async-promise-executor": "warn",
        "no-promise-executor-return": "warn",
        "prefer-promise-reject-errors": "warn",
        "require-await": "warn",
        "unicorn/no-unnecessary-await": "warn",

        /* ---------- Error ---------- */

        "no-throw-literal": "warn",
        "unicorn/throw-new-error": "warn",

        /* ---------- RegExp ---------- */

        "regexp/no-useless-flag": "warn",
        "regexp/no-useless-quantifier": "warn",
        "regexp/prefer-character-class": "warn",
        "regexp/prefer-d": "warn",
        "regexp/prefer-plus-quantifier": "warn",
        "regexp/prefer-question-quantifier": "warn",
        "regexp/prefer-regexp-exec": "warn",
        "regexp/prefer-regexp-test": "warn",
        "regexp/prefer-w": "warn",
        "regexp/require-unicode-regexp": "off",

        /* ---------- Unicode ---------- */

        "no-irregular-whitespace": "warn",
        "no-misleading-character-class": "warn",
        "no-control-regex": "warn",

        /* ---------- Comments ---------- */

        "eslint-comments/disable-enable-pair": "warn",
        "eslint-comments/no-unlimited-disable": "warn",
        "eslint-comments/no-unused-disable": "warn",
        "no-warning-comments": "warn",

        /* ---------- Unicorn 其余 ---------- */

        "unicorn/consistent-destructuring": "warn",
        "unicorn/consistent-function-scoping": "warn",
        "unicorn/explicit-length-check": "warn",
        "unicorn/no-lonely-if": "warn",
        "unicorn/no-useless-undefined": "warn",
        "unicorn/no-negated-condition": "warn",
        "unicorn/prefer-default-parameters": "warn",
        "unicorn/prefer-logical-operator-over-ternary": "warn",
        "unicorn/prefer-number-properties": "warn",
        "unicorn/prefer-structured-clone": "warn",
    },
}, {
    files: ["**/*.sh"],
    languageOptions: {
        parser: parserPlain,
    },
    rules: {
        "format/prettier": ["warn", {
            parser: "sh",
            plugins: ["prettier-plugin-sh"],
            tabWidth: 4,
        }],
    },
}, {
    /*
     * .d.ts 里每个 declare module 块都需要各自 import 一次，属误报。
     */
    files: ["**/*.d.ts"],
    rules: {
        "no-duplicate-imports": "off",
    },
}, {
    /*
     * VS Code 的设置项有自己的分组惯例，不对它强制字母序。
     */
    ignores: [".vscode/**"],
});
