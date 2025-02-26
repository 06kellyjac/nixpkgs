{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  wheel,

  intltool,
}:

buildPythonPackage rec {
  pname = "gramps";
  version = "5.2.4";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "gramps-project";
    repo = "gramps";
    rev = "v${version}";
    hash = "sha256-Jue5V4pzfd1MaZwEhkGam+MhNjaisio7byMBPgGmiFg=";
  };

  build-system = [
    setuptools
    wheel
  ];

  nativeBuildInputs = [
    intltool
    # wrapGAppsHook3
    # intltool
    # gettext
    # gobject-introspection
    # python3Packages.setuptools
  ];

  pythonImportsCheck = [ "gramps" ];

  meta = {
    description = "Source code for Gramps Genealogical program";
    homepage = "https://github.com/gramps-project/gramps";
    changelog = "https://github.com/gramps-project/gramps/blob/${src.rev}/ChangeLog";
    license = lib.licenses.gpl2Only;
    maintainers = with lib.maintainers; [ ];
  };
}
