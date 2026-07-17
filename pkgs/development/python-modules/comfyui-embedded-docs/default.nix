{
  lib,
  buildPythonPackage,
  fetchPypi,

  setuptools,

  unittestCheckHook,
}:

buildPythonPackage rec {
  pname = "comfyui-embedded-docs";
  version = "0.5.8";
  pyproject = true;

  # no tags on github
  src = fetchPypi {
    pname = "comfyui_embedded_docs";
    inherit version;
    hash = "sha256-w6fGpXHcTkx7Ur5qAw3kts2ZaNxqneLqKmd2/A5BjwU=";
  };
  build-system = [ setuptools ];

  pythonImportsCheck = [ "comfyui_embedded_docs" ];

  meta = {
    description = "Embedded documentation for ComfyUI nodes";
    homepage = "https://github.com/Comfy-Org/embedded-docs/";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [
      jk
    ];
  };
}
