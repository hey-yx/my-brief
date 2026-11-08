---
name: kanban-orchestration
description: Use when creating kanban cards or coordinating workers.
version: 1.3.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [kanban, delegation, multi-worker, orchestration]
    related_skills: [sdlc-review]
---

# Kanban 多卡编排

仅用于用户明确交办的看板任务，不为求全面而新增任务或清理项。提交、推送、合并和删除操作只按本次明确授权执行，下面的流程不构成默认授权。

## When to Use

- 大任务拆成多张看板卡派给 coder / researcher / reviewer
- 多张卡在同一项目并行、需要协调工作区
- 卡片建错了、建重了要清理

## 流程

### 1. 建卡前：先定项目上下文

- 先 `desktop_project` 建/切项目，再 `kanban_create`。每张卡**显式传** `project` + `workspace_kind` + `workspace_path`。工作区形态按卡间文件重叠度选：改动面相交的卡（同改 types/hosts/app 这类接线文件）用 `worktree`：各自分支零污染，主会话按依赖序合并、解并集冲突；真正互不相交的卡才用 `dir` 共享目录。用户主动要求 worktree 时照办（不要按旧印象推 Directory）。
- 大规模并行（≥5 卡）时给每卡设 `max_runtime_seconds`（调研 3600 / 实现 5400-7200），防单卡失控占住并发槽。
- 不带 `workspace_path` 会退化成「别的项目下的 worktree」，worker 直接在错误的仓库里干活。
- 卡体照 `templates/task-card.md` 骨架写：目标 / 背景（实测数据）/ 任务 / 验收 checkbox / 约定；卡体里的实测数字就是 worker 的验收基线。单张特性卡带不确定前提时（新签名算法、未核验的第三方接口），把「预研先行、产出入卡评、任一硬卡点即停不硬磕」写进任务序：预研不过就不进实现，避免 worker 交付半成品。
- 派卡前先 `git status` 清场：同仓库常有别的会话留下的未提交改动：先跑测试验证是绿的，再提交并推送保护住，然后才派卡。并行 worker 的 diff 会和遗留未提交改动混在一起无法归属；遗留文件若撞上某张卡的文件清单（如 README），worker 只能绕开或覆盖别人的活。main 脏着派卡而 worktree 已建时：新提交照常落在主仓 main（worktree 各自检出到独立分支互不影响），已派发的卡下次重跑时自动 rebase 到新 main，无需撤卡。

### 2. 建卡后：立即 `kanban_list` 核对再汇报

- 逐张核对 `workspace_path` 和 `project_id` 符合预期，才能向用户汇报完成。
- 核对时不带 status 过滤：调度器几秒内就派发，`status=ready` 可能已查不到刚建的卡。
- **看板按项目独立建（用户偏好「同名 kanban」）**：用户说「在对应 Kanban 里建任务」= `hermes kanban boards create <项目名>` 建与项目同名的板，之后所有 `kanban_*` 工具都带 `board=<项目名>` 指向它（不带则落默认板）；`project` 参数只是卡片标签 + 工作目录。汇报卡位置时说清板名。板 slug 只收小写 ASCII（中文直接被拒，报 invalid board slug）：用项目英文 slug 建板（如 allparse），卡标题仍可用中文。

### 3. 并行 worker 共享工作区的协调令

同一 `workspace_path` 的多张卡会并行跑 worker，同一 git 工作区互相污染。派发后立刻在每张 running 卡留协调令：

- 只改自己卡片范围内的文件；
- **一律不动 git**（不 commit / 不 checkout / 不切分支）；
- 动手前用 `search_files(target='files')` 确认目标路径没被别的卡新建；
- 完成时只报改动文件清单，提交推送由主会话统一做。
- 两张卡都想碰同一高频文件（README、package.json 这类）时，不拆权限：整卡独占给一张，另一张只把建议条目写进完成报告，由独占卡或主会话落地。
- 用户中途追加质量标准（尤其视觉/设计类）时，立刻把标准原文 `kanban_comment` 到卡上：worker 不是本会话 subagent，只有卡评能触达。追加消息若含未回答的问题，把答案也写进评论或卡体：running 中的卡不会自动收下会话里后续说的决策，卡体是 worker 的唯一完整上下文。设计类交付在卡体里就写死「交付前程序化像素检测 + vision 自检 + 预览图贴卡评」三件套：**vision 是语义看图，会漏报文字重叠/相切**（实测过 2px 碰撞被 vision 三次判「无重叠」），固定画布类交付必须跑 PIL 带间距检测（hallmark skill 的 `scripts/pixel-gap-check.py`），把阈值写进卡体、worker 交付前自己跑并把数字贴卡评；像素指标全绿不等于用户认可，最终验收以主会话亲眼看图为准。

