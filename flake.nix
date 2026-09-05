{
  description = "NixOS base (minimal console) - Legion R7000P 2021 reinstall bootstrap";

  inputs = {
    # 唯一 input：只跟 nixpkgs（无 home-manager/sops/NUR/…）。
    # rev 与主仓库 flake.lock 当前 nixpkgs 一致（ffb3c9b7），
    # 目的：完整版 rebuild 前基础版已装的 closure 与主仓库同源，
    # 通过 TUNA/USTC 镜像能命中尽量多的二进制缓存，减少下载。
    # 重装前若主仓库已升级 nixpkgs，可改此 rev 后 `nix flake lock --update-input nixpkgs`。
    nixpkgs.url = "github:nixos/nixpkgs/ffb3c9b700e759be2ef13237c9d8f953b32a1e46";
  };

  outputs = {nixpkgs, ...}: {
    nixosConfigurations.legion = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ./hosts/legion/configuration.nix
      ];
    };
  };
}
