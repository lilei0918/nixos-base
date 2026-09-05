# AGENTS.md — nixos-base（NixOS 重装 bootstrap 仓库）

本仓库是 `nixos-DMS` 精简出的**纯终端最小版**，仅用于 NixOS 重装引导，
随后会切换到完整版 `~/nixos-DMS`。AI agent 在本仓库工作时遵守以下规则。

## 1. 适用范围

- 目标主机：Lenovo Legion R7000P 2021，配置名 `legion`。
- 只改本仓库内文件；不要引用 `nixos-DMS` 的 `inputs`/模块路径（本仓库 flake 只有 nixpkgs）。
- 需要完整版配置做对照/引用时，去读 `~/nixos-DMS`（只读），不要把它拖进来。

## 2. 硬性安全边界（同主仓库）

- 禁止读写工作区以外的文件（除非运维必需路径）。
- 禁止未要求就 `git push` / `gh` 创建远端对象 / 破坏性操作（`rm -rf`、分区操作等）。
- 禁止改动 `/home/lilei` 之外系统关键文件（rebuild 流程除外）。
- `hosts/legion/hardware-configuration.nix` 由 `nixos-generate-config` 生成，勿手动改。

## 3. 机密处理

- 本仓库**无 sops/机密**。`configuration.nix` 里的 `initialPassword = "changeme"`
  是临时密码，只用于装完首登；agent 不得将其改写成真实密码、不得在别处复述。
- 回答/文档中不出现任何真实口令。

## 4. 工具默认值

- 本仓库是独立 flake，构建命令：
  `nixos-rebuild switch --flake .#legion`（或进入完整版后用 `nh`）。
- 校验：`alejandra .`（如已装）→ `nix flake check`。
- 重装走 `disko-fs.nix`（只重建 nvme1n1p2）+ 手动挂 `/boot/efi`(nvme0n1p6)。

## 5. 沟通

- 默认中文；代码/命令/标识符用英文。
- 执行会改系统的命令前先说明命令与影响。
