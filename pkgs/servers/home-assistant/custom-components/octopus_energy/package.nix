{
  lib,
  fetchFromGitHub,
  buildHomeAssistantComponent,
  pydantic,
}:

buildHomeAssistantComponent rec {
  owner = "bottlecapdave";
  domain = "octopus_energy";
  version = "14.0.2";

  src = fetchFromGitHub {
    owner = "BottlecapDave";
    repo = "HomeAssistant-OctopusEnergy";
    tag = "v${version}";
    hash = "sha256-gK6Mh3yz2Gf0c8OE+jnrGx2xwf1zYO8MJVOYvAMIrZQ=";
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
