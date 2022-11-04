{ pkgs, lib, config, ... }:
let
  cfg = config.virtualisation.buildkit;
in
{

  options.virtualisation.buildkit = with lib.types; {
    enable = lib.mkEnableOption (lib.mdDoc "buildkit");

    package = lib.mkOption {
      default = cfg.package;
      defaultText = lib.literalExpression "pkgs.buildkit";
      type = types.package;
      description = lib.mdDoc ''
        buildkit package to be used in the module.
      '';
    };

    includeCli = mkOption {
      type = types.bool;
      default = true;
      description = lib.mdDoc ''
        Include buildctl in system packages.
      '';
    };

    extraPrefixArgs = mkOption {
      type = types.listOf types.str;
      default = [ "" ];
      example = [ "nsenter" ];
      description = lib.mdDoc "Extra arguments to use before buildkitd.";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ "" ];
      example = [ "--log-ip" ];
      description = lib.mdDoc "Extra arguments to use running buildkitd.";
    };
  };

  config = lib.mkIf cfg.enable {

    environment.systemPackages = lib.mkIf (cfg.includeCli) [ cfg.package ];

    # service adapted from
    # https://github.com/moby/buildkit/blob/master/examples/systemd/system/buildkit.service

    systemd.services.buildkit = lib.mkIf (cfg.enable) {
      wantedBy = [ "default.target" ];
      after = [ "buildkit.socket" ];
      requires = [ "buildkit.socket" ];

      description = "BuildKit";
      path = with pkgs; [ buildkit coreutils util-linux ];
      serviceConfig = {
        ExecStart = "${lib.escapeShellArgs cfg.extraPrefixArgs } buildkitd --addr fd:// ${lib.escapeShellArgs cfg.extraArgs }";
        ExecReload = "${pkgs.procps}/bin/kill -s HUP $MAINPID";
        RestartSec = 2;
        Restart = "always";
        Type = "simple";
        KillMode = "mixed";
      };
    };
  };
}
