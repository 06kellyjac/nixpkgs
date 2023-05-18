let
  pkgs = import ../../../../../. { };
  inherit (pkgs) lib;
  # process that structure from
  # [
  #   {
  #     "commit": "commit1",
  #     "files": [
  #       "<PATH>"
  #     ]
  #   },
  #   {
  #     "commit": "commit2",
  #     "files": [
  #       "<PATH>"
  #       "<PATH3>"
  #     ]
  #   },
  #   {
  #     "commit": "commit1",
  #     "files": [
  #       "<PATH2>"
  #     ]
  #   },
  #   {
  #     "commit": "commit2",
  #     "files": [
  #       "<PATH2>"
  #     ]
  #   }
  # ]
  # to
  # {
  #   "commit1": {
  #     "file_name": "<PATH>",
  #     "file_name2": "<PATH2>",
  #   },
  #   "commit2": {
  #     "file_name": "<PATH1>",
  #     "file_name2": "<PATH2>",
  #     "file_name3": "<PATH3>",
  #   }
  # }
  drvsThatRequireFiles = lib.listToAttrs (builtins.map (v: { name = v.commit; value = v.files; }) (lib.mapAttrsToList (_: v: v.passthru.lbRequirements)
    # filter for derivations that have .passthru.lbRequirements marking desired files
    (lib.filterAttrs (n: v: (builtins.typeOf v == "set" && builtins.hasAttr "passthru" v && builtins.hasAttr "lbRequirements" v.passthru)) pkgs.minimal-bootstrap)));
  # process that structure from
  # {
  #   "commit1": {
  #     "file_name": "<PATH>",
  #     "file_name2": "<PATH2>",
  #   },
  #   "commit2": {
  #     "file_name": "<PATH1>",
  #     "file_name2": "<PATH2>",
  #     "file_name3": "<PATH3>",
  #   }
  # }
  # to
  # {
  #   "commit1": {
  #     "files": [
  #       "<PATH1>"
  #       "<PATH2>"
  #     ]
  #   },
  #   "commit2": {
  #     "files": [
  #       "<PATH1>"
  #       "<PATH2>"
  #       "<PATH3>"
  #     ]
  #   }
  # }
  drvsB = lib.mapAttrs (n: v: { files = (lib.mapAttrsToList (_: v: v) v); }) drvsThatRequireFiles;
in
# a
  # builtins.hasAttr "passthru" pkgs.minimal-bootstrap.gnutar && builtins.hasAttr "live-bootstrap" pkgs.minimal-bootstrap.gnutar.passthru
drvsB
# (builtins.hasAttr "passthru" v && builtins.hasAttr "live-bootstrap" v.passthru) ==