替代方案：用 `kanban_link` 父子依赖串行化。注意 worker 不是本会话的 subagent，无法用 steer 控制，只能靠卡片评论沟通。

### 4. 建错卡当场清理，别拖

调度器几秒内就会派发误建卡，只留「作废」评论挡不住派发。立即四步：

1. `kanban_comment` 标作废（说明正确版本在哪）；
2. `kanban_block(kind=capability)` 阻断派发；
3. 确认零产出后 `kanban_complete`（summary 写明「作废归档 · 零产出」）；
4. 误建卡若已在错误仓库建了 worktree/分支：核对与主干零提交差异后 `git worktree remove` + `git branch -D` 清掉。

### 5. 收尾集成（主会话职责）

- 跨时段等卡完成时用 `scripts/monitor-completion.sh <board> <card...>`：轮询 kanban.db 的 status + `git merge-base --is-ancestor` 验合并，双条件才算完。后台监听进程扛不住机器休眠（会被杀），醒来后手动重跑同一探测接着走，不必重建监听。

- 用户要求「自己去跑通」＝关键路径与最终真机验证由主会话亲手做：子代理/worker 的产出是素材不是交付，「测试绿了」不等于「跑通了」，主会话自己端到端执行一遍（真机冒烟、接口实测）再汇报。核心实现类的活也优先主会话亲手做，子代理留给可独立交付的并行件（调研、补测试、写文档）。
- 收尾路径分两条：**独立 worktree 卡走 worker 自合并**（规则写进卡体约定，命令序列已实测：合并/推 main/删分支全程 `git -C <主检出>`：worktree 内 `checkout main` 报 already checked out；删分支前先 worktree 内 `git checkout --detach` 否则 branch -d 被拒；`merge --no-ff --no-commit` → 验证绿才 commit + push main；冲突/不绿则 `merge --abort`、不动 main，只推任务分支留主会话集成；**历史异常即停**：合并前 `git merge-base main <分支>` 为空（无共同祖先，main 被重写过）或 merge 报冲突，都直接降级留主会话，不许解冲突硬合）；多卡相交、冲突卡、同目录卡仍由主会话统一 commit + 合并。worker 自合并过的卡主会话抽查 main 上验证命令即可，报「留待主会话集成」的才走完整集成验收；主会话合并多卡时逐卡验证 worker 产物真落了 main（目标文件在主仓存在且内容可追溯），worker 自述「已合并/已复制」不采信：工作树路径与主仓路径一字之差，落错处不亲眼看发现不了。
- 用户或卡片明确授权推送时，worker 才把任务分支推 origin；失败说明原因，不自动扩大推送或合并范围。
- worker 的完成报告是自述，不直接采信：主会话跑全量测试 / 类型检查 / 实链验证后再验收。
- 收尾只处理明确交办的范围，不顺手清理死代码、修其他 bug 或补齐文档。范围外发现只说明，不自动执行；完成当前交办即汇报。
- worker 报告的疑似 bug（约定只报告不修的）先写最小复现实锤：几行脚本跑出错误输出再上报用户，不转述未经复现的结论。
- worker 自述的副作用（「已上传附件」「已推送」）用系统记录核实：附件查任务 attachments 与事件流，git 副作用查仓库实际状态；描述与记录不符时以记录为准，缺的补挂、叙事失实的打回。
- 多卡产出的共享文件冲突在集成时统一解；一个主题一个 commit。
- worker 若写了半成品文件（如平台 adapter 的 parse.ts），在卡上注明文件路径让下一个 worker 接着写，不要推倒重写。
- 集成验收通过后：按主题分段 commit，快进合并进 main 并推送，已合并的特性分支当场删干净（本地 + 远端），不留退役分支。worker 自合并成功后系统会自动删 worktree 与 `wt/` 分支；自定义分支名的要 worker 自己删，主会话收尾 `git branch -a` 核对零残留。

## 陷阱

