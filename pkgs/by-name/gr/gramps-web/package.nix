{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation rec {
  pname = "gramps-web";
  version = "25.2.0";

  src = fetchFromGitHub {
    owner = "gramps-project";
    repo = "gramps-web";
    rev = "v${version}";
    hash = "sha256-/GaQ58rQwPJ/jZRrZ7ABydMGKCfLI92XkuyKsmP187I=";
  };

  meta = {
    description = "Open Source Online Genealogy System";
    homepage = "https://github.com/gramps-project/gramps-web";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "gramps-web";
    platforms = lib.platforms.all;
  };
}
