# My Brief

我平时用的 AI Agent 提示词、偏好和 skill。规则都是实际踩坑之后补上的，换机器时把这里的东西复制过去，行为能对得上。

## 里面有什么

| 路径 | 内容 |
|---|---|
| `prompts/SOUL.md` | 全局规则：边界、回复格式、事实来源、工具习惯 |
| `prompts/USER.md` | 个人偏好：做事方式、输出约定、验收习惯 |
| `skills/` | 常用 skill：回复、文案、证据分级、交付纪律 |
| `BROWSER.md` | 浏览器自动化：挑浏览器、驱动页面、登录、反爬、Camoufox |

## 怎么用

1. `prompts/SOUL.md` 放到 `~/.hermes/SOUL.md`
2. `prompts/USER.md` 放到 `~/.hermes/memories/USER.md`
3. `skills/<name>/` 复制到 skills 目录
4. 浏览器规则按 `BROWSER.md` 配

多 profile 时，每个 profile 的 `memories` 目录各放一份。换机器时把方括号占位符改成本机对应的值。

## 脱敏

凭据路径、服务器域名、公司名和内部服务名做了打码，路径改成 `~`；密码和密钥不在仓库里。

## 说明

两份提示词分成规则和偏好两层，是为了换机器时能分别放到 Hermes 的位置，不用再拆一次。改规则动 `SOUL.md`，改喜好动 `USER.md`。
