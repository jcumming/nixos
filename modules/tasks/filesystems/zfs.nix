{ config, pkgs, ... }:
#
# todo:
#   - crontab for scrubs, etc
#   - zfs tunables
#   - /etc/zfs/zpool.cache handling


with pkgs.lib;

let

  cfgSpl = config.boot.spl;
  inInitrd = any (fs: fs == "zfs") config.boot.initrd.supportedFilesystems;
  inSystem = any (fs: fs == "zfs") config.boot.supportedFilesystems;
  kernel = config.boot.kernelPackages;

in

{

  ###### interface
  
  options = { 
    boot.spl.hostid = mkOption { 
      default = "";
      example = "0xdeadbeef";
      description = ''
        ZFS uses a system's hostid to determine if a storage pool (zpool) is
        native to this system, and should thus be imported automatically.
        Unfortunately, this hostid can change under linux from boot to boot (by
        changing network adapters, for instance). Specify a unique 32 bit hostid in
        hex here for zfs to prevent getting a random hostid between boots and having to
        manually import pools.
      '';
    };
  };

  ###### implementation

  config = mkIf ( inInitrd || inSystem ) {

    boot = { 
      kernelModules = [ "spl" "zfs" ] ;
      extraModulePackages = [ kernel.zfs kernel.spl ];
      extraModprobeConfig = mkIf (cfgSpl.hostid != "") ''
        options spl spl_hostid=${cfgSpl.hostid}
      '';
    };

    boot.initrd = mkIf inInitrd { 
      kernelModules = [ "spl" "zfs" ] ;
      # zfs uses libs from:  zfs, glibc, utillinux, zlib, gcc and glibc. 
      # stage-1.nix provides:     glibc  utlilinux        gcc and glibc 
      extraUtilsCommands =
        ''
          cp -v ${kernel.zfs}/sbin/zfs $out/bin
          cp -v ${kernel.zfs}/sbin/zdb $out/bin
          cp -v ${kernel.zfs}/sbin/zpool $out/bin
          cp -pdv ${kernel.zfs}/lib/lib*.so.* $out/lib
          cp -pdv ${pkgs.zlib}/lib/lib*.so.* $out/lib
        '';
      postDeviceCommands =
        ''
          zpool import -f -a -d /dev
        '';
    };

    systemd.services."zpool-import" = mkIf inSystem {
      description = "Import zpools";
      after = [ "systemd-udev-settle.service" ];
      wantedBy = [ "local-fs.target" ];
      restartIfChanged = false;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "-${kernel.zfs}/sbin/zpool import -d /dev -f -a";     # XXX: allow failure?
      };
    };

    systemd.services."zfs-mount" = {
      description = "Mount zfs volumes";
      after = [ "zpool-import.service" ];
      wantedBy = [ "local-fs.target" ];
      restartIfChanged = false;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "-${kernel.zfs}/sbin/zfs mount -a";  # XXX: allow failure?
        ExecStop = "-${kernel.zfs}/sbin/zfs umount -a";  # XXX: allow failure?
      };
    };

    system.fsPackages = [ kernel.zfs ];                  # XXX: needed? zfs doesn't have (need) a fsck
    environment.systemPackages = [ kernel.zfs ];
    services.udev.packages = [ kernel.zfs ];             # to hook zvol naming, etc. 
  };
}
