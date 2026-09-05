# ⚠️ 此文件由 ‘nixos-generate-config’ 生成，勿手动修改！
# 修改请前往：https://github.com/lilei0918/nixos-DMS
{
  config,
  lib,
  modulesPath,
  ...
}: {
  # ─────────────────────────────────────────────────────
  # ✅ 导入未识别硬件模块处理
  # ─────────────────────────────────────────────────────
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # ─────────────────────────────────────────────────────
  # ✅ 引导内核模块
  # ─────────────────────────────────────────────────────
  boot.initrd = {
    availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    #kernelModules = [ ];
  };

  # ─────────────────────────────────────────────────────
  # ✅ 文件系统挂载（Btrfs 子卷）
  # ─────────────────────────────────────────────────────
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/6c9764ff-c293-4be8-801c-982bdb6ed30a";
    fsType = "btrfs";
    options = ["subvol=@" "compress=zstd" "noatime" "discard=async"];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/6c9764ff-c293-4be8-801c-982bdb6ed30a";
    fsType = "btrfs";
    options = ["subvol=@home" "compress=zstd" "noatime" "discard=async"];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/6c9764ff-c293-4be8-801c-982bdb6ed30a";
    fsType = "btrfs";
    options = ["subvol=@nix" "compress=zstd" "noatime" "discard=async"];
  };

  fileSystems."/var/log" = {
    device = "/dev/disk/by-uuid/6c9764ff-c293-4be8-801c-982bdb6ed30a";
    fsType = "btrfs";
    options = ["subvol=@log" "compress=zstd" "noatime" "discard=async"];
  };

  fileSystems."/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = ["mode=1777" "nosuid" "nodev" "size=4G"];
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/AC09-EF5B";
    fsType = "vfat";
    options = ["fmask=0022" "dmask=0022"];
  };

  # ─────────────────────────────────────────────────────
  # ✅ 交换空间配置
  # ─────────────────────────────────────────────────────
  swapDevices = [];

  # ─────────────────────────────────────────────────────
  # ✅ 网络配置（DHCP 由 network.nix 的 NetworkManager 负责）
  # ─────────────────────────────────────────────────────
  networking.useDHCP = lib.mkDefault false;

  # 可按需启用具体接口：
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp4s0.useDHCP = lib.mkDefault true;

  # ─────────────────────────────────────────────────────
  # ✅ 处理器微码与平台设定
  # ─────────────────────────────────────────────────────
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
