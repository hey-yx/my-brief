# <任务标题（含目标数字，如「镜像瘦身 830MB → 目标 <700MB」）>

## 目标
一句话：把什么从 X 变成 Y，验收基线是什么。

## 背景（实测数据）
- 现状数字：怎么测的、何时测的（worker 卡评里的实测值照抄，不写约数）
- 环境约束：磁盘、网络、部署形态等会影响做法的事实
- 相关卡引用：前序卡的实测评论（如「见 t_xxx 卡评」）

## 任务
1. 先测量/拆解现状，再动手
2. 逐项改，每步记录前后数字
3. 失败项回滚并记录原因，不硬磕

## 验收
- [ ] 功能验证：含真实链路/真实数据，不止单测
- [ ] 本仓库验证命令全绿（如 `bun test` + `tsc --noEmit`）
- [ ] 前后实测数字写进卡片评论与 README
- [ ] 目标达不到时如实写清每个砍不动项的原因

## 约定
- 同目录卡：**一律不动 git**（不 commit / 不 checkout / 不推分支），完成时报改动文件清单，提交推送由主会话统一做
- **收尾自合并**（仅 worktree 卡、且建卡时确认本仓库没有别的卡在跑）：自验全绿后按序做。worktree 里不能 `checkout main`（报 "already checked out"），所有 git 一律带主检出路径跑：先 `ROOT=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")`，然后 `git -C "$ROOT" checkout main && git -C "$ROOT" pull --ff-only` → `git -C "$ROOT" merge --no-ff --no-commit <任务分支>` → 仓库验证命令全绿才 `git -C "$ROOT" commit` + `git -C "$ROOT" push origin main` → 删自己分支：先在 worktree 里 `git checkout --detach`（分支被自己 worktree 占着时 `branch -d` 会拒），再 `git -C "$ROOT" branch -D <分支>` 和 `git push origin --delete <分支>`。任何一步不顺（冲突 / 验证不绿 / main 拉不动）就 `git -C "$ROOT" merge --abort`，**不动 main**，只推任务分支到 origin，完成报告写明「留待主会话集成」。**历史异常即停**：合并前先 `BASE=$(git -C "$ROOT" merge-base main <任务分支>)`，`BASE` 为空（无共同祖先，说明 main 被重写过或分支基于旧历史）不许合并，直接走降级路径；`merge --no-ff --no-commit` 报冲突同样即停，不许手动解冲突硬合
- 改动范围：只列允许改的文件；明确不许动的部分
- 不实际部署、不重启线上服务
- ⚠️ 已知坑写在这里（例如：不要跑 `bun run format`，配置与仓库风格不符会全仓重排）
