{
  lib,
  python3,
  fetchFromGitHub,
}:

python3.pkgs.buildPythonApplication rec {
  pname = "gramps-web-api";
  version = "2.8.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "gramps-project";
    repo = "gramps-web-api";
    rev = "v${version}";
    hash = "sha256-GueJsypEogIhj06heeAWXmvoUbhjxXKzqZhtJeRp7+g=";
  };

  build-system = [
    python3.pkgs.setuptools
    python3.pkgs.setuptools-scm
    python3.pkgs.wheel
  ];

  dependencies = with python3.pkgs; [
    alembic
    bleach
    boto3
    celery
    click
    ffmpeg-python
    flask
    flask-caching
    flask-compress
    flask-cors
    flask-jwt-extended
    flask-limiter
    flask-sqlalchemy
    gramps
    gramps-ql
    jsonschema
    marshmallow
    object-ql
    pdf2image
    pillow
    pytesseract
    sifts
    sqlalchemy
    unidecode
    waitress
    webargs
  ];

  optional-dependencies = with python3.pkgs; {
    ai = [
      openai
      sentence-transformers
    ];
  };

  pythonImportsCheck = [ "gramps_webapi" ];

  meta = {
    description = "A RESTful web API for Gramps - backend of Gramps Web";
    homepage = "https://github.com/gramps-project/gramps-web-api";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ jk ];
    mainProgram = "gramps-web-api";
  };
}
