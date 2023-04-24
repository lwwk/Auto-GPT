# 'dev' or 'release' container build
ARG BUILD_TYPE=dev

# Use an official Python base image from the Docker Hub
FROM python:3.10-slim AS autogpt-base

# Install browsers
RUN apt-get update && apt-get install -y \
    chromium-driver firefox-esr \
    ca-certificates

# Install utilities
RUN apt-get install -y curl jq wget git

# Set environment variables
ENV PIP_NO_CACHE_DIR=yes \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Install the required python packages globally
ENV PATH="$PATH:/root/.local/bin"
COPY requirements.txt .

# Only install dev dependencies in dev container builds
ARG BUILD_TYPE
RUN [ "${BUILD_TYPE}" = 'dev' ] || sed -i '/Items below this point will not be included in the Docker Image/,$d' requirements.txt && \
	pip install --no-cache-dir -r requirements.txt

WORKDIR /app

# Set the entrypoint
ENTRYPOINT ["python", "-m", "autogpt"]

# dev build -> include everything
FROM autogpt-base as autogpt-dev
ONBUILD COPY . ./

# release build -> include bare minimum
FROM autogpt-base as autogpt-release
ONBUILD COPY autogpt/ ./autogpt

FROM autogpt-${BUILD_TYPE} AS auto-gpt
