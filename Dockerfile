# Stage 1: Install dependencies using uv
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS uv-builder

WORKDIR /app

# Copy only the necessary files for dependency installation
COPY pyproject.toml .

# Install dependencies into a virtual environment
# We run sync without --frozen first to generate a lockfile if needed,
# although for Docker builds it's often better to generate uv.lock locally first.
# For simplicity here, we'll just install based on pyproject.toml.
# Using --system installs into the global site-packages managed by uv,
# which we then copy in the next stage.
RUN uv venv && \
    uv pip install --no-cache -p python3.12 -r pyproject.toml

# Stage 2: Final runtime image
FROM python:3.12-slim-bookworm AS final

# Install pandoc as mkslides might depend on it
# RUN apt-get update && \
#     apt-get install -y pandoc --no-install-recommends && \
#     rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the virtual environment with dependencies from the builder stage
COPY --from=uv-builder /app/.venv /app/.venv

# Copy the application code
COPY src/ ./src/

# Add the virtual environment's bin directory to the PATH
ENV PATH="/app/.venv/bin:$PATH"

# Copy the README file
COPY README.md /app/README.md

# Run mkslides_server.py when the container launches
ENTRYPOINT ["python", "src/mkslides_mcp_server/server.py"]
