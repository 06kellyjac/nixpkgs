{
  lib,
  python3Packages,

  fetchFromGitHub,

  nix-update-script,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "wyoming-openai";
  version = "0.5.0";
  pyproject = true;
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "roryeckel";
    repo = "wyoming_openai";
    tag = "v${finalAttrs.version}";
    hash = "sha256-QGv/F6rIdvTXIryu4L3djPBUTZ+L6WlR1Slw2mGyKf0=";
  };

  patches = [
    ./pyproject_entrypoint.patch
  ];

  build-system = [
    python3Packages.setuptools
  ];

  pythonRelaxDeps = [
    "openai"
    "wyoming"
  ];

  dependencies = with python3Packages; [
    openai
    pysbd
    wyoming
  ];

  optional-dependencies = with python3Packages; {
    dev = [
      pytest
      pytest-asyncio
      pytest-cov
      pytest-mock
    ];
  };

  pythonImportsCheck = [
    "wyoming_openai"
  ];

  nativeCheckInputs = [
    python3Packages.pytestCheckHook
  ]
  ++ finalAttrs.passthru.optional-dependencies.dev;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "OpenAI-Compatible Proxy Middleware for the Wyoming Protocol";
    homepage = "https://github.com/roryeckel/wyoming_openai";
    changelog = "https://github.com/roryeckel/wyoming_openai/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [
      jk
    ];
    mainProgram = "wyoming-openai";
  };
})
