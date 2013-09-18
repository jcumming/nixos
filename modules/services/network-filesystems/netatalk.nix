# Support for DRBD, the Distributed Replicated Block Device.

{ config, pkgs, ... }:

with pkgs.lib;

let cfg = config.services.netatalk;
    afpd_cfg = pkgs.writeText "afp.conf" cfg.config;

in

{

  ###### interface

  options = {

    services.netatalk.enable = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Whether to enable support for AppleTalk File Server. 
      '';
    };

    services.netatalk.config = mkOption {
      default = "";
      type = types.string;
      description = ''
        Contents of the <filename>afp.conf</filename> configuration file.
      '';
      example = ''
        [Global]
        vol preset = default_for_all_vol
        uam list = uams_dhx2.so
        save password = no
         
        [default_for_all_vol]
        file perm = 0664
        directory perm = 0774
        cnid scheme = dbd
         
        [Homes]
        basedir regex = /home
         
        [TimeMachine]
        path = /afp/tm_backup
        time machine = yes
      '';
    };

  };

  
  ###### implementation

  config = mkIf cfg.enable {
  
    environment.systemPackages = [ pkgs.netatalk ];

    security.pam.services = [ { name = "netatalk"; } ] ;

# need a pre-target to make /var/lib/.. 
    
    systemd.services.netatalk_afp = {
      description = "netatalk afp server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig.ExecStart = "${pkgs.netatalk}/sbin/afpd -d -F ${afpd_cfg}";
    };

    systemd.services.netatalk_cnid_metad = {
      description = "netatalk catalog node id mapping server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig.ExecStart = "${pkgs.netatalk}/sbin/cnid_metad -d -F ${afpd_cfg}";
    };
  };
  
}
