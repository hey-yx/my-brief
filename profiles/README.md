# Profile 分工

四个 worker profile，各管一段：

| profile | 职责 |
|---|---|
| `coder` | 把开发任务变成能跑、验证过、贴合现有代码的改动 |
| `promptsmith` | 把粗糙需求重写成结构化、可直接用的提示词 |
| `researcher` | 做有来源、可核查的调研，交付能支撑决策的结论 |
| `reviewer` | 找出本次改动引入的真问题，给带位置的审查结论 |

四份 SOUL 共享同一套硬约束，区别在职责、工作流程和输出格式。分开建 profile 是为了让每个角色只做自己的事，写代码的不会顺手审查，做调研的不会顺手改代码。

## 怎么用

在 Hermes 里建同名 profile，把 `<name>/SOUL.md` 放到 `~/.hermes/profiles/<name>/SOUL.md`。模型、工具和记忆按各自的 profile 配，不共用。

这里只放 SOUL。profile 的 `memories`、`config.yaml`、`.env`、`auth.json` 没有上传，里面有本机环境和凭据。
