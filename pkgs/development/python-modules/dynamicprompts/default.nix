{
  lib,
  fetchFromGitHub,
  buildPythonPackage,
  pythonOlder,

  hatchling,

  pyparsing,
  jinja2,

  # optional
  transformers,
  requests,
  pyyaml,

  pytest-cov,
  pytest-lazy-fixture,

  pytestCheckHook,
}:
buildPythonPackage rec {
  pname = "dynamicprompts";
  version = "0.31.0";
  pyproject = true;
  disabled = pythonOlder "3.8";

  src = fetchFromGitHub {
    owner = "adieyal";
    repo = "dynamicprompts";
    rev = "v${version}";
    hash = "sha256-+ZUOwAw6ptNpuWLi6L6exG1HSGoNIcL7bzDFcZqVnWA=";
  };

  build-system = [
    hatchling
  ];

  dependencies = [
    pyparsing
    jinja2
  ];

  optional-dependencies = {
    attentiongrabber = []; # empty list for backwards compatibility

    magicprompt = [ transformers ];

    feelinglucky = [ requests ];

    yaml = [ pyyaml ];

    dev = [
      pytest-cov
      pytest-lazy-fixture
    ];
  };

  pythonImportsCheck = [ "dynamicprompts" ];
  nativeCheckInputs = [
    pytestCheckHook
  ] ++ lib.flatten (builtins.attrValues optional-dependencies);

  meta = {
    description = "Templating language for generating prompts for text to image generators such as Stable Diffusion";
    homepage = "https://github.com/adieyal/dynamicprompts/";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      jk
    ];
  };
}
