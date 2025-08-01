{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hcloud.nixserver;
in
{

  options.hcloud.nixserver = mkOption {
    default = { };
    description = ''
      create a nixos server, via nixos-infect.
    '';
    type = with types;
      attrsOf (submodule ({ name, ... }: {
        options = {
          enable = mkEnableOption "nixserver";

          # todo eine option für zusätzlichen speicher
          name = mkOption {
            default = "nixserver-${name}";
            type = with types; str;
            description = ''
              name of the server
            '';
          };
          serverType = mkOption {
            default = "cx11";
            type = with types; str;
            description = ''
              Hardware equipment.This options influences costs!
            '';
          };
          channel = mkOption {
            default = "nixos-21.05";
            type = with types; str;
            description = ''
              nixos channel to install
            '';
          };
          backups = mkOption {
            default = false;
            type = with types; bool;
            description = ''
              enable backups or not
            '';
          };
          location = mkOption {
            default = null;
            type = nullOr str;
            description = ''
              location where the machine should run.
            '';
          };
          extraConfig = mkOption {
            default = { };
            type = attrs;
            description = ''
              parameter of the hcloud_server which are not covered yet.
            '';
          };
        };
      }));
  };

  config = mkIf (cfg != { }) {

    hcloud.server = mapAttrs'
      (name: configuration: {
        name = "${configuration.name}";
        value = {
          inherit (configuration) enable serverType backups name location extraConfig;
          provisioners = [{
            remote-exec.inline = [
              ''
                NO_REBOOT="dont" \
                PROVIDER=HCloud \
                NIX_CHANNEL=${configuration.channel} \
                curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | bash 2>&1 | tee /tmp/infect.log
              ''
              "shutdown -r +1"
            ];
          }];
        };
      })
      cfg;
  };

}
