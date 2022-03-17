# Based on multistage docker using poetry with pipx:
# https://github.com/br3ndonland/inboard/pull/47
# Multistage docker file to "build" the app and copy over the venv

## Alternative method
## TODO: maybe use this instead
# FROM python-base as builder
# ...
# RUN poetry export -f requirements.txt > requirements.txt

# FROM python-base as app
# ...
# RUN pip install -r requirements.txt
# ...
##

# Base container with python
# Add aditional python ENVs here
ARG PYTHON_DOCKER_TAG=3.10-slim
FROM python:$PYTHON_DOCKER_TAG as python-base
ENV DEPLOY_DIR=/deploy
ENV BUILD_DIR=/build

# Builder container with poetry for building the app
FROM python-base as builder
ARG PIPX_VERSION=0.16.4 POETRY_VERSION=1.1.13
ENV PATH=/opt/pipx/bin:$PATH \
    PIPX_BIN_DIR=/opt/pipx/bin \
    PIPX_HOME=/opt/pipx/home
WORKDIR $BUILD_DIR
COPY poetry.lock pyproject.toml $BUILD_DIR/
RUN python -m pip install --no-cache-dir --upgrade pip "pipx==$PIPX_VERSION"
RUN pipx install "poetry==$POETRY_VERSION"

# Actual build run here to create .venv
FROM builder as build
ENV POETRY_VIRTUALENVS_IN_PROJECT=true
RUN poetry install --no-dev --no-interaction --no-root

# The final application container built on the just the base python container
FROM python-base as app
RUN groupadd -r myuser && useradd -r -g myuser myuser
ENV PATH="$DEPLOY_DIR/.venv/bin:$PATH"
WORKDIR $DEPLOY_DIR
COPY --from=build /$BUILD_DIR ./
COPY ./app ./app
COPY ./data ./data
COPY tests.py .
EXPOSE 5000
USER myuser
ENTRYPOINT ["python"]
CMD ["app/main.py" ]
