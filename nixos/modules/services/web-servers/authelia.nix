{ lib
, pkgs
, config
, ...
}:

let
  cfg = config.services.authelia;

  format = pkgs.formats.yaml { };
  configFile = format.generate "config.yml" cfg.settings;

  autheliaOpts = with lib; { name, ... }: {
    options = {
      enable = mkEnableOption "Authelia instance";

      name = mkOption {
        type = types.str;
        default = name;
      };

      package = mkOption {
        default = pkgs.authelia;
        type = types.package;
        defaultText = literalExpression "pkgs.authelia";
      };

      user = mkOption {
        default = "authelia-${name}";
        type = types.str;
      };
      group = mkOption {
        default = "authelia-${name}";
        type = types.str;
      };

      jwtSecretFile = mkOption {
        type = types.path;
        default = null;
        description = ''
          Path to your JWT secret used during identity verificaiton.
        '';
      };

      oidcIssuerPrivateKeyFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          Path to your private key file used to encrypt OIDC JWTs.
        '';
      };

      oidcHmacSecretFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          Path to your HMAC secret used to sign OIDC JWTs.
        '';
      };

      sessionSecretFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          Path to your session secret. Only used when redis is used as session storage.
        '';
      };

      storageEncryptionKeyFile = mkOption {
        type = types.path;
        default = null;
        description = ''
          Path to your storage encryption key.
        '';
      };

      settings = mkOption {
        description = ''
          Your Authelia config.yml as a Nix attribute set.

          https://github.com/authelia/authelia/blob/master/config.template.yml
        '';
        default = { };
        type = types.submodule {
          freeformType = format.type;
          options = {
            default_2fa_method = mkOption {
              type = types.enum [ "" "totp" "webauthn" "mobile_push" ];
              default = "";
              example = "webauthn";
              description = ''
                Default 2FA method for new users and fallback for preferred but disabled methods.
              '';
            };

            server = {
              host = mkOption {
                type = types.str;
                default = "localhost";
                example = "0.0.0.0";
                description = ''
              '';
              };

              port = mkOption {
                type = types.port;
                default = 9091;
                description = ''
              '';
              };
            };

            log = {
              level = mkOption {
                type = types.enum [ "info" "debug" "trace" ];
                default = "info";
                example = "debug";
                description = ''
              '';
              };
            };
          };
        };
      };
    };
  };
in
{
  options.services.authelia.instances = with lib; mkOption {
    default = { };
    type = types.attrsOf (types.submodule autheliaOpts);
  };

  config =
    let
      mkInstanceServiceConfig = instance: {
        description = "Authelia authentication and authorization server";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          User = instance.user;
          Group = instance.group;
          ExecStart = "${instance.package}/bin/authelia --config ${format.generate "config.yml" instance.settings}";
        };
        environment = {
          AUTHELIA_JWT_SECRET_FILE = instance.jwtSecretFile;
          AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE = instance.storageEncryptionKeyFile;
        } // lib.optionalAttrs (instance.sessionSecretFile != null) {
          AUTHELIA_SESSION_SECRET_FILE = instance.sessionSecretFile;
        } // lib.optionalAttrs (instance.oidcIssuerPrivateKeyFile != null) {
          AUTHELIA_IDENTITY_PROVIDERS_OIDC_ISSUER_PRIVATE_KEY_FILE = instance.oidcIssuerPrivateKeyFile;
          AUTHELIA_IDENTITY_PROVIDERS_OIDC_HMAC_SECRET_FILE = instance.oidcHmacSecretFile;
        };
      };
      mkInstanceUsersConfig = instance: {
        groups."authelia-${instance.name}" =
          lib.mkIf (instance.group == "authelia-${instance.name}") {
            name = "authelia-${instance.name}";
          };
        users."authelia-${instance.name}" =
          lib.mkIf (instance.user == "authelia-${instance.name}") {
            name = "authelia-${instance.name}";
            isSystemUser = true;
            group = instance.group;
          };
      };
      instances = builtins.attrValues cfg.instances;
    in
    {
      systemd.services = lib.mkMerge
        (map
          (instance: lib.mkIf instance.enable {
            "authelia-${instance.name}" = mkInstanceServiceConfig instance;
          })
          instances);
      users = lib.mkMerge
        (map
          (instance: lib.mkIf instance.enable (mkInstanceUsersConfig instance))
          instances);
    };
}
