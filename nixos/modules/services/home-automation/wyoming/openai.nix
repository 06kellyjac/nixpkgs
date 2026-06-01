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
    literalExpression
    mkOption
    mkEnableOption
    mkPackageOption
    types
    ;

  inherit (builtins)
    toString
    ;

  inherit (utils)
    escapeSystemdExecArgs
    ;
in

{
  options.services.wyoming.openai = with types; {
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

              uri = mkOption {
                type = strMatching "^(tcp|unix)://.*$";
                example = "tcp://0.0.0.0:10200";
                description = ''
                  URI to bind the wyoming server to.
                '';
              };

              stt-models = mkOption {
                type = listOf str;
                default = [ ];
                description = ''
                  List of models to use for the STT service.
                '';
              };

              stt-streaming-models = mkOption {
                type = listOf str;
                default = [ ];
                description = ''
                  List of STT models that support streaming (e.g.
                  `gpt-4o-transcribe` `gpt-4o-mini-transcribe`). Only these
                  models will use streaming mode.
                '';
              };

              stt-realtime-streaming-models = mkOption {
                type = listOf str;
                default = [ ];
                description = ''
                  List of STT models that use OpenAI Realtime transcription
                  sessions (e.g. `gpt-realtime-whisper` `gpt-4o-transcribe`
                  `gpt-4o-mini-transcribe whisper-1`). These models stream audio
                  over `/v1/realtime` and emit Wyoming `TranscriptChunk` deltas
                  before the final transcript.

                  Not commonly supported by community projects.
                '';
              };

              stt-backend = mkOption {
                type = nullOr str;
                default = null;
                description = ''
                  Enable unofficial API feature sets.
                '';
              };

              tts-models = mkOption {
                type = listOf str;
                default = [ ];
                description = ''
                  List of models to use for the TTS service.
                '';
              };

              tts-voices = mkOption {
                type = listOf str;
                default = [ ];
                description = ''
                  List of models to use for the STT service.
                '';
              };

              tts-backend = mkOption {
                type = nullOr str;
                default = null;
                description = ''
                  Enable unofficial API feature sets.
                '';
              };

              tts-streaming-models = mkOption {
                type = listOf str;
                default = [ ];
                description = ''
                  List of TTS models to enable incremental streaming via [pySBD](https://github.com/nipunsadvilkar/pySBD)
                  sentence chunking that powers the TTS streaming pipeline
                  (e.g. `tts-1`) with up to three concurrent synthesis requests.
                '';
              };

              extraArgs = mkOption {
                type = listOf str;
                default = [ ];
                description = ''
                  Extra arguments to pass to the server commandline.
                '';
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
            ExecStart = escapeSystemdExecArgs (
              [
                (lib.getExe cfg.package)
                "--uri"
                options.uri
              ]
              ++ lib.optionals (options.stt-models != null) [
                "--stt-models"
                (lib.concatStringsSep " " options.stt-models)
              ]
              ++ lib.optionals (options.stt-streaming-models != null) [
                "--stt-streaming-models"
                (lib.concatStringsSep " " options.stt-streaming-models)
              ]
              ++ lib.optionals (options.stt-streaming-models != null) [
                "--stt-streaming-models"
                (lib.concatStringsSep " " options.stt-streaming-models)
              ]
              ++ lib.optionals (options.stt-backend != null) [
                "--stt-backend"
                options.stt-backend
              ]
              ++ lib.optionals (options.tts-models != null) [
                "--tts-models"
                (lib.concatStringsSep " " options.tts-models)
              ]
              ++ lib.optionals (options.tts-voices != null) [
                "--tts-voices"
                (lib.concatStringsSep " " options.tts-voices)
              ]
              ++ lib.optionals (options.tts-streaming-models != null) [
                "--tts-streaming-models"
                (lib.concatStringsSep " " options.tts-streaming-models)
              ]
              ++ lib.optionals (options.tts-backend != null) [
                "--tts-backend"
                options.tts-backend
              ]
              ++ options.extraArgs
            );
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
