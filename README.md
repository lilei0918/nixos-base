# nixos-base — NixOS 重装 bootstrap（最小 console 版）

从主仓库 `nixos-DMS`（`/home/lilei/nixos-DMS`）精简而来的**纯终端最小配置**。
**用途**：NixOS 重装时先用它把系统装起来，跑通网络与代理，再拉完整版仓库 rebuild，
避免在 GitHub / cachix / cache.nixos.org 下载慢的网络里一次装完整版（下载量太大）。

**目标主机**：Lenovo Legion R7000P 2021。主机名 `nixos`，flake 配置名 `legion`。

---

## 一、和完整版的差异（裁剪了什么）

| 项 | 完整版 nixos-DMS | 本 base |
|---|---|---|
| flake inputs | nixpkgs + home-manager/NUR/DMS/hermes/sops/grub-themes/daeuniverse… | **仅 nixpkgs** |
| GUI | niri + greetd/tuigreet | **无**（纯 TTY console） |
| home-manager | 有 | 无 |
| sops 机密 | secrets.yaml + age | 无（用户用 `initialPassword` 临时密码） |
| 代理 | dae（daeuniverse input） | 无专用代理软件，靠环境变量/http 代理 |
| 主题 GRUB | nixos-grub-themes | 默认外观 |
| 密码 | sops 解密 password_hash | `initialPassword = "changeme"`（首登后 `passwd` 改掉） |

保留的“基础设施”与完整版一致：GRUB 引导 + Windows 11 entry、NetworkManager、
清华/中科大镜像 substituter、btrfs fstrim/scrub、DATATB 自动挂载、内核参数。

---

## 二、目录

```text
nixos-base/
├── flake.nix                    # 仅 nixpkgs（rev 与主仓库 flake.lock 当前一致）
├── flake.lock
├── hosts/legion/
│   ├── configuration.nix        # console 最小配置（改这里）
│   ├── hardware-configuration.nix  # 硬件挂载（与主仓库同，按 UUID）
│   └── disko-fs.nix             # 重装分区脚本（保留 DATATB/加密盘，仅重建根分区）
└── README.md
```

---

## 三、日常切换流程（重装完、基础版在跑时）

```bash
cd ~/nixos-base
# 改 hosts/legion/configuration.nix（比如启代理）
nixos-rebuild switch --flake .#legion
```

---

## 四、完整重装流程（从 NixOS 官方 ISO）

> 假设目标：保留 nvme1n1p1(DATATB) + nvme1n1p3(加密盘)，只重建 nvme1n1p2(NixOS)。
> 本仓库拷到 ISO 环境（U 盘）里备用。

1. **进官方 ISO**，联网（如用 WiFi：`iwctl station wlan0 connect <SSID>`）。
2. **分区 + 挂载**（用仓库里的 disko 配置；只重建根分区，保留 DATATB/加密盘）：
   ```bash
   cd /mnt-usb/nixos-base        # 仓库所在路径
   nix run github:nix-community/disko -- --mode format,mount ./hosts/legion/disko-fs.nix
   ```
   > disko 只动 nvme1n1p2，挂完根在 `/mnt`。
3. **手动挂 NixOS 专用 ESP**（nvme0n1p6，UUID `AC09-EF5B`）到 `/mnt/boot/efi`：
   ```bash
   mkdir -p /mnt/boot/efi
   mount /dev/disk/by-uuid/AC09-EF5B /mnt/boot/efi
   ```
4. **重新生成 hardware-configuration.nix**（disko 重新格式化根分区 → btrfs
   根 UUID 会变，仓库里那份已过期）：
   ```bash
   nixos-generate-config --root /mnt
   cp /mnt/etc/nixos/hardware-configuration.nix ./hosts/legion/hardware-configuration.nix
   ```
5. **安装**（root 密码不需要：本配置 root 已锁，日常用 lilei + sudo）：
   ```bash
   nixos-install --root /mnt --flake .#legion --no-root-password
   ```
   如果 ISO 拉 flake/二进制慢，先给 ISO 的 nix 配好清华镜像再装：
   ```bash
   export NIX_CONFIG="substituters = https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://cache.nixos.org"
   ```
6. **重启进系统**：`reboot`。登录 lilei（初始密码 `changeme`）。
7. **立刻改密码**：`passwd`（并把 configuration.nix 里的 `initialPassword` 删掉再 rebuild）。
8. **配代理**（若直连 GitHub/cachix 还是慢）：编辑
   `hosts/legion/configuration.nix` 顶部的 `proxyHttp`，填你的 http 代理
   （本机 mihomo 或局域网其它设备的 7890 端口等），然后
   ```bash
   nixos-rebuild switch --flake .#legion
   ```
   验证：`curl -x "$proxyHttp" -I https://github.com`
9. **拉完整版并切换**：
   ```bash
   git clone git@github.com:lilei0918/nixos-DMS.git ~/nixos-DMS
   cd ~/nixos-DMS
   nh os switch .#legion        # 或 nixos-rebuild switch --flake .#legion
   ```
   完整版 rebuild 时的 flake inputs（home-manager/NUR/…）与 store 下载都会走
   `configuration.nix` 里已启用的代理（nix-daemon 已注入代理环境变量）。

---

## 五、nixpkgs 版本维护

本仓库 nixpkgs 固定到与主仓库当前一致的 rev（`ffb3c9b7…`，见 flake.nix）。
目的：基础版与完整版同源 nixpkgs，让完整版 rebuild 尽可能命中同一批二进制缓存。
主仓库升级 nixpkgs 后，重装前同步更新：

```bash
# 把 flake.nix 里 nixpkgs 的 rev 改成主仓库 flake.lock 当前的 nixpkgs rev
nix flake lock --update-input nixpkgs
nix flake check
```

---

## 六、安全与注意事项

- `initialPassword` 是**明文临时密码**，仅限装完首登用；务必首登 `passwd` 后删除该字段。
- root 已锁（`hashedPassword = "!"`），日常用 `sudo`。
- 本仓库无任何机密文件；重装需要的 secrets 在完整版仓库（sops 加密）中，
  完整版装好、sops 信任根恢复后自动解密。
- 重装会清空 nvme1n1p2（NixOS 根）；DATATB 与加密盘不动，但**请先备份重要数据**。
