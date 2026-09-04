{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types mkOption;

  cfg = config.services.pterodactyl.wings;

  format = pkgs.formats.yaml { };
  configFile = format.generate "pterodactyl-wings-config.yml" cfg.settings;
in
{
  options.services.pterodactyl.wings = {
    enable = lib.mkEnableOption "Pterodactyl Wings service";

    package = mkOption {
      type = types.package;
      default = pkgs.pterodactyl-wings;
      defaultText = "pkgs.pterodactyl-wings";
      description = "Pterodactyl Wings package to use";
    };

    user = mkOption {
      type = types.str;
      default = "pterodactyl-wings";
      description = "User to run Wings as";
    };

    group = mkOption {
      type = types.str;
      default = "pterodactyl-wings";
      description = "Group to run Wings as";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the Wings API and SFTP ports in the firewall";
    };

    containerRuntime = mkOption {
      type = types.enum [ "docker" ];
      default = "docker";
      description = "The container runtime to use for Wings";
    };

    rootDir = mkOption {
      type = types.path;
      default = "/var/lib/pterodactyl-wings";
      description = "The root directory where all of Wings's data is stored";
    };

    logDir = mkOption {
      type = types.path;
      default = "/var/log/pterodactyl-wings";
      description = "Directory where logs for Wings and server installations are stored";
    };

    tmpDir = mkOption {
      type = types.path;
      default = "/var/cache/pterodactyl-wings";
      description = "Directory where temporary files for server installations are stored";
    };

    runDir = mkOption {
      type = types.path;
      default = "/run/pterodactyl-wings";
      description = "Directory where runtime files are stored";
    };

    secrets = mkOption {
      description = ''
        It is recommended you keep your secrets separate from the configuration.
        It's especially important to keep the raw secrets out of your nix
        configuration, as the values will be preserved in your nix store.
        This attribute allows you to configure the location of secret files to
        be loaded at runtime.

        If you need to set additional secret values in the pterodactyl-wings
        config you should leverage "file://''${filePath}"
      '';
      default = { };
      type = types.submodule {
        options = {
          manual = mkOption {
            default = false;
            example = true;
            description = ''
              Configuring pterodactyl-wings' secret files via the secrets
              attribute set is intended to be convenient and help catch cases
              where values are required to run at all.
              If a user wants to set these values themselves and bypass the
              validation they can set this value to true.
            '';
            type = types.bool;
          };

          # required
          tokenIDFile = mkOption {
            type = types.nullOr types.externalPath;
            default = null;
            description = ''
              Path to your Token ID secret used for X.
            '';
          };

          # required
          tokenFile = mkOption {
            type = types.nullOr types.externalPath;
            default = null;
            description = ''
              Path to your Token secret used for X.
            '';
          };

          sslCertFile = mkOption {
            type = types.nullOr types.externalPath;
            default = null;
            description = ''
              Path to your SSL Cert secret used for X.
            '';
          };

          sslKeyFile = mkOption {
            type = types.nullOr types.externalPath;
            default = null;
            description = ''
              Path to your SSL Key secret used for X.
            '';
          };
        };
      };
    };

    settings = mkOption {
      description = ''
        Your Pterodactyl Wings config.yml as a Nix attribute set.
        There are several values that are defined and documented in nix such as `check_permissions_on_boot`,
        but additional items can also be included.

        <https://pterodactyl.io/wings/1.0/configuration.html>

        Some values are undocumented <https://github.com/pterodactyl/wings/blob/develop/config/config.go>
      '';
      default = { };
      example = ''
        {
          app_name = "nixos_pterodactyl";
          installer_limits = {
            memory = 1024;
            cpu = 100;
          };
        }
      '';
      type = types.submodule {
        freeformType = format.type;
        options = {
          # TODO: consider a genUuid option, could set value with file://<file_name>
          # without needing to replace values in the config file
          uuid = lib.mkOption {
            type = with lib.types; nullOr str;
            # pre-defined uuid of Dns in RFC 4122
            example = "6ba7b810-9dad-11d1-80b4-00c04fd430c8";
            default = null;
            description = ''
              Must be set to a unique identifier, preferably a UUID according to
              RFC 4122. UUIDs can be generated with `uuidgen` command, found in
              the `util-linux` package.
            '';
          };

          ignore_panel_config_updates = mkOption {
            type = types.nullOr types.bool;
            default = true;
            example = true;
            description = ''
              Causes confiuration updates that are sent by the Pterodactyl Panel to be ignored.
              Important for our declarative config via nix.
            '';
            # TODO: check if having this off causes any problems at runtime, maybe force
          };

          token_id = mkOption {
            type = types.str;
            default = null;
            example = "/var/log/authelia/authelia.log";
            description = "File path where the logs will be written. If not set logs are written to stdout.";
          };

          token = mkOption {
            type = types.str;
            default = null;
            example = "/var/log/authelia/authelia.log";
            description = "File path where the logs will be written. If not set logs are written to stdout.";
          };

          remote = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "TODO";
            description = "The URL of the panel to connect to.";
          };

          debug = mkOption {
            type = types.nullOr types.bool;
            default = null;
            example = true;
            description = "Force Wings to run in debug mode.";
          };

          check_permissions_on_boot = mkOption {
            type = types.nullOr types.bool;
            default = null;
            example = true;
            description = ''
              Check all file permissions on each boot.
              Disable this when you have a very large amount of files and the
              server startup is hanging on checking permissions.
            '';
          };

          api = {
            host = mkOption {
              type = types.str;
              default = "localhost";
              example = "0.0.0.0";
              description = "The address to listen on.";
            };
            port = lib.mkOption {
              type = lib.types.port;
              default = 8080;
              example = 11343;
              description = "Port that pterodactyl wings listens on.";
            };
          };

          system = {
            # TODO: force these values?
            root_directory = mkOption {
              type = types.nullOr types.externalPath;
              default = null;
              example = "/var/log/authelia/authelia.log";
              description = "File path where the logs will be written. If not set logs are written to stdout.";
            };

            log_directory = mkOption {
              type = types.nullOr types.externalPath;
              default = null;
              example = "/var/log/authelia/authelia.log";
              description = "File path where the logs will be written. If not set logs are written to stdout.";
            };

            data = mkOption {
              type = types.nullOr types.externalPath;
              default = null;
              example = "/var/log/authelia/authelia.log";
              description = "File path where the logs will be written. If not set logs are written to stdout.";
            };

            archive_directory = mkOption {
              type = types.nullOr types.externalPath;
              default = null;
              example = "/var/log/authelia/authelia.log";
              description = "File path where the logs will be written. If not set logs are written to stdout.";
            };

            backup_directory = mkOption {
              type = types.nullOr types.externalPath;
              default = null;
              example = "/var/log/authelia/authelia.log";
              description = "File path where the logs will be written. If not set logs are written to stdout.";
            };

            tmp_directory = mkOption {
              type = types.nullOr types.externalPath;
              default = null;
              example = "/var/log/authelia/authelia.log";
              description = "File path where the logs will be written. If not set logs are written to stdout.";
            };

            username = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "pterodactyl-wing";
              description = "File path where the logs will be written. If not set logs are written to stdout.";
            };

            user = {
              uid = mkOption {
                type = types.nullOr types.ints.unsigned;
                default = null;
                example = 5432;
                description = "File path where the logs will be written. If not set logs are written to stdout.";
              };
              gid = mkOption {
                type = types.nullOr types.ints.unsigned;
                default = null;
                example = 5432;
                description = "File path where the logs will be written. If not set logs are written to stdout.";
              };
            };

            sftp = {
              bind_address = mkOption {
                type = types.str;
                default = "localhost";
                example = "0.0.0.0";
                description = "The address to listen on.";
              };
              bind_port = lib.mkOption {
                type = lib.types.port;
                default = 2022;
                example = 11344;
                description = ''
                  Port that llama-swap listens on.
                '';
              };
            };
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.settings.uuid != null;
        message = "services.pterodactyl.wings.uuid must be set";
      }
      {
        assertion =
          # both set
          (cfg.secrets.sslCertFile != null && cfg.secrets.sslKeyFile != null)
          # or both unset
          || (cfg.secrets.sslCertFile == null && cfg.secrets.sslKeyFile == null);
        message = "both services.pterodactyl.wings.secrets.sslCertFile and services.pterodactyl.wings.secrets.sslKeyFile must be set or neither";
      }
      {
        assertion =
          cfg.secrets.manual || (cfg.secrets.tokenIDFile != null && cfg.secrets.tokenFile != null);
        message = ''
          Pterodactyl Wings requires a Token ID and Token to work.
          Either set them like so:
          services.pterodactyl.wings.secrets.tokenIDFile = "/my/path/to/token_id_file";
          services.pterodactyl.wings.secrets.tokenFile = "/my/path/to/token_file";

          Or set services.pterodactyl.wings.secrets.manual = true; and provide
          them yourself in the settings for a key via `$ENV_VAR` or `file://<filename>` directives.
          https://github.com/pterodactyl/wings/blob/d6116827313dae176ddf4741e233554392993398/config/config.go#L414-L422
          Do not include raw secrets in nix settings.
        '';
      }
    ];

    services.pterodactyl.wings.settings = {
      remote =
        let
          panelCfg = config.settings.pterodactyl.panel;
        in
        lib.mkIf panelCfg.enable lib.mkDefault panelCfg.app.url;

      token_id = "file://${cfg.secrets.tokenIDFile}";
      token = "file://${cfg.secrets.tokenFile}";
      api.ssl = {
        enabled = lib.mkIf (
          cfg.secrets.sslCertFile != null || cfg.secrets.sslKeyFile != null
        ) lib.mkDefault true;
        cert = lib.mkIf (cfg.secrets.sslCertFile != null) "file://${cfg.secrets.sslCertFile}";
        key = lib.mkIf (cfg.secrets.sslKeyFile != null) "file://${cfg.secrets.sslKeyFile}";
      };

      system = {
        root_directory = cfg.rootDir;
        log_directory = cfg.logDir;
        data = "${cfg.rootDir}/volumes";
        archive_directory = "${cfg.rootDir}/archives";
        backup_directory = "${cfg.rootDir}/backups";
        tmp_directory = cfg.tmpDir;
        username = cfg.user;
        user = {
          uid = config.users.users.${cfg.user}.uid;
          gid = config.users.groups.${cfg.group}.gid;
        };
        passwd.directory = "${cfg.runDir}/etc";
        machine_id.directory = "${cfg.runDir}/machine-id";
      };
    };

    virtualisation.docker.enable = lib.mkIf (cfg.containerRuntime == "docker") true;

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [
      cfg.settings.api.port
      cfg.settings.system.sftp.bind_port
    ];

    systemd.services.pterodactyl-wings = {
      description = "Pterodactyl Wings service";
      after = [
        "network-online.target"
      ]
      ++ lib.optional (cfg.containerRuntime == "docker") "docker.service";
      wants = [ "network-online.target" ];
      requires = lib.optional (cfg.containerRuntime == "docker") "docker.service";
      wantedBy = [ "multi-user.target" ];

      serviceConfig =
        let
          nonNullSecretsMap = lib.filterAttrs (
            k: v:
            # strip out the manual override
            k != "manual"
            # and strip unset secrets
            && v != null
          ) cfg.secrets;
        in
        {
          User = cfg.user;
          Group = cfg.group;
          ExecStart = "${lib.getExe cfg.package} --config ${configFile}";
          Restart = "always";
          RestartSec = "5s";
          StateDirectory = lib.removePrefix "/var/lib/" cfg.rootDir;
          LogsDirectory = lib.removePrefix "/var/log/" cfg.logDir;
          CacheDirectory = lib.removePrefix "/var/cache/" cfg.tmpDir;
          RuntimeDirectory = lib.removePrefix "/run/" cfg.runDir;
          ReadWritePaths = [
            cfg.rootDir
            cfg.logDir
            cfg.tmpDir
            cfg.runDir
          ];

          LoadCredential = lib.mapAttrsToList (k: v: "${k}:${v}") nonNullSecretsMap;

          # Security options:
          AmbientCapabilities = "CAP_CHOWN";
          CapabilityBoundingSet = "";
          DeviceAllow = "";
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          NoNewPrivileges = true;

          PrivateTmp = true;
          PrivateDevices = true;
          PrivateUsers = true;

          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = "read-only";
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectProc = "noaccess";
          ProtectSystem = "strict";

          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;

          SystemCallArchitectures = "native";
          SystemCallErrorNumber = "EPERM";
          SystemCallFilter = [
            "@system-service"
            "~@cpu-emulation"
            "~@debug"
            "~@keyring"
            "~@memlock"
            "~@obsolete"
            "~@privileged"
            "~@setuid"
          ];
        };
    };

    users.users = lib.mkIf (cfg.user == "pterodactyl-wings") {
      ${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.rootDir;
        extraGroups = lib.optional (cfg.containerRuntime == "docker") "docker";
      };
    };

    users.groups = lib.mkIf (cfg.group == "pterodactyl-wings") {
      ${cfg.group} = { };
    };
  };
}
