{ config, lib, pkgs, ... }:

let
  inherit (lib) types;
  cfg = config.security.pam.pwquality;
in
{
  options = {
    security.pam.pwquality = {
      enable = lib.mkEnableOption (lib.mdDoc "Enable PAM pwquality system to enforce complex passwords.");

      package = lib.mkPackageOption pkgs "libpwquality" { };

      settings = mkOption {
        description = mdDoc ''
          Config options for the /etc/login.defs file, that defines
          the site-specific configuration for the shadow password suite.
          See login.defs(5) man page for available options.
        '';
        type = submodule {
          freeformType = (pkgs.formats.keyValue { }).type;
          options = {
            difok = lib.mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "1";
              description = lib.mdDoc ''
                Number of characters in the new password that must not be present in
                the old password.

                The special value of `0` disables all checks of similarity of the new
                password with the old password except the new password being exactly
                the same as the old one.
              '';
            };

            minlen = lib.mkOption {
              type = types.nullOr (
                types.addCheck types.int (x: x >= 6) // {
                  name = "positiveIntMinSix";
                  description = "positive integer >= 6";
                }
              );
              default = null;
              example = 8;
              description = lib.mdDoc ''
                Minimum acceptable size for the new password (plus one if credits are
                not disabled which is the default).
                (See {manpage}`refentrytitle(8)`.)

                Cannot be set to lower value than 6.
              '';
            };

            dcredit = lib.mkOption {
              type = types.nullOr types.int;
              default = null;
              example = 0;
              description = lib.mdDoc ''
                The maximum credit for having digits in the new password. If less than
                0 it is the minimum number of digits in the new password.
              '';
            };

            ucredit = lib.mkOption {
              type = types.nullOr types.int;
              default = null;
              example = 0;
              description = lib.mdDoc ''
                The maximum credit for having uppercase characters in the new
                password. If less than `0` it is the minimum number of uppercase
                characters in the new password.
              '';
            };

            lcredit = lib.mkOption {
              type = types.nullOr types.int;
              default = null;
              example = 0;
              description = lib.mdDoc ''
                The maximum credit for having lowercase characters in the new
                password. If less than 0 it is the minimum number of lowercase
                characters in the new password.
              '';
            };

            ocredit = lib.mkOption {
              type = types.nullOr types.int;
              default = null;
              example = 0;
              description = lib.mdDoc ''
                The maximum credit for having other characters in the new password. If
                less than `0` it is the minimum number of other characters in the new
                password.
              '';
            };

            minclass = lib.mkOption {
              type = types.nullOr types.int;
              default = null;
              example = 0;
              description = lib.mdDoc ''
                The minimum number of required classes of characters for the new
                password (digits, uppercase, lowercase, others).
              '';
            };

            maxrepeat = lib.mkOption {
              type = types.nullOr types.ints.unsigned;
              default = null;
              example = 0;
              description = lib.mdDoc ''
                The maximum number of allowed same consecutive characters in the new
                password. The check is disabled if the value is `0`.
              '';
            };

            maxsequence = lib.mkOption {
              type = types.nullOr types.ints.unsigned;
              default = null;
              example = 0;
              description = lib.mdDoc ''
                The maximum length of monotonic character sequences in the new
                password. Examples of such sequence are `12345` or `fedcb`. Note that
                most such passwords will not pass the simplicity check unless the
                sequence is only a minor part of the password. The check is disabled
                if the value is `0`.
              '';
            };

            maxclassrepeat = lib.mkOption {
              type = types.nullOr types.ints.unsigned;
              default = null;
              example = 0;
              description = lib.mdDoc ''
                The maximum number of allowed consecutive characters of the same class
                in the new password. The check is disabled if the value is `0`.
              '';
            };

            gecoscheck = lib.mkOption {
              type = types.nullOr types.ints.unsigned;
              default = null;
              example = 0;
              description = lib.mdDoc ''
                If nonzero, check whether the words longer than `3` characters from
                the *GECOS* field of the user's {manpage}`passwd(5)` entry are
                contained in the new password. The check is disabled if the value is
                `0`.
              '';
            };

            dictcheck = lib.mkOption {
              type = types.nullOr types.ints.unsigned;
              default = null;
              example = 1;
              description = lib.mdDoc ''
                If nonzero, check whether the password (with possible modifications)
                matches a word in a dictionary. Currently the dictionary check is
                performed using the cracklib library.
              '';
            };

            usercheck = lib.mkOption {
              type = types.nullOr types.ints.unsigned;
              default = null;
              example = 1;
              description = lib.mdDoc ''
                If nonzero, check whether the password (with possible modifications)
                contains the user name in some form. It is not performed for user
                names shorter than `3` characters.
              '';
            };

            usersubstr = lib.mkOption {
              type = types.nullOr types.ints.unsigned;
              default = null;
              example = 0;
              description = lib.mdDoc ''
                If greater than `3` (due to the minimum length in usercheck), check
                whether the password contains a substring of at least *N* length in
                some form.
              '';
            };

            enforcing = lib.mkOption {
              type = types.nullOr types.ints.unsigned;
              default = null;
              example = 1;
              description = lib.mdDoc ''
                If nonzero, reject the password if it fails the checks, otherwise only
                print the warning. This setting applies only to the `pam_pwquality`
                module and possibly other applications that explicitly change their
                behavior based on it. It does not affect {manpage}`pwmake(1)` and
                {manpage}`pwscore(1)`
              '';
            };

            badwords = lib.mkOption {
              type = types.nullOr (types.listOf types.str);
              default = null;
              example = [ "password" "pass" "hunter42" ];
              description = lib.mdDoc ''
                A list of words that must not be contained in the password. These are
                additional words to the cracklib dictionary check. This setting can be
                also used by applications to emulate the gecos check for user accounts
                that are not created yet.
              '';
            };

            dictpath = lib.mkOption {
              type = types.nullOr types.path;
              default = null;
              example = "/usr/local/lib/pw_dict";
              description = lib.mdDoc ''
                Path to the cracklib dictionaries. Default is to use the cracklib
                default.
              '';
            };

            retry = lib.mkOption {
              type = types.nullOr types.ints.unsigned;
              default = null;
              example = 1;
              description = lib.mdDoc ''
                Prompt user at most *N* times before returning with error.
              '';
            };

            enforce_for_root = lib.mkOption {
              type = types.nullOr types.bool;
              default = null;
              description = lib.mdDoc ''
                The module will return error on failed check even if the user changing
                the password is root. This option is off by default which means that
                just the message about the failed check is printed but root can change
                the password anyway. Note that root is not asked for an old password
                so the checks that compare the old and new password are not performed.
              '';
            };

            local_users_only = lib.mkOption {
              type = types.nullOr types.bool;
              default = null;
              description = lib.mdDoc ''
                The module will not test the password quality for users that are not
                present in the {file}`/etc/passwd` file. The module still asks for the
                password so the following modules in the stack can use the
                {option}`security.pam.pwquality.config.use_authtok` option.
              '';
            };
          };
        };
        default = { };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.libpwquality ];
    environment.etc."security/pwquality.conf".source =
      pkgs.writeText
        "pwquality.conf"
        (toKeyValue cfg.settings);
    # (lib.concatMapStrings
    #   (x: x + "\n")
    #   (lib.mapAttrsToList
    #     (name: value: if (builtins.typeOf value) == "bool" then name else "${name} = ${builtins.toString value}")
    #     (lib.filterAttrs (k: v: v != null) (removeAttrs cfg [ "enable" "package" ]))
    #   ));
  };
}
