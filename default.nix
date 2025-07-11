{ hasDataDisk }:
{
  config,
  lib,
  modulesPath,
  ...
}:

{
  nixpkgs.hostPlatform = "x86_64-linux";

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/profiles/minimal.nix")
  ];

  # Enable bootloader from initial configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Grow the root partition to fill the disk
  boot.growPartition = true;

  # Add filesystem partitions
  swapDevices = [
    {
      device = "/dev/disk/by-partlabel/disk-system-swap";
      randomEncryption.enable = true;
      randomEncryption.allowDiscards = config.services.fstrim.enable;
    }
  ];

  fileSystems =
    # Disk: /dev/sda
    {
      "/boot" = {
        device = "/dev/disk/by-partlabel/disk-system-ESP";
        fsType = "vfat";
      };
      "/" = {
        device = "/dev/disk/by-partlabel/disk-system-root";
        fsType = "ext4";
        autoResize = true;
      };
    }
    //
    # Disk: /dev/sdb (optional)
    lib.optionalAttrs hasDataDisk {
      "/data" = {
        device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi1";
        fsType = "ext4";
        autoResize = true;
      };
    };

  # Automatically keep system clean and optimized
  boot.loader.systemd-boot.configurationLimit = 8;
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 7d";
  nix.optimise.automatic = true;

  nix.channel.enable = false;
  system.disableInstallerTools = true;

  # Configure QEMU quest agent for safe shutdown
  services.qemuGuest.enable = true;
  systemd.extraConfig = "DefaultTimeoutStopSec=10s";

  # Enable SSH
  programs.ssh.startAgent = true;
  services.openssh.enable = true;

  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.KbdInteractiveAuthentication = false;
  users.users."root".openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILPLqP71iBRAFd7OFIjlkN6yGEr++G5eRDJ+U57R9f8e user@nixos"
  ];

  # Prevent local link hostname resolution
  networking.enableIPv6 = false;

  # Update locale and timezone
  console.keyMap = "de";
  time.timeZone = "Europe/Berlin";

  # Optimizations
  services.preload.enable = true;

  # Enable firmware updates
  services.fwupd.enable = true;
  services.fwupd.extraRemotes = [ "lvfs-testing" ];
  services.fwupd.daemonSettings.DisabledPlugins = [ "bios" ];
}
