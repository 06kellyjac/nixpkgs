{
  lib,
  fetchFromGitHub,
  buildPythonPackage,
  pythonOlder,

  setuptools,

  pyparsing,
  torch,
  transformers,
  diffusers,
}:
buildPythonPackage rec {
  pname = "compel";
  version = "2.1.1";
  pyproject = true;
  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "damian0815";
    repo = "compel";
    rev = version;
    hash = "sha256-n/UVWe4EuP4gWl4j/H5q+u1IXHxfzXbJNNZxb0aXABA=";
  };

  build-system = [ setuptools ];

  dependencies = [
    pyparsing
    torch
    transformers
    diffusers
  ];

  pythonImportsCheck = [ "compel" ];

  # has tests dir but `unittestCheckHook` doesn't run them

  meta = {
    description = "Prompting enhancement library for transformers-type text embedding systems";
    homepage = "https://github.com/damian0815/compel/";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      jk
    ];
  };
}
