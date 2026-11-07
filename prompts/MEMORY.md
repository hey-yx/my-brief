FlClash（2026-11-07 从 Clash Verge 迁入，桌面代理唯一客户端）TUN utun4 + 系统代理 7897 双层；FlClashCore 已 setuid root，TUN 免密；Verge 保留安装但自启已停。双层 wrap 截断大传输（curl 18），再现先拆一层。
§
全局 skills 在 ~/.agents/skills（skills.external_dirs 只读挂载）；Hermes 自建技能写 ~/.hermes/skills，同名本地优先。
§
Next.js dev 与 build 共用产物目录会让 dev 500（Cannot find module './xxx.js'）：NameYouLike 已用 next.config.ts 的 distDir 分离（dev→.next-dev，build→.next）。
§
UISpecs（原 speccite→Readspec→UISpecs，2026-11-07 定名；目录 ~/workspace/active/UISpecs、仓库 hey-yx/ui-specs、包名 ui-specs）站点在 site/ 走 Astro dev 4321；8000 常被占，或旧进程 cwd 已删→全 404，先 curl 探活再换端口。
§
多聊天会话并行、状态会打架：关键状态（cron/服务/看板）动手前重读并记快照时点，汇报注明。
§
[本地网关] 127.0.0.1:3425；4 worker 已对齐 default 模型段；[代理服务](8788) 无并发限制。
§
双域名 [域名 A]+[域名 B] 证书/续期/1Panel 陷阱全在 [服务器手册路径]；动手前先读同目录 ai-runbook.md。
§
记忆约定：只留必知事实，细节指针化到 docs/skill/servers。改 SOUL.md 或 memories 后必须同步 4 个 worker profile，跑 align_profiles.py --sync 并 re-audit。
§
Hermes 桌面打包构建无 CDP，本地构建/换包见 hermes-agent skill（macos-desktop-updates）；插件半包开关在 设置→插件；后端就绪看 desktop.log 的 HERMES_BACKEND_READY；gateway 独立进程（ppid=1）。
§
域名判定勿信本机 DNS（Clash TUN 劫无解析域名到假 IP）；一律 RDAP/whois。NameYouLike（原 namerubric，目录驼峰，域名/包名/localStorage 键小写）不直调大模型 API，采集与规则计算走本地脚本；凭据在 [凭据文件]。
§
断言生效时机前对照部署形态（容器 env 启动定死/热加载/需重启），有前提写前提。
§
Docker Desktop 容器访问宿主代理走 host.docker.internal（192.168.65.254），到 Clash 7897 的 CONNECT 返回 200；容器内 127.0.0.1 指容器自身。
§
安全占位符只在显示层脱敏，工具入参阶段会还原真值。看着像占位符时别断言「拿不到」或盘上被污染（也会盖住非凭据字符串如 URL slug），用等值比较探真实字节再下结论。
§
skills.auto_load 常驻 3 个：intent-to-ship、concise-responses、chat-output-style（2026-11-03 精简，prompt-optimizer 与 hermes-agent-skill-authoring 改按需加载）；改后只在新会话生效。
§
Hermes cron 与投递坑：no_agent 脚本按后缀选解释器（.sh/.bash→bash，其余→Python），Python 内容写成 .sh 报 import: command not found；微信（iLink）推送需用户先给机器人发过消息；插件 adapter 在网关启动时构建，改 .env 须重启网关；投递成败查 executions.db 的 delivery_outcome。
§
Write 覆盖已有文件常被拒（提示未见完整内容或部分视图）：read_file 命中秘密脱敏即算部分视图；改用 patch，或 rm 后重写。
§
用户已弃用 ZCode（2026-10-30 确认），主用 Hermes；~/.zcode/AGENTS.md 已归档为 .retired，规则唯一来源是 ~/.hermes/SOUL.md。
§
NameYouLike 只做英文命名，改站先问减什么；元素库/系列库已删勿再加回；提示词正文在仓库根 prompt.txt；server/ 服务层是已下线残骸已删勿回；形状钉在 tests/research-stage.test.ts。站点布局/皮肤细节见 creative/page-design-preferences 与 devops/naming skill、项目 research/。
§
默认模型=group/smart-mix。思考强度三层：本地网关的 hermes effort 写入 config 的 agent.reasoning_effort，桌面预设另在 ui-preferences（批量改用 hermes-agent skill 的 scripts/set_presets_effort.py，自动 bump revision）；2026-11-06 三层回落 medium（delegation 仍 low），compression.threshold_tokens 已调 30 万。[代理服务] 全系 43-73 tok/s 同档；仪表盘 tok/s 分子含隐藏思考；[本地网关] 价是美元。
§
审计类任务只做用户点名的项目，不自动扩到 active 下全部项目（2026-11-03 用户纠正）。
§
Hermes 已开 tool_loop_guardrails.hard_stop_enabled=true（2026-11-03，hermes config set 写入）；它只在构造 agent 时烘焙，改配置后需开新会话才生效。
§
默认浏览器是 Safari（2026-11-06 迁移），Hermes 真实登录态浏览器靠 browser.real_profile_browser=chrome 钉住（源码补丁，hermes-agent skill 的 browser 参考有记录）；hermes update 合并后要检查补丁是否还在。
§
GitHub 发布链路坑（2026-11-06 实测）：git clone 大传输在双层代理下 early EOF/SSL 断，改 gh api 逐文件操作；fork 建分支指向上游最新 sha 会 404（fork 对象库缺提交），退回 fork 自己的 main sha（纯祖先则 PR diff 干净）；contents PUT 更新已有文件必须带该文件 blob 的 sha 字段；catalog entry 用 ~/.hermes/hermes-agent/.venv 的 hermes_yaml + entry_from_mapping 校验。