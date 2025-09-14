{
  lib,
  python312Packages,
  fetchFromGitHub,

  pnpm_10,
  nodejs,

  config,
  rocmSupport ? config.rocmSupport,
  rocmPackages ? { },

  versionCheckHook,
}:

# on 3.12 due to mediapipe
python312Packages.buildPythonApplication rec {
  pname = "invokeai";
  version = "6.7.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "invoke-ai";
    repo = "InvokeAI";
    rev = "v${version}";
    hash = "sha256-mgsipr/mUsV15qnucMSlYYBRjhJyhwQVBmFJNgM3eWQ=";
  };

  patches = [
    ./swap-to-requests_mock.patch
  ];

  pnpmDeps = pnpm_10.fetchDeps {
    inherit pname version src;
    sourceRoot = "${src.name}/invokeai/frontend/web";
    fetcherVersion = 2;
    hash = "sha256-xXD4QDZRvUBRI0Of3kiawsh8t/86qMfstLt7wnXoMXw=";
  };
  pnpmRoot = "invokeai/frontend/web";

  nativeBuildInputs = [
    nodejs
    pnpm_10.configHook

    python312Packages.pythonRelaxDepsHook
  ];

  postPatch = ''
    substituteInPlace ./pyproject.toml \
      --replace-fail '"pip", ' ""

    # skip linting
    substituteInPlace ./invokeai/frontend/web/package.json \
      --replace-fail "pnpm run lint && " ""
  '';

  preBuild = ''
    make frontend-build
  '';

  build-system = with python312Packages; [
    # pip
    setuptools
    wheel
  ];

  pythonRemoveDeps = [
    # remove to provide as opencv-python
    "opencv-contrib-python"
    # in our dist-info the name is just "triton"
    "pytorch-triton-rocm"
  ];

  pythonRelaxDeps = [
    "diffusers"
    "mediapipe"
    "numpy"
    "onnx"
    "onnxruntime"
    "sentencepiece"
    "torch"
  ];

  dependencies = with python312Packages; [
    accelerate
    bitsandbytes
    blake3
    compel
    deprecated
    diffusers
    dnspython
    dynamicprompts
    einops
    fastapi
    fastapi-events
    gguf
    huggingface-hub
    mediapipe
    numpy
    onnx
    onnxruntime
    opencv-python
    picklescan
    pillow
    prompt-toolkit
    pydantic
    pydantic-settings
    pypatchmatch
    python-multipart
    python-socketio
    pywavelets
    requests
    safetensors
    semver
    sentencepiece
    spandrel
    # torch
    torchsde
    # torchvision
    transformers
    uvicorn
  ];

  optional-dependencies = with python312Packages; {
    cpu = [
      torch
      torchvision
    ];
    cuda = [
      torch
      torchvision
    ];
    onnx = [ onnxruntime ];
    # onnx-cuda = [ onnxruntime-gpu ]; - doesn't exist
    # onnx-directml = [ onnxruntime-directml ]; - doesn't exist
    rocm = [
      triton # replaces pytorch-triton-rocm
      torch
      torchvision
    ];
    test = [
      httpx
      humanize
      polyfactory
      pytest-cov
      pytest-datadir
      pytest-timeout
      requests-mock # replaces requests-testadapter (via patch)
    ];
    xformers = [
      xformers
    ];
  };

  disabledTests = [
    # not sure why it fails
    "test_config_uniquely_matches_model"
  ];

  nativeCheckInputs = [
    python312Packages.pytestCheckHook
  ]
  ++ lib.flatten (builtins.attrValues optional-dependencies);

  pythonImportsCheck = [
    "invokeai"
  ];

  makeWrapperArgs =
    let
      binpath = lib.makeBinPath (
        []
        ++ lib.optional (rocmSupport) rocmPackages.rocminfo
      );
    in
    [
      ''--prefix PATH : "${binpath}"''
    ];

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";

  meta = {
    description = "Invoke is a leading creative engine for Stable Diffusion models, empowering professionals, artists, and enthusiasts to generate and create visual media using the latest AI-driven technologies. The solution offers an industry leading WebUI, and serves as the foundation for multiple commercial products";
    homepage = "https://invoke-ai.github.io/InvokeAI/";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [
      jk
    ];
    mainProgram = "invokeai-web";
  };
}