| 现象 | 规则 |
|---|---|
| 仓库改名/移动后，所有 linked worktree 全废（每个 worktree 里 `git` 报 `not a git repository`，`git worktree list` 标 `prunable`） | worktree 的 `.git` 文件存的是**绝对路径**，仓库一改名就全指向旧址。修：`git worktree repair` **必须显式传每个 worktree 路径**（不带参数它仍按旧路径找，修不了）；报 `unable to locate repository` 的（元数据已没了）只能移开目录再 `git worktree add <path> <branch>`，移开后记得把 `node_modules`/`.next`/`.venv` 等忽略产物搬回去，验完再删备份 |
| 用户在别的项目里找不到卡 | 卡可能落在默认板而非项目同名板；汇报卡位置前先 `kanban_list` 核对板名 |
| 建卡落到了别的项目 worktree | `kanban_create` 不带 workspace 参数就会随机落；每张卡显式传 |
| worker 并发把 git 工作区搞脏 | 同目录卡一律「worker 不动 git」，主会话统一提交 |
| 多个 worker 同时改共享文件（errors.ts 之类） | 卡体里划清「只动自己范围的文件」；主会话集成时跑全量测试统一解冲突 |
| 「作废」评论救不了误建卡 | 评论不阻断派发，必须 `kanban_block` |
| 卡面显示 done 但没干活 | worker 可能看到作废指令提前收工；以 `kanban_show` 的 run summary 和仓库 diff 双重核实 |
| 建卡后 ready 列查不到卡 | 调度器秒级派发已移入 running；核对时不带 status 过滤 |
| worker 一启动就 crash，worker_output 含 `Gateway draining: update_paused` / `Kanban owner refused` / `Gateway disconnected` | 是 gateway 断连连坐，不是任务问题。两种成因：① `hermes update` 排水窗口；② 机器休眠刚醒（worker 被杀后重试撞 draining，crashed×2 自动 blocked）。确认死法：`kanban_show` 看 events（crashed×2 + gave_up + worker_output）；更新成因要确认更新已结束（无 update 进程、hermes-agent checkout 干净、无 hermes-update-pull 残留），休眠成因只需确认 gateway 进程还活着（ps）。然后逐张 `kanban_unblock` 重派，卡体与产出无损，别重建卡 |
| 排水过后 worker 仍秒死，报「a source update is unfinished; run hermes update from a shell」 | 是更新的收尾步骤没跑完（装 pinned 插件/依赖），且可能有孤儿锁（`.git/hermes-update.lock` 内 PID 已死、lsof 无人持有），先删孤儿锁，再在 shell 里跑一次官方 `hermes update` 把收尾走完；删锁只解决锁、不解决收尾，两者都要做。**每次跑 `hermes update` 都会重写锁**，收尾失败的运行会留下新的死 pid 锁，每次 update 跑完后重查一遍锁（读锁内 pid、ps 验死）再重派，别只清一次就以为完了。update 收尾还会报「Gateway restart still owed」：网关进程树内跑 `hermes gateway restart` / `launchctl kickstart` / osascript 包裹全被 preflight 拦（「Blocked: command cannot restart the gateway」），重启只能交给用户在终端自己跑。**网关确认恢复前别 kanban_unblock**：重派撞 draining/execution unknown 同样 crash×2 → gave_up 再度 blocked，白烧重试预算（`effective_limit=2`，烧完只能人工解）。确认标准既不是「PID 换了」，也不是 fleet 报 up to date（实测可同时挂着「owed a restart」警告）；决定性信号是 agent.log 里 `Restart deferred wait complete` 与 `active work drained; proceeding to stop()` 之后出现新的 `kanban dispatcher: embedded in gateway`。完整取证链（板库直读 task_events 取崩溃原文、update receipt 的 `gateway_restart: {}`、`hermes -p <profile> --yolo -z` 区分 profile 故障与网关准入）见 `references/worker-crash-recovery.md` |
| worker 报 `rate-limited (quota wall)` 退出（exit 75） | 模型通道并发限流，不算失败：派发器自动重排不计数，别 kanban_unblock 也别重建，等槽位自愈；限流期间给板子减负比催重试有效 |
| update 发出的 gateway 重启长时间不落地 | 排水在有活跃会话时一直 defer（日志刷「Restart deferred: waiting on N active work unit(s)」），属正常等待；提前强杀会砍掉用户正在聊的会话 |
| 要跑 `hermes update` 时 | 先 `kanban_list` 查 running 卡，排水窗口会拒绝该窗口内 spawn 的全部 worker，每卡 crash×2 后自动 blocked；多会话环境下另一会话可能正在跑 update，派卡后留意首批 crash 是否这个形态 |
| worker 崩溃输出里的报错像旧新闻（锁已删还报 update unfinished / 同一 session id 反复出现） | 按时间线对齐：崩溃事件里的 worker_output 是 worker 启动那一刻的环境快照，不是当前状态，排查时以「崩溃时刻」的锁/网关状态为准，别拿现在已修好的环境去否定报错；反过来，别在锁刚清、网关未确认恢复时就重派（见上条） |
| 卡依赖还没完成就被领走了 | `kanban_link` 对已 running 的卡报错；改为把前置条件写进卡体（含「前置卡未合时怎么办」的降级路径），依赖控制只对未派发的卡建 |
| 脚本用 `sqlite3 "file:…?mode=ro"` 读 kanban.db，报 `unable to open database file (14)`，且时好时坏 | 这些库是 WAL 模式：没有活跃写连接时 `-shm` 不存在，只读方式无法创建它就必然失败，**不是并发竞争，重试多少次都一样**（曾导致每日归档脚本连续 3 天随机漏板）。正确做法：先试 mode=ro，失败退回普通路径打开并带 `-cmd "PRAGMA query_only=1;"` 保住只读语义 |
| terminal 命令被拦，报「cannot restart, stop, or uninstall the gateway」，但命令跟重启无关 | 自我保护钩子按**字面串**匹配：脚本文件里只要写了 `hermes gateway restart` 这几个词，执行这个脚本的命令就被整条拦掉（定时任务跑它同样受影响）。脚本里用 `grep -v -e 'did not restart running gateways'` 这类不含该串的模式过滤，别写全句 |
| 工作区有别人改到一半的文件（另一会话或另一卡的 WIP，测试红但 git status 显示的改动不属于你） | 绝不整树 `git stash` / `checkout` / `reset` 来隔离自己的验证，会瞬间搬空别人的进行中改动；只 `git stash push -- <自己的文件>` 限定路径，或开临时 worktree 做 A/B，测完立刻恢复 |
| 多张卡都用 `dir` 共享目录时，主仓测试突然红了几条 | 先查是不是另一张卡正在跑（`kanban_list status=running` 并看它改的文件），dir 卡并行会同时改同一批文件，中途态测试红是正常现象，**此时别急着修**：插手会和 worker 抢同一批文件、把冲突放大。判据：红的文件是否属于 running 卡的清单；是就等它跑完再验，不是才是真回归 |
| dir 卡文件清单相交（如都改 prompts.ts / audit.ts） | 即使用户偏好 Directory，相交的卡也不能并行：用 `kanban_link` 建父子串成依赖链串行化，或退 `worktree` 各自分支。派卡前先比一遍各卡文件清单，「都用 dir」不等于「不相交」 |
| 卡间文件清单互不相交 | 可省 worktree 与统一提交：卡体写死本卡文件清单 + 派卡前 git status 清场，worker 各自在主检出直接提交自己范围（实测三卡并行零冲突，提交时间线交错但互不踩）；主会话逐卡以 git log + 审计脚本核对落库，不采信 worker 自述 |
| worker 交的统计类报告（样本量、百分比、分布） | 回查它落盘的原始数据：核对条数与一两个关键比率能否从 raw 文件复算（如「连字符率 60%」要在 raw 上跑一遍）。原始数据结构常是 `{source,count,packages}` 而非裸数组，直接 `len(json)` 会拿到键数（3）而误判「样本造假」，先打印结构再算 |
| 陈旧重试通知（「已完成 + dispatcher 将重试」） | 通知队列滞后会重发已 done 卡的通知。以 `kanban_show` 的 status / current_run_id 为准：status=done 且 current_run_id=null 就是没在排队，不需要任何动作，别重复建卡 |
| 后台进程「listening」通知在进程已 kill 后仍到达 | 同样是延迟投递；用 `lsof -nP -iTCP:<端口> -sTCP:LISTEN` + `pgrep -lf` 实测端口与进程，空则无残留，不用处理 |
| `delegate_task` 长中文任务描述报 JSON 解析错（Expecting ',' delimiter） | 任务参数的 JSON 解析器扛不住长中文+嵌套引号（与 deferred tool_call 同病）：把完整说明写进 scratch 文件，goal/context 只留短 ASCII 引用文件路径，output_schema 也先省掉；cron 长指令同理（指令写文件、prompt 只留英文短引用）；子代理开工先读说明书 |
| `execute_code` in a headless/kanban worker session is hard-rejected by the approval policy (`approvals.single_query_mode`) | Workers run scripts through `terminal`, never `execute_code` |
| leaf 子代理开工先计划拆孙代理、或把产出攒到最后一次性验证 | 派发指令写死「NEVER spawn subagents」+「每 2-3 个文件跑一次验证」；不加约束的 leaf 会把时间烧在拆解上（实测 12 分钟零产出被中断），渐进验证才能在中断时保住已完成产出 |
