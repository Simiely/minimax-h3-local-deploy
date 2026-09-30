# minimax-h3-local-deploy

> 在**消费级 N 卡**（12 GB / 16 GB 两档）上跑通 MiniMax H3（Hailuo 3.0）视频生成的本地部署资料。
> 结论优先、标出处、可核对。社区每周都在动 —— **动手前以各仓库 README 的当前数值为准**，不要照抄本仓库的历史数字。

---

## 这是什么

- **目标硬件**：RTX 4070 Super（12 GB）/ RTX 4070 Ti Super（16 GB），其余显存档位可类推
- **覆盖范围**：ComfyUI 本地推理路线 —— 选哪条量化路线、下哪些文件、怎么装、怎么配、怎么排错
- **不在范围内**：2K 输出（模块未开源，只能走官方 API）、无审查 / 越狱玩法（仅在 `参考/` 里做技术说明与风险提示）

## 先说三条硬结论

| # | 结论 | 对你的影响 |
|---|---|---|
| 1 | **本地永远只有 768p**（短边 768，上限 1344×768，最小 384p）。`H3-Regenerate-2K` 未开源 | 交付物要 2K 就别搞本地 |
| 2 | **社区许可排除美 / 欧 / 英 / 韩**，条款还覆盖输出物与衍生模型 | 国内自用没问题；别把权重与成品带到这些地区商用 |
| 3 | **瓶颈常在主机不在显卡**：内存不足时权重每一步都从硬盘重读 | 同一张 12G 卡，5 秒草稿能从 6 分钟变 25 分钟 |

## 两张卡怎么选

| | RTX 4070 Super 12G | RTX 4070 Ti Super 16G |
|---|---|---|
| 定位 | 能跑，但属**实验环境**（每步至少 8.7 GiB transformer 走 PCIe） | 本地这一档的**入门生产位** |
| 首推 | 路线 B：剪枝 INT8 + NVFP4 文本编码器 | 画质优先 → 路线 B；速度优先 → 路线 C |
| 备选 | 路线 A：GGUF Q4（省显存，但要装额外加载器） | 同左 |
| 首次参数 | 864×480（0.4 MP）／124 帧（5 秒）／20 步 | 0.4–0.5 MP；配 Turbo 8 步可摸 768p 短边 |
| 预期耗时 | 6–10 分钟/条（32 GB 内存）；16 GB 内存掉到 20–29 分钟 | 2–7 分钟/条 |
| 硬门槛 | 32 GB 内存起 + NVMe 45 GB 空闲 + CUDA 13 | 64 GB 内存更顺 |

| 路线 | 扩散模型 | 文本编码器 | 取向 |
|---|---|---|---|
| **A** GGUF Q4 | 剪枝 Q4_K_M（10.6 GiB） | GGUF Q2_K（7.9 GB） | 最省显存，**要装较新的 ComfyUI-GGUF** |
| **B**（推荐）剪枝 INT8 | `..._pruned_int8_convrot`（19.53 GiB） | NVFP4 AWQ（14.61 GiB） | 免额外节点包、画质最好，靠卸载换显存 |
| **C** INT4 / mixed | 11.3 / 15.5 GB | INT4 convrot（15.0 GB） | 少卸载、更快，画质明显下降 |

决策树与完整对比见 [`docs/使用指南.md`](docs/使用指南.md)。

> **本机实测（2026-09-30）**：4070 Ti SUPER 16G + 64 GB 内存，路线 B，864×480 / 124 帧 / 20 步
> = **3 分 13 秒/条**，显存峰值 15.2/16 GiB，系统内存峰值仅 22.7 GiB（远低于社区流传的 45.6 GiB ——
> ComfyUI 0.37 的动态显存加载已改变这个结论）。详见 [`docs/实测-路线B-4070TiSuper16G.md`](docs/实测-路线B-4070TiSuper16G.md)。

## 快速开始

**1）环境**：ComfyUI ≥ 0.30.0，PyTorch 必须 **cu130**（cu128 会静默关掉 int8 快速路径，慢约 3 倍）。

```bash
cd ComfyUI
git fetch --tags && git checkout v0.30.2   # 或更新版本
pip install -r requirements.txt
# 必须最后装 CUDA 13 栈：requirements.txt 里 torch 未锁版本，后装会覆盖并破坏快速路径
pip install --force-reinstall --index-url https://download.pytorch.org/whl/cu130 \
  torch torchvision torchaudio
```

**2）下载权重**（在 ComfyUI 根目录执行，路径写 `models`）：

```bash
hf download Comfy-Org/MiniMax-H3 \
  diffusion_models/minimax_h3_fl2va_pruned_int8_convrot.safetensors \
  text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors \
  vae/minimax_h3_video_vae_fp16.safetensors \
  vae/minimax_h3_audio_vae_fp32.safetensors \
  --local-dir models
```

**3）启动**（32 GB 内存的机器必加第一个标志）：

```bash
python main.py --disable-pinned-memory --disable-async-offload --reserve-vram 1
```

**4）首次验证**：`Template Library → Video → MiniMax H3 → T2V`，跑 **864×480 / 124 帧 / 20 步** 的最小样例，
确认「能加载 → 能采样 → 画面 + 立体声都解码 → 导出成功」再往上调。

## 文档索引

| 文件 | 内容 |
|---|---|
| [`docs/使用指南.md`](docs/使用指南.md) | **主文档**：三条路线对比、决策树、硬门槛、下载清单、安装顺序、参数手册、加速件、排错表 |
| [`docs/实测-路线B-4070TiSuper16G.md`](docs/实测-路线B-4070TiSuper16G.md) | **单机实测**：路线 B 耗时/显存/内存峰值 + 与社区口径的逐条对照 + 无头（Headless）运行要点 |
| [`DEVELOPMENT.md`](DEVELOPMENT.md) | 关键问题与方案（一坑一篇，8 条）—— 踩坑先看这里 |
| [`AGENTS.md`](AGENTS.md) | 给 AI / 未来自己的项目规则与**文档基线** |
| [`CHANGELOG.md`](CHANGELOG.md) | 版本记录 |
| [`docs/参考/`](docs/参考/) | 两篇 B 站教程视频的要点对照、风险说明与口播逐字稿 |

## 来源

Comfy-Org 文件清单 · comfyui-wiki 社区量化汇总 · MiniMax 官方 FAQ（hub.minimax.io/h3）· smeltcore RTX 4070 SUPER 实测配方 ·
jxxy 官方整合仓库导航 · B 站 AI-PanSir《你的显卡该下哪个 MiniMax H3》· 零度解说《新越狱模型》（仅作风险参考）。
每个数字在正文里都标了出处；**社区量化与实测会失效，请以当前仓库为准**。

## 许可与边界

- MiniMax H3 权重适用其**社区许可**（排除美 / 欧 / 英 / 韩，输出物同受限），本仓库只是资料整理，不附带任何权重。
- 本仓库**不提供**绕过内容安全机制的配置、提示词或思路；相关讨论仅限技术说明与风险提示。
- 参考视频的逐字稿为公开视频的机器转写，版权归原作者，仅作研究记录。
