{ pkgs, lib, config, ... }:
let
  containerdcfg = config.virtualisation.containerd;
  cfg = containerdcfg.rootless;
  proxy_env = config.networking.proxy.envVars;

  configFile =
    if cfg.configFile == null then
      settingsFormat.generate "containerd.toml" cfg.settings
    else
      cfg.configFile;

  containerdConfigChecked = pkgs.runCommand "containerd-config-checked.toml"
    {
      nativeBuildInputs = [ cfg.package ];
    }
    ''
      containerd -c ${configFile} config dump >/dev/null
      ln -s ${configFile} $out
    '';

  settingsFormat = pkgs.formats.toml { };
in
{

  options.virtualisation.containerd.rootless = with lib.types; {
    enable = lib.mkEnableOption (lib.mdDoc "containerd container runtime");

    package = lib.mkOption {
      default = containerdcfg.package;
      defaultText = lib.literalExpression "pkgs.containerd";
      type = types.package;
      description = lib.mdDoc ''
        containerd package to be used in the module.
      '';
    };

    rootlessHelperPackage = lib.mkOption {
      default = pkgs.containerd-rootless;
      defaultText = lib.literalExpression "pkgs.containerd-rootless";
      type = types.package;
      description = lib.mdDoc "containerd-rootless helper package to be used in the module.";
    };

    portDriver = lib.mkOption {
      default = "builtin";
      type = types.enum [ "builtin" "slirp4netns" ];
      description = lib.mdDoc "Port driver to be used";
    };

    # TODO: actually use this? or leave that to something like home-manager
    configFile = lib.mkOption {
      default = null;
      description = lib.mdDoc ''
        Path to containerd config file.
        Setting this option will override any configuration applied by the settings option.
      '';
      type = nullOr path;
    };

    settings = lib.mkOption {
      type = settingsFormat.type;
      default = { };
      description = lib.mdDoc ''
        Verbatim lines to add to containerd.toml
      '';
    };

    args = lib.mkOption {
      default = { };
      description = lib.mdDoc "extra args to append to the containerd cmdline";
      type = attrsOf str;
    };
  };

  config = lib.mkIf cfg.enable {
    # virtualisation.containerd = {
    #   args.config = toString containerdConfigChecked;
    #   settings = {
    #     version = 2;
    #     plugins."io.containerd.grpc.v1.cri" = {
    #       containerd.snapshotter =
    #         lib.mkIf config.boot.zfs.enabled (lib.mkOptionDefault "zfs");
    #       cni.bin_dir = lib.mkOptionDefault "${pkgs.cni-plugins}/bin";
    #     };
    #   };
    # };

    # environment.systemPackages = [ cfg.package ];

    # User services adapted from
    # https://github.com/containerd/nerdctl/blob/master/extras/rootless/containerd-rootless-setuptool.sh
    systemd.user.services = lib.mkIf (cfg.enable) {
      containerd = {
        wantedBy = [ "default.target" ];

        description = "containerd (Rootless)";
        environment = {
          CONTAINERD_ROOTLESS_ROOTLESSKIT_PORT_DRIVER = cfg.portDriver;
        };
        # needs newuidmap
        path = [ "/run/wrappers" ]
          ++ lib.optional config.boot.zfs.enabled config.boot.zfs.package;
        unitConfig = {
          ConditionUser = "!root";
          StartLimitInterval = "60s";
        };

        serviceConfig = {
          ExecStart = "${cfg.rootlessHelperPackage}/bin/containerd-rootless";
          ExecReload = "${pkgs.procps}/bin/kill -s HUP $MAINPID";
          TimeoutSec = 0;
          RestartSec = 2;
          Restart = "always";
          StartLimitBurst = 3;
          LimitNOFILE = "infinity";
          LimitNPROC = "infinity";
          LimitCORE = "infinity";
          TasksMax = "infinity";
          Delegate = true;
          Type = "simple";
          KillMode = "mixed";
        };
      };


      # buildkit = {
      #   wantedBy = [ "default.target" ];

      #   description = "BuildKit (Rootless)";
      #   partOf = [ containerdUnit ];
      #   path = with pkgs; [ buildkit coreutils util-linux ];
      #   serviceConfig =
      #     let
      #       # Helper script:
      #       # https://github.com/containerd/nerdctl/blob/884dc5480da0c4db5e2e18b008a9a7578af59b51/extras/rootless/containerd-rootless-setuptool.sh#L142-L147
      #       nsenterScript = pkgs.writeShellScript "nsenter"
      #         ''
      #           pid=$(cat "$XDG_RUNTIME_DIR/containerd-rootless/child_pid")
      #           exec nsenter --no-fork --wd="$(pwd)" --preserve-credentials -m -n -U -t "$pid" -- "$@"
      #         '';
      #     in
      #     {
      #       ExecStart = "${nsenterScript} buildkitd";
      #       ExecReload = "${pkgs.procps}/bin/kill -s HUP $MAINPID";
      #       RestartSec = 2;
      #       Restart = "always";
      #       Type = "simple";
      #       KillMode = "mixed";
      #     };
      # };
    };
  };
}
