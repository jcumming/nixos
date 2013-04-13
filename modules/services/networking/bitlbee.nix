{ config, pkgs, ... }:

with pkgs.lib;

let

  bitlbeeUid = config.ids.uids.bitlbee;

  cfg = config.services.bitlbee;

  configFile = pkgs.writeText "bitlbee.conf" 
    ''
      [settings]
      RunMode = ForkDaemon
      User = bitlbee
      DaemonInterface = ${cfg.interface}
      DaemonPort = ${toString cfg.portNumber}
      ${cfg.extraCfg}
    '';
in

{
  ###### interface

  options = {
    services.bitlbee = {
      enable = mkOption {
      default = false;
      description = ''
        Whether to run the BitlBee IRC to other chat network gateway.
        Running it allows you to access the MSN, Jabber, Yahoo! and ICQ chat
        networks via an IRC client.
      '';

      };
      interface = mkOption {
        default = "127.0.0.1";
        description = ''
          The interface the BitlBee deamon will be listening to.  If `127.0.0.1',
          only clients on the local host can connect to it; if `0.0.0.0', clients
          can access it from any network interface.
        '';
      };

      portNumber = mkOption {
        default = 6667;
        description = "Number of the port BitlBee will be listening to.";
      };

      extraCfg = mkOption {
        default = "";
        description = "Extra config to put in the [services] section of bitlbee.conf";
      };
    };
  };


  ###### implementation

  config = mkIf config.services.bitlbee.enable {

    users.extraUsers = singleton { 
      name = "bitlbee";
      uid = bitlbeeUid;
      description = "BitlBee user";
      home = "/var/empty";
    };

    users.extraGroups = singleton { 
      name = "bitlbee";
      gid = config.ids.gids.bitlbee;
    };

    systemd.services.bitlbee = { 
      after = [ "network.target" ] ; 
      description = "BitlBee IRC to other chat networks gateway";
      wantedBy = [ "multi-user.target" ]; 
      path = [ pkgs.bitlbee ]; 
      preStart = " mkdir -p /var/lib/bitlbee && chown bitlbee:bitlbee /var/lib/bitlbee";
      script = "exec bitlbee -c ${configFile} -v -n";
      };
  };
}
