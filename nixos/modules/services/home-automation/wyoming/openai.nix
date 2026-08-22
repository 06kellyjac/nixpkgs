{
  config,
  lib,
  pkgs,
  utils,
  ...
}:

let
  cfg = config.services.wyoming.openai;

  inherit (lib)
    mkOption
    mkEnableOption
    mkPackageOption
    types
    ;

  inherit (utils)
    escapeSystemdExecArgs
    ;

  backendsType = types.nullOr (
    types.enum [
      "OPENAI"
      "SPEACHES"
      "KOKORO_FASTAPI"
      "LOCALAI"
    ]
  );

  flagsType =
    with lib.types;
    nullOr (oneOf [
      nonEmptyStr
      (listOf nonEmptyStr)
    ]);
in

{
  options.services.wyoming.openai = {
    package = mkPackageOption pkgs "wyoming-openai" { };

    servers = mkOption {
      default = { };
      description = ''
        Attribute set of wyoming-openai instances to spawn.
      '';
      type = types.attrsOf (
        types.submodule (
          { name, ... }:
          {
            options = {
              enable = mkEnableOption "Wyoming OpenAI proxy server";

              flags = lib.mkOption {
                type = types.submodule {
                  # undefined flags
                  freeformType = types.attrsOf flagsType;

                  options = {
                    uri = mkOption {
                      type = types.strMatching "^(tcp|unix)://.*$";
                      example = "tcp://0.0.0.0:10200";
                      description = ''
                        URI to bind the wyoming server to.
                      '';
                    };

                    log-level = mkOption {
                      type = types.nullOr (
                        types.enum [
                          "DEBUG"
                          "INFO"
                          "WARNING"
                          "ERROR"
                          "CRITICAL"
                        ]
                      );
                      default = null;
                      example = "DEBUG";
                      description = ''
                        Logging level.
                      '';
                    };

                    languages = mkOption {
                      type = types.listOf types.str;
                      default = [ ];
                      example = [
                        "en"
                        "fr"
                      ];
                      description = ''
                        List of languages supported by both STT and TTS.
                        If you need different languages for each you can define
                        separate wyoming-openai configs for now.
                      '';
                    };

                    stt-backend = mkOption {
                      type = backendsType;
                      default = null;
                      description = ''
                        Backend for speech-to-text.
                      '';
                    };

                    stt-models = mkOption {
                      type = types.listOf types.str;
                      default = [ ];
                      description = ''
                        List of models to use for the STT service.
                      '';
                    };

                    stt-streaming-models = mkOption {
                      type = types.listOf types.str;
                      default = [ ];
                      description = ''
                        List of STT model identifiers that support streaming (e.g.
                        `gpt-4o-transcribe` `gpt-4o-mini-transcribe`). Only these
                        models will use streaming mode.
                      '';
                    };

                    stt-realtime-streaming-models = mkOption {
                      type = types.listOf types.str;
                      default = [ ];
                      description = ''
                        List of STT model identifiers that use OpenAI Realtime
                        transcription (e.g. `gpt-realtime-whisper`). These models
                        stream audio over `/v1/realtime` and emit Wyoming
                        `TranscriptChunk` deltas before the final transcript.

                        Not commonly supported by community projects.
                      '';
                    };

                    tts-backend = mkOption {
                      type = backendsType;
                      default = null;
                      description = ''
                        Backend for speech-to-text.
                      '';
                    };

                    tts-voices = mkOption {
                      type = types.listOf types.str;
                      default = [ ];
                      description = ''
                        List of available TTS voices.
                      '';
                    };

                    tts-models = mkOption {
                      type = types.listOf types.str;
                      default = [ ];
                      description = ''
                        List of models to use for the TTS service.
                      '';
                    };

                    tts-streaming-models = mkOption {
                      type = types.listOf types.str;
                      default = [ ];
                      description = ''
                        List of TTS models to enable incremental streaming via
                        [pySBD](https://github.com/nipunsadvilkar/pySBD) sentence
                        chunking that powers the TTS streaming pipeline (e.g.
                        `tts-1`) with up to three concurrent synthesis requests.
                      '';
                    };
                  };
                };
              };
            };
          }
        )
      );
    };
  };

  config =
    let
      inherit (lib)
        mapAttrs'
        mkIf
        nameValuePair
        ;
    in
    mkIf (cfg.servers != { }) {
      systemd.services = mapAttrs' (
        server: options:
        nameValuePair "wyoming-openai-${server}" {
          inherit (options) enable;
          description = "Wyoming OpenAI server instance ${server}";
          wants = [
            "network-online.target"
          ];
          after = [
            "network-online.target"
          ];
          wantedBy = [
            "multi-user.target"
          ];
          serviceConfig = {
            DynamicUser = true;
            User = "wyoming-openai";
            StateDirectory = [ "wyoming/openai" ];
            ExecStart =
              let
                flagsToArgs =
                  flags:
                  lib.concatLists (
                    lib.mapAttrsToList (
                      name: value:
                      # wyoming-openai doesn't split string arguments by space
                      # it wants raw values to follow a flag so:
                      # `--languages "en fr"` would not work
                      # `--languages en fr` or `--languages "en" "fr"` would work
                      # flagsToArgs = lib.mapAttrsToList (
                      #   name: value: if value == null then "--${name}" else "--${name} ${value}"
                      # ) cfg.flags;
                      if builtins.isList value then
                        if lib.length value == 0 then [ ] else [ "--${name}" ] ++ value
                      else if builtins.isString value then
                        if builtins.stringLength == 0 then
                          [ ]
                        else
                          [
                            "--${name}"
                            value
                          ]
                      else if value == null then
                        [ ]
                      else
                        throw "Unexpected type for flag '${name}': ${builtins.typeOf value}"
                    ) flags
                  );
              in
              lib.concatStringsSep " " [
                (lib.getExe cfg.package)
                (escapeSystemdExecArgs (
                  (flagsToArgs options.flags)
                  # [
                  #   (lib.getExe cfg.package)
                  #   "--uri"
                  #   options.uri
                  # ]
                  # ++ lib.optionals (options.stt-models != null) [
                  #   "--stt-models"
                  #   (lib.concatStringsSep " " options.stt-models)
                  # ]
                  # ++ lib.optionals (options.stt-streaming-models != null) [
                  #   "--stt-streaming-models"
                  #   (lib.concatStringsSep " " options.stt-streaming-models)
                  # ]
                  # ++ lib.optionals (options.stt-streaming-models != null) [
                  #   "--stt-streaming-models"
                  #   (lib.concatStringsSep " " options.stt-streaming-models)
                  # ]
                  # ++ lib.optionals (options.stt-backend != null) [
                  #   "--stt-backend"
                  #   options.stt-backend
                  # ]
                  # ++ lib.optionals (options.tts-models != null) [
                  #   "--tts-models"
                  #   (lib.concatStringsSep " " options.tts-models)
                  # ]
                  # ++ lib.optionals (options.tts-voices != null) [
                  #   "--tts-voices"
                  #   (lib.concatStringsSep " " options.tts-voices)
                  # ]
                  # ++ lib.optionals (options.tts-streaming-models != null) [
                  #   "--tts-streaming-models"
                  #   (lib.concatStringsSep " " options.tts-streaming-models)
                  # ]
                  # ++ lib.optionals (options.tts-backend != null) [
                  #   "--tts-backend"
                  #   options.tts-backend
                  # ]
                  # ++ options.extraArgs
                ))
              ];
            CapabilityBoundingSet = "";
            DeviceAllow = "";
            DevicePolicy = "closed";
            LockPersonality = true;
            MemoryDenyWriteExecute = true;
            PrivateDevices = true;
            PrivateUsers = true;
            ProtectHome = true;
            ProtectHostname = true;
            ProtectKernelLogs = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            ProtectControlGroups = true;
            ProtectProc = "invisible";
            ProcSubset = "pid";
            RestrictAddressFamilies = [
              "AF_INET"
              "AF_INET6"
              "AF_UNIX"
            ];
            RestrictNamespaces = true;
            RestrictRealtime = true;
            SystemCallArchitectures = "native";
            SystemCallFilter = [
              "@system-service"
              "~@privileged"
            ];
            UMask = "0077";
          };
        }
      ) cfg.servers;
    };
}
