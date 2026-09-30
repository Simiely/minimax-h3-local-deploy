# CHANGELOG

本项目遵循「按版本分节、不拆分」的记录方式（见 `AGENTS.md`）。

## v0.2.0 · 2026-09-30

**首次实跑：路线 B 在 4070 Ti SUPER 16G 上跑通，并用实测数据校准了社区口径**

- 新增 `docs/实测-路线B-4070TiSuper16G.md`：单机实测记录 —— 864×480 / 124 帧 / 20 步 = **3 分 13 秒/条**，
  显存峰值 15.2/16 GiB、系统内存峰值 22.7 GiB；产物 h264 + aac 双声道（音画一次推理同出）
- **校准一条过时口径**：社区流传「编码器 + transformer 同时驻留系统内存约 45.6 GiB（32 GB 内存会出事）」，
  在 ComfyUI 0.37 上实测峰值只有 **22.7 GiB** —— 新版的动态显存加载 / 分段暂存 + `--disable-pinned-memory`
  已改变这个结论，**「32 GB 内存是下限」的判断偏保守**
- 实证 NVFP4 在 Ada（30/40 系）上确为 **emulated ops**（启动日志明示），印证主文档的选型判断
- 新增**无头（Headless）运行要点**：官方模板是 Subgraph 格式、`/prompt` 只吃 API 格式 ⇒
  必须手工展开；逐条列出展开时的 7 个关键点（`MiniMaxH3ImageToVideo` 不接关键帧即纯 t2va、
  `SamplerCustomAdvanced` slot 0 同喂两个 VAE 解码、turbo LoRA 分支默认关、17k+5 帧网格、
  视频 VAE 的 int8_convrot / fp16 可互换等）
- `README.md` 加实测速览与文档索引

## v0.1.0 · 2026-09-28

**首次整理：MiniMax H3 本地部署资料（12 GB / 16 GB 消费级 N 卡）**

- 新增 `README.md`：三条硬结论（768p 上限 / 许可地域 / 主机瓶颈）、两张卡选型表、快速开始四步、文档索引
- 新增 `docs/使用指南.md`：三条量化路线（A · GGUF Q4 / B · 剪枝 INT8 + NVFP4 编码器 / C · INT4 或 mixed）对比与决策树、
  硬门槛清单、下载清单、安装顺序（torch cu130 最后装）、最小验证 8 步、参数手册、加速件优先级、排错速查、何时改用 API
- 新增 `DEVELOPMENT.md`：关键问题与方案 8 条（pinned memory 致死 / cu128 静默降级 / 12G 卡主机瓶颈 /
  NVFP4 用在哪 / GGUF 加载器与类型识别 / GGUF 后缀不可信 / 缺 VAE / 2K 与许可）
- 新增 `docs/参考/`：两篇教程视频的要点对照、风险说明与口播逐字稿（AI-PanSir 选型视频、零度解说无审查编码器视频）
- 新增 `AGENTS.md`（含文档基线行）与本文件
