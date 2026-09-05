# ═══════════════════════════════════════════════════════════════
# nixos-base — Legion R7000P 2021 最小化 console 配置
#
# 定位：NixOS 重装 bootstrap。只装纯终端系统，跑通网络后：
#   1) 改本文件顶部 `proxyHttp` 填好你的 http 代理（局域网/手机代理均可）
#   2) sudo nixos-rebuild switch（nix-daemon 会随之带上代理环境变量）
#   3) git clone / DATATB 拷入完整版仓库，`nh os switch` / nixos-rebuild 到完整版
#
# 相对主仓库（nixos-DMS）裁剪掉：GUI(niri/greetd)、home-manager、sops、
# NUR/DMS/hermes、daeuniverse 代理、vault、gaming、nix-ld 等一切非必需输入/模块。
# 本机只跟随 nixpkgs（唯一 flake input），且 rev 与主仓库当前一致。
# ═══════════════════════════════════════════════════════════════
{
  config,
  pkgs,
  lib,
  ...
}: let
  # ─────────────────────────────────────────────────────────────
  # 代理（编辑这里）
  #   null          = 不走代理（默认）
  #   "http://…:7890" = 启用，nix/git/curl 全部走该 http 代理
  #   （可指向局域网其它设备，如手机/路由器的代理端口）
  # ─────────────────────────────────────────────────────────────
  proxyHttp = null;
in {
  imports = [
    ./hardware-configuration.nix
  ];

  # ─────────────────────────────────────────────────────────────
  # 用户
  #   initialPassword：装好后首次登录请立刻 `passwd` 改成真密码，
  #   并把这个字段从本文件删除后再 rebuild。
  # ─────────────────────────────────────────────────────────────
  users.users.lilei = {
    isNormalUser = true;
    uid = 1000;
    description = "lilei";
    extraGroups = ["wheel" "networkmanager"];
    initialPassword = "changeme";
  };

  # root 锁定（只用 lilei + sudo；避免 root 无密码从 console 登录）
  users.users.root.hashedPassword = "!";

  # ─────────────────────────────────────────────────────────────
  # 引导（与主仓库 boot.nix 一致：GRUB 主引导 + Windows 手动 entry；
  # 不装主题 = 用默认 grub 外观，主题等完整版 rebuild 后再来）
  # ─────────────────────────────────────────────────────────────
  boot.loader = {
    timeout = 5;

    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";

      extraEntries = ''
        menuentry "Windows 11" {
          search --file /EFI/Microsoft/Boot/bootmgfw.efi --set=root
          chainloader /EFI/Microsoft/Boot/bootmgfw.efi
        }
      '';
      extraEntriesBeforeNixOS = false;
    };

    efi = {
      efiSysMountPoint = "/boot/efi";
      canTouchEfiVariables = true;
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelParams = [
    "amd_pstate=passive"
    "nowatchdog"
  ];

  # ─────────────────────────────────────────────────────────────
  # 硬件（console 阶段最简；GPU 固件仍开启避免显示问题）
  # ─────────────────────────────────────────────────────────────
  hardware.enableRedistributableFirmware = true;

  services = {
    fstrim.enable = true;
    btrfs.autoScrub.enable = true;
  };

  # ─────────────────────────────────────────────────────────────
  # 网络：NetworkManager（console 下用 `nmtui` / `nmcli` 连 WiFi）
  # ─────────────────────────────────────────────────────────────
  networking = {
    hostName = "nixos";

    networkmanager = {
      enable = true;
      wifi.backend = "wpa_supplicant";
      wifi.powersave = false;
    };

    timeServers = [
      "ntp.aliyun.com"
      "ntp.tencent.com"
    ];
  };

  # ─────────────────────────────────────────────────────────────
  # Nix 自身：镜像 substituter（装包尽量命中清华/中科大镜像，绕开
  # cache.nixos.org / cachix 的慢速；github 源码/输入另走上方代理）
  # ─────────────────────────────────────────────────────────────
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];

    auto-optimise-store = true;

    substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=1"
      "https://mirrors.ustc.edu.cn/nix-channels/store?priority=2"
      "https://cache.nixos.org?priority=20"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 3d";
  };

  nixpkgs.config.allowUnfree = true;

  # ─────────────────────────────────────────────────────────────
  # 时区 / 键盘
  # ─────────────────────────────────────────────────────────────
  time.timeZone = "Asia/Shanghai";

  console.keyMap = "us";

  # ─────────────────────────────────────────────────────────────
  # 系统软件包（装完即用，体积从简）
  #   git/curl/wget  — 拉完整版仓库 / 测代理
  #   vim           — 改配置
  #   ntfs3g        — 若需手动挂 DATATB(ntfs)
  #   btrfs-progs   — btrfs 维护
  # ─────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    vim
    jq
    htop
    tree
    file
    btrfs-progs
    ntfs3g
  ];

  # DATATB 数据盘自动挂载（与主仓库一致；重装后立即能取回备份/仓库）
  fileSystems."/run/media/lilei/DATATB" = {
    device = "/dev/disk/by-label/DATATB";
    fsType = "ntfs3";
    options = [
      "uid=${toString config.users.users.lilei.uid}"
      "gid=${toString config.users.groups.users.gid}"
      "umask=022"
      "nofail"
      "x-systemd.automount"
    ];
  };

  # ─────────────────────────────────────────────────────────────
  # 代理接线（非 null 时把代理注入 nix-daemon，否则 root 下的
  # nix/git 拉取不认 sessionVariables）
  # ─────────────────────────────────────────────────────────────
  networking.proxy.default = proxyHttp;

  systemd.services.nix-daemon.environment = lib.mkIf (proxyHttp != null) {
    http_proxy = proxyHttp;
    https_proxy = proxyHttp;
    all_proxy = proxyHttp;
    no_proxy = "127.0.0.1,localhost";
  };

  # ─────────────────────────────────────────────────────────────
  # 远程运维（需要时取消注释，base 阶段默认不开 sshd）
  # ─────────────────────────────────────────────────────────────
  # services.openssh = {
  #   enable = true;
  #   settings.PasswordAuthentication = true;
  #   settings.PermitRootLogin = "no";
  # };

  system.stateVersion = "25.05";
}
