{
  lib,
  buildDartApplication,
  fetchFromGitHub,
  runCommand,
  yq-go,
  _experimental-update-script-combinators,
  gitUpdater,
}:

let
  version = "3.2.1";

  src = fetchFromGitHub {
    owner = "leoafarias";
    repo = "fvm";
    tag = version;
    hash = "sha256-i7sJRBrS5qyW8uGlx+zg+wDxsxgmolTMcikHyOzv3Bs=";
  };
in
buildDartApplication {
  pname = "fvm";
  inherit version src;

  pubspecLock = lib.importJSON ./pubspec.lock.json;

  passthru = {
    pubspecSource =
      runCommand "pubspec.lock.json"
        {
          inherit src;
          nativeBuildInputs = [ yq-go ];
        }
        ''
          yq eval --output-format=json --prettyPrint $src/pubspec.lock > "$out"
        '';
    updateScript = _experimental-update-script-combinators.sequence [
      (gitUpdater { })
      (_experimental-update-script-combinators.copyAttrOutputToFile "fvm.pubspecSource" ./pubspec.lock.json)
    ];
  };

  meta = {
    description = "Simple CLI to manage Flutter SDK versions";
    homepage = "https://github.com/leoafarias/fvm";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
  };
}
