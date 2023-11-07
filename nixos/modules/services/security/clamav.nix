{ config, lib, pkgs, ... }:
let
  inherit (lib) types;

  cfg = config.services.clamav;
  pkg = cfg.package;

  targetOpts = { name, config, ... }: {
    config.name = lib.mkDefault name;
    options = {
      name = lib.mkOption {
        type = types.str;
        # defaulted to the target attribute name
        description = lib.mdDoc "The name of this monitoring target.";
      };

      monitorAccess = lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Whether the paths in this monitoring target should be actively monitored by `clamonacc`.";
      };

      scanInterval = lib.mkOption {
        type = types.str;
        default = "weekly";
        description = lib.mdDoc "How frequently to scan the paths in this monitoring target.";
      };

      paths = lib.mkOption {
        type = types.listOf types.path;
        example = [ "/home/alice/Documents" "/home/alice/Downloads" ];
        default = null;
        description = lib.mdDoc ''
          Provide a list of paths to be monitored as part of this monitoring target.
        '';
      };
    };
  };

  toKeyValue = lib.generators.toKeyValue {
    mkKeyValue = lib.generators.mkKeyValueDefault { } " ";
    listsAsDuplicateKeys = true;
  };

  clamdConfigFile = pkgs.writeText "clamd.conf" (toKeyValue cfg.daemon.settings);
  freshclamConfigFile = pkgs.writeText "freshclam.conf" (toKeyValue cfg.updater.settings);

  notify-self = pkgs.writeShellScript "notify-self-of-virus-event" ''
    set -Eeuo pipefail

    echo "monitoring clamav logs for viruses found"

    journalctl --lines 0 --output cat --output-fields=MESSAGE --since now --follow --unit clamav-daemon.service |
      while IFS= read -r LINE; do
        if [[ "$LINE" =~ .*FOUND$ ]]; then
          CLAM_VIRUSEVENT_VIRUSNAME=$(echo "$LINE" | ${pkgs.busybox}/bin/awk '{ print $(NF-1) }')
          CLAM_VIRUSEVENT_FILENAME=$(echo "$LINE" | ${pkgs.busybox}/bin/awk '{ print substr($(NF-2), 1, length($(NF-2))-1) }')
          CLAM_VIRUSEVENT_DATE=$(echo "$LINE" | ${pkgs.busybox}/bin/awk -F ' -> ' '{ print $(1) }')

          ALERT="Virus found in $CLAM_VIRUSEVENT_FILENAME on $CLAM_VIRUSEVENT_DATE - Signature detected by clamav: $CLAM_VIRUSEVENT_VIRUSNAME"
          echo "Pushing notification - $ALERT"

          # called from a user systemd service we will have DBUS_SESSION_BUS_ADDRESS set
          ${pkgs.libnotify}/bin/notify-send --urgency critical -i dialog-warning "Virus found!" "$ALERT"
        fi
      done
  '';
