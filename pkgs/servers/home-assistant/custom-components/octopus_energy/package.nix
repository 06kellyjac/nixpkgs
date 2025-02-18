{
  lib,
  fetchFromGitHub,
  buildHomeAssistantComponent,
  pydantic,
}:

buildHomeAssistantComponent rec {
  owner = "bottlecapdave";
  domain = "octopus_energy";
  version = "15.2.0";

  src = fetchFromGitHub {
    owner = "BottlecapDave";
    repo = "HomeAssistant-OctopusEnergy";
    tag = "v${version}";
    hash = "sha256-GZerFoS1SQFCM2aLvyV0zOgighsnV/o3vdz2vNzDx+8=";
  };

  dependencies = [ pydantic ];

  dontBuild = true;

  meta = {
    changelog = "https://github.com/BottlecapDave/HomeAssistant-OctopusEnergy/blob/${version}/CHANGELOG.md";
    homepage = "https://bottlecapdave.github.io/HomeAssistant-OctopusEnergy/";
    description = "Home Assistant integration for interacting with Octopus Energy";
    maintainers = with lib.maintainers; [ jk ];
    license = lib.licenses.mit;
  };
}
