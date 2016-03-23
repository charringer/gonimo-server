{
  "baby.gonimo.com" =
    { config, pkgs, ...}:
    {
      deployment.targetEnv = "none";

      # Host specifics
      boot.loader.grub.device = "/dev/vda";
      imports =
      [ <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
      	];

      boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_blk" ];
      boot.kernelModules = [ ];
      boot.extraModulePackages = [ ];

      fileSystems."/" =
      { device = "/dev/disk/by-label/nixos";
      	fsType = "ext4";
	};
	
      services.openssh.enable = true;
      networking.firewall.allowPing = true;
    };
}
