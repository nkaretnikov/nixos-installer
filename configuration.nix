# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  boot.loader.gummiboot.enable = true;
  boot.loader.gummiboot.timeout = 5;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_3_18;
  boot.initrd.kernelModules = [ "fbcon" ];
  boot.initrd.luks.devices = [
    { name = "main"; device = DISK3; preLVM = true; }
  ];

  fileSystems = [ {
    mountPoint = "/";
    device = "/dev/main/main";
  } {
    mountPoint = "/home";
    device = "/dev/main/home";
  } {
    mountPoint = "/boot";
    device = DISK2;
  }
  ];

  networking.hostName = "nixos";

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "15.08";
}
