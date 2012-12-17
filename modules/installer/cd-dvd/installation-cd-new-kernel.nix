{ config, pkgs, ... }:

{
  require = [ ./installation-cd-minimal.nix ];

  boot.kernelPackages = pkgs.linuxPackages_3_6;
  boot.vesa = false;
}
