# Worker 秒崩 / 网关排水：取证与恢复

触发：卡自动 blocked，事件里 `crashed`×2 + `gave_up`，worker_output 含 `Kanban owner refused`、`runtime_draining`、`execution unknown` 或 `a source update is unfinished`。这类失败不是任务问题，卡体与产出无损，别重建卡。

## 1. 取崩溃原文：直读板库

`kanban_show` 对内容多的卡会返回数万字符，进上下文常被压缩掉，细节读不到。直接查板库更稳：

```bash
DB=~/.hermes/kanban/boards/<board-slug>/kanban.db
sqlite3 $DB "SELECT status, current_run_id FROM tasks WHERE id='<task>'"
sqlite3 $DB "SELECT kind, datetime(created_at,'unixepoch','localtime'), substr(payload,1,400) FROM task_events WHERE task_id='<task>' ORDER BY rowid DESC LIMIT 5"
```

- `kind` 序列 `claimed → spawned → crashed → gave_up` 就是被判失败的形状；payload 里 `worker_output` 是 worker 退出前最后几行，`failures` / `effective_limit` 说明重试预算（默认 2，烧完要人工解）。
- `created_at` 是 unix 秒，配 `datetime(...,'unixepoch','localtime')` 直接出本地时间，用来和日志对齐。

## 2. 按崩溃时刻对齐环境

worker_output 是 worker 启动那一刻的环境快照。别拿「现在锁已经清了」去否定报错；反过来，锁刚清、网关没确认恢复时也别急着重派。

## 3. 三种成因

| 现象 | 成因 | 动作 |
|---|---|---|
| 日志刷 `Restart deferred: waiting on N active work unit(s)` | update 排水在等活跃会话 | 正常等待；强杀会砍掉用户正在聊的会话 |
| worker 在别处跑 update 的窗口内 spawn | update 排水窗口 | 等 update 结束再 unblock |
| 休眠刚醒后 crash | 机器合盖杀后台进程 | pgrep 验 gateway 活着，直接 unblock 重派 |

## 4. `a source update is unfinished`：孤儿锁 + 收尾

```bash
LOCK=~/.hermes/hermes-agent/.git/hermes-update.lock
PID=$(head -1 $LOCK)
ps -p $PID >/dev/null && echo ALIVE || echo DEAD   # pid 死
lsof $LOCK | tail -n +2 | wc -l                    # 0 = 无持有者
```

pid 死 + 无持有者 = 孤儿锁，删掉；然后在 shell 跑 `hermes update` 走收尾。**每次 update 都重写锁**，跑完重查一遍再重派，别只清一次就以为完了。

update 自身 success 不代表结束：receipt 在 `~/.hermes/logs/update_receipts/latest.json`（各 profile 在 `~/.hermes/profiles/<p>/logs/update_receipts/latest.json`），`outcome: success` 但 `gateway_restart` 是空对象 `{}` = 重启跟进没落地。

## 5. 网关重启只能交给用户

会话内 `hermes gateway restart`、`launchctl kickstart`、osascript 包裹全被 preflight 拦（防自杀）。让用户在终端自己跑，跑完别信口头「好了」，按 §6 验。

## 6. 判「真的恢复」：日志 + 探针，不信 PID

- `~/.hermes/logs/agent.log`：`gateway.session_authority: Session ... paused: runtime_draining` = 还在排水；`gateway.run: Restart deferred wait complete — active work drained; proceeding to stop()` 之后出现新的 `kanban dispatcher: embedded in gateway (interval=...)` = 新实例接管。这条链走完才可重派。
- PID 变了不等于换了代码；fleet 版本检查（`hermes update` 尾部）报 up to date 也可能同时挂着「owed a restart」警告，两个都只是辅助信号。
- 区分「profile 坏了」和「网关准入拒了」：`hermes -p <profile> --yolo -z "reply with the single word OK"` 能正常回 OK 就说明 checkout/profile 没问题，问题在网关 admission 层（排水），别去查依赖或删会话。该探针会真实起一次 agent 会话花 token，只跑一次。

## 7. 重派

§6 全部通过后 `kanban_unblock` 一次即可；重试预算只有 2 次，排水期间每重派一次烧一次，卡会再 blocked 且需人工再解。