in
{
  imports = [
    (lib.mkRemovedOptionModule [ "services" "clamav" "updater" "config" ] "Use services.clamav.updater.settings instead.")
    (lib.mkRemovedOptionModule [ "services" "clamav" "updater" "extraConfig" ] "Use services.clamav.updater.settings instead.")
    (lib.mkRemovedOptionModule [ "services" "clamav" "daemon" "extraConfig" ] "Use services.clamav.daemon.settings instead.")
  ];

  options = {
    services.clamav = {
      enable = lib.mkEnableOption (lib.mdDoc "ClamAV");

      package = lib.mkOption {
        type = types.package;
        default = pkgs.clamav;
        defaultText = lib.literalExpression "pkgs.clamav";
        description = lib.mdDoc ''
          The `clamav` derivation to use. Useful to override
          configuration options used for the package.
        '';
      };

      user = lib.mkOption {
        type = types.str;
        default = "clamav";
        example = "clamantivirus";
        description = lib.mdDoc ''
          The name of the clamav user
        '';
      };

      group = lib.mkOption {
        type = types.str;
        default = cfg.user;
        example = "clamantivirus";
        description = lib.mdDoc ''
          The name of the clamav group. Defaults to match
          {options}`services.clamav.user`.
        '';
      };

      stateDir = lib.mkOption {
        type = types.path;
        default = "/var/lib/clamav";
        example = "/var/lib/clamantivirus";
        description = lib.mdDoc ''
          TODO
        '';
      };

      runDir = lib.mkOption {
        type = types.path;
        default = "/run/clamav";
        example = "/run/clamantivirus";
        description = lib.mdDoc ''
          TODO
        '';
      };

      daemon = {
        enable = lib.mkOption {
          type = types.bool;
          default = true;
          description = lib.mdDoc ''
            Whether to enable the ClamAV `clamd` daemon.
          '';
        };

        settings = lib.mkOption {
          type = with types; attrsOf (oneOf [ bool int str (listOf str) ]);
          default = { };
          description = lib.mdDoc ''
            ClamAV configuration. Refer to {manpage}`clamd.conf(5)` for details
            on supported values.
          '';
        };
      };

      updater = {
        enable = lib.mkOption {
          type = types.bool;
          default = true;
          description = lib.mdDoc ''
            Whether to enable the ClamAV `freshclam` updater.
          '';
        };

        frequency = lib.mkOption {
          type = types.int;
          default = 12;
          description = lib.mdDoc ''
            Number of database checks per day.
          '';
        };

        interval = lib.mkOption {
          type = types.str;
          default = "hourly";
          description = lib.mdDoc ''
            How often freshclam is invoked. See {manpage}`systemd.time(7)` for
            more information about the format.
          '';
        };

        settings = lib.mkOption {
          type = with types; attrsOf (oneOf [ bool int str (listOf str) ]);
          default = { };
          description = lib.mdDoc ''
            freshclam configuration. Refer to {manpage}`freshclam.conf(5)` for
            details on supported values.
          '';
        };
      };

      monitoring = {
        enable = lib.mkOption {
          type = types.bool;
          default = true;
          description = lib.mdDoc ''
            Whether to enable active monitoring and scanning for specified
            locations using `clamonacc` and `clamdscan`.

            Configure these locations via
            {option}`services.clamav.monitoring.targets`.

            Also depends on {option}`services.clamav.daemon.enable`
          '';
        };

        scanCollection = lib.mkOption {
          type = types.str;
          default = "clamav-scan";
          description = lib.mdDoc ''
            The shared journal entry to collect scan and activity logs.
          '';
        };

        notify = lib.mkOption {
          type = types.bool;
          default = true;
          description = lib.mdDoc ''
            If graphical users should see notifications upon virus
            identification.
          '';
        };

        quarantineLocation = lib.mkOption {
          type = types.nullOr types.path;
          default = null;
          example = "/root/quarantine";
          description = lib.mdDoc ''
            A location to quarantine files identified by ClamAV as dangerous.
          '';
        };

        targets = lib.mkOption {
          type = with types; attrsOf (submodule targetOpts);
          default = { };
          example = {
            mystuff = {
              monitorAccess = false;
              paths = [
                "/home/me/stuff"
                "/myotherstuff"
                "/tmp/stuff"
              ];
            };
            yourstuff = {
              scanInterval = "weekly";
              paths = [
                "/tmp/yourstuff"
                "/home/you/Stuff"
              ];
            };
          };
          description = lib.mdDoc ''
            Here you can set which locations you would like to monitor.
            These locations can be configured to be scanned on an interval and
            can be set to monitor access to these locations warning immediately
            of any potential matches.
            Access monitoring can be combined with the `OnAccessPrevention`
            ClamAV option to block access to potentially malicious files.
          '';
        };
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    (lib.mkIf (cfg.daemon.enable || cfg.updater.enable) {
      environment.systemPackages = [ pkg ];

      users.users.${cfg.user} = {
        uid = config.ids.uids.clamav;
        group = cfg.group;
        description = "ClamAV daemon user";
        home = cfg.stateDir;
      };

      users.groups.${cfg.group}.gid = config.ids.gids.clamav;
    })
    (lib.mkIf (cfg.daemon.enable) {
      services.clamav.daemon.settings = {
        DatabaseDirectory = cfg.stateDir;
        LocalSocket = "${cfg.runDir}/clamd.ctl";
        PidFile = "${cfg.runDir}/clamd.pid";
        TemporaryDirectory = "/tmp";
        User = cfg.user;
        Foreground = true;
      };

      environment.etc."clamav/clamd.conf".source = clamdConfigFile;

      systemd.services.clamav-daemon = lib.mkIf cfg.daemon.enable {
        description = "ClamAV daemon (clamd)";
        after = lib.optional cfg.updater.enable "clamav-freshclam.service";
        wantedBy = [ "multi-user.target" ];
        restartTriggers = [ clamdConfigFile ];

        preStart = ''
          mkdir -m 0755 -p ${cfg.runDir}
          chown ${cfg.user}:${cfg.group} ${cfg.runDir}
        '';

        serviceConfig = {
          ExecStart = "${pkg}/bin/clamd";
          ExecReload = "${pkgs.coreutils}/bin/kill -USR2 $MAINPID";
          PrivateTmp = "yes";
          PrivateDevices = "yes";
          PrivateNetwork = "yes";
        };
      };
    })
    (lib.mkIf (cfg.updater.enable) {
      services.clamav.updater.settings = {
        DatabaseDirectory = cfg.stateDir;
        Foreground = true;
        Checks = cfg.updater.frequency;
        DatabaseMirror = [ "database.clamav.net" ];
      };
      environment.etc."clamav/freshclam.conf".source = freshclamConfigFile;
      systemd.timers.clamav-freshclam = {
        description = "Timer for ClamAV virus database updater (freshclam)";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.updater.interval;
          Unit = "clamav-freshclam.service";
        };
      };

      systemd.services.clamav-freshclam = {
        description = "ClamAV virus database updater (freshclam)";
        restartTriggers = [ freshclamConfigFile ];
        after = [ "network-online.target" ];
        preStart = ''
          mkdir -m 0755 -p ${cfg.stateDir}
          chown ${cfg.user}:${cfg.group} ${cfg.stateDir}
        '';

        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkg}/bin/freshclam";
          SuccessExitStatus = "1"; # if databases are up to date
          PrivateTmp = "yes";
          PrivateDevices = "yes";
        };
      };
    })
    (lib.mkIf (cfg.daemon.enable && cfg.monitoring.enable) (
      let
        mkScanTimers = name: target:
          lib.nameValuePair "${cfg.monitoring.scanCollection}-${target.name}" {
            description = "ClamAV scan timer for the <${name}> target in `services.clamav.monitoring.targets`";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = target.scanInterval;
              Unit = "${cfg.monitoring.scanCollection}-${target.name}.service";
            };
          };

        mkScanServices = name: target:
          lib.nameValuePair "${cfg.monitoring.scanCollection}-${target.name}" {
            description = "ClamAV scan service for the <${name}> target in `services.clamav.monitoring.targets`";
            after = [ "network-online.target" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = ''
                ${pkg}/bin/clamdscan \
                  --wait \
                  --stdout \
                  --infected \
                  ${lib.optionalString (cfg.monitoring.quarantineLocation != null) "--move=${lib.escapeShellArg cfg.monitoring.quarantineLocation}"} \
                  --recursive \
                  --fdpass ${toString target.paths}
              '';
            };
          };

        targetsWithScanning = lib.filterAttrs (_: c: c.scanInterval != null) cfg.monitoring.targets;

        targetsToAccessIncludePath = targets:
          # squash the list of lists into a single list
          lib.flatten (
            # then just keep the files
            builtins.map (v: v.paths) (
              # keep those we want to monitor
              builtins.filter (v: v.monitorAccess)
                # turn attrset to list
                (lib.mapAttrsToList (_: v: v) targets)
            )
          );
      in
      {
        # use a user service to avoid giving clamav access to notify-send to the user
        # # allow clamav user to notify-send to other user's dbus
        # security.sudo.extraConfig = lib.mkIf cfg.monitoring.notify ''
        #   clamav ALL = (ALL) NOPASSWD: SETENV: ${pkgs.libnotify}/bin/notify-send
        # '';
        # services.clamav.daemon.settings.VirusEvent = lib.mkIf cfg.monitoring.notify "${notify-all-users}";

        systemd.user.services.clamav-notify-virus = lib.mkIf cfg.monitoring.notify {
          description = "ClamAV - Notify user of virus event";

          requires = [ "dbus.socket" "basic.target" "session.slice" ];
          after = [ "dbus.socket" "basic.target" "session.slice" ];
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          # service-name@username
          # https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html#Specifiers
          serviceConfig = {
            SyslogIdentifier = "%N@%u";
            Type = "simple";
            ExecStart = notify-self;
            Restart = "always";
          };
        };

        services.clamav.daemon.settings.OnAccessIncludePath = targetsToAccessIncludePath cfg.monitoring.targets;

        systemd.services = {
          clamav-clamonacc = {
            description = "ClamAV daemon (clamonacc)";
            after = [ "clamav-freshclam.service" "clamav-daemon.service" ];
            wantedBy = [ "multi-user.target" ];
            restartTriggers = [ "/etc/clamav/clamd.conf" ];

            serviceConfig = {
              Type = "simple";
              ExecStart = ''
                ${pkg}/bin/clamonacc \
                  --wait \
                  --foreground \
                  ${lib.optionalString (cfg.monitoring.quarantineLocation != null) "--move=${lib.escapeShellArg cfg.monitoring.quarantineLocation}"} \
                  --fdpass
              '';
              PrivateTmp = "yes";
              PrivateDevices = "yes";
              PrivateNetwork = "yes";
            };
          };
        } // lib.mapAttrs' mkScanServices targetsWithScanning;

        systemd.timers = lib.mapAttrs' mkScanTimers targetsWithScanning;
      }
    ))
  ]);
}
