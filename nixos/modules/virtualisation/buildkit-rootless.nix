{ pkgs, lib, config, ... }:
let
  buildkitcfg = config.virtualisation.buildkit;
  cfg = buildkitcfg.rootless;
  proxy_env = config.networking.proxy.envVars;

  configFile =
    if cfg.configFile == null then
      settingsFormat.generate "containerd.toml" cfg.settings
    else
      cfg.configFile;

  containerdConfigChecked = pkgs.runCommand "containerd-config-checked.toml"
    {
      nativeBuildInputs = [ cfg.package ];
    } ''
    containerd -c ${configFile} config dump >/dev/null
    ln -s ${configFile} $out
  '';

  settingsFormat = pkgs.formats.toml { };
in
{

  options.virtualisation.buildkit.rootless = with lib.types; {
    enable = lib.mkEnableOption (lib.mdDoc "buildkit");

    package = lib.mkOption {
      default = buildkitcfg.package;
      defaultText = lib.literalExpression "pkgs.buildkit";
      type = types.package;
      description = lib.mdDoc ''
        buildkit package to be used in the module.
      '';
    };

    args = lib.mkOption {
      default = { };
      description = lib.mdDoc "extra args to append to the containerd cmdline";
      type = attrsOf str;
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
      example = [ "--debug" ];
      description = lib.mdDoc "Extra arguments to use running buildkitd.";
    };
  };

  config = lib.mkIf cfg.enable {

    environment.systemPackages = lib.mkIf (buildkitcfg.includeCli) [ cfg.package ];

    # service adapted from
    # https://github.com/moby/buildkit/blob/master/examples/systemd/user/buildkit.service
    # and
    # https://github.com/containerd/nerdctl/blob/master/extras/rootless/containerd-rootless-setuptool.sh
    systemd.user.services = lib.mkIf (cfg.enable) {
      buildkit = {
        wantedBy = [ "default.target" ];

        description = "BuildKit (Rootless)";
        path = with pkgs; [ buildkit coreutils util-linux ];
        serviceConfig = {
          ExecStart = "${nsenterScript} buildkitd ${lib.concatStringsSep " " (lib.cli.toGNUCommandLine {} cfg.args)}";
          ExecReload = "${pkgs.procps}/bin/kill -s HUP $MAINPID";
          RestartSec = 2;
          Restart = "always";
          Type = "simple";
          KillMode = "mixed";
        };
      };
    };
  };
}
