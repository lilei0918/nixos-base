# disko 声明式分区配置 — 仅重建 NixOS 根分区（nvme1n1p2），保留 DATATB 与加密盘
#
# 作用：重装/换机时用 disko 一键复刻 NixOS 的 btrfs 子卷布局（@/@home/@nix/@log），
#      不再手动分区。对应 hosts/legion/hardware-configuration.nix 的挂载方式。
#
# 磁盘：nvme1n1（ZHITAI TiPlus7100 1TB），当前分区：
#   nvme1n1p1  783.9G  ntfs  DATATB  数据盘  → 本配置【不】格式化，仅占位保留
#   nvme1n1p2  150G    btrfs NIXOS   根分区  → 本配置格式化为 btrfs + 子卷（⚠️ 会清空此分区）
#   nvme1n1p3  20G     LUKS2 加密盘          → 本配置【不】格式化，仅占位保留
#
# ⚠️ EFI（/boot/efi）在 nvme0n1p6（NixOS 专用 ESP，UUID AC09-EF5B），本配置不碰，
#    由安装步骤手动挂载；NixOS 引导为 GRUB（configuration.nix 的 boot.loader.grub，
#    写入该 ESP，与 nvme0n1p1 的 Windows ESP 相互独立）。
#
# 用法（在 NixOS 官方 ISO 中）：
#   保留 DATATB + 加密盘（分区表已存在，只格式化/挂载根分区）：
#     nix run github:nix-community/disko -- --mode format,mount ./hosts/legion/disko-fs.nix
#   全新空盘（重建整块 nvme1n1 的分区表；会覆盖全盘，DATATB/加密盘不保留）：
#     nix run github:nix-community/disko -- --mode create,format,mount ./hosts/legion/disko-fs.nix
#   ⚠️ 不要使用 --mode destroy（会销毁整块盘）。
{
  disko.devices.disk.nvme1n1 = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-ZHITAI_TiPlus7100_1TB_ZTA71T0AB24182L6AD";

    content = {
      type = "gpt";

      partitions = {
        DATATB = {
          # 数据盘（NTFS）：占位保留，不格式化（无 content）
          # ⚠️ disko GPT 的裸数字 size 是「512 字节扇区数」不是字节！
          #    必须用带单位写法；841670983680 B ≈ 783.9 GB（实测）
          size = "784G";
          type = "0700"; # Microsoft basic data
        };

        NIXOS = {
          # NixOS 根分区（btrfs），重装目标
          # 161062674432 B = 150 GiB（实测分区大小）
          size = "150G";
          type = "8300"; # Linux filesystem

          content = {
            type = "btrfs";
            extraArgs = ["-f"]; # 强制格式化，清空旧数据（此分区即 NixOS 根）

            subvolumes = {
              "@" = {
                mountpoint = "/";
                mountOptions = ["compress=zstd" "noatime" "discard=async"];
              };
              "@home" = {
                mountpoint = "/home";
                mountOptions = ["compress=zstd" "noatime" "discard=async"];
              };
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = ["compress=zstd" "noatime" "discard=async"];
              };
              "@log" = {
                mountpoint = "/var/log";
                mountOptions = ["compress=zstd" "noatime" "discard=async"];
              };
            };
          };
        };

        VAULT = {
          # 加密盘（LUKS2）：占位保留，不格式化（无 content）
          # 21474836480 B = 20 GiB（实测分区大小）
          size = "20G";
          type = "8309"; # Linux LUKS
        };
      };
    };
  };
}
