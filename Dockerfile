FROM python:3.12-alpine

# Install system dependencies including Chromium and ChromeDriver
RUN apk add --no-cache \
    git \
    curl \
    chromium \
    chromium-chromedriver

# Install uv from official image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set working directory
WORKDIR /app

# Copy project files
COPY . /app

# Sync dependencies and install project
RUN --mount=type=cache,target=/root/.cache/uv \
    pip install --no-cache-dir inquirer && \
    pip install --no-cache-dir git+https://github.com/stickerdaniel/linkedin_scraper.git && \
    uv sync --frozen

# Create a non-root user
RUN adduser -D -u 1000 mcpuser && chown -R mcpuser:mcpuser /app

# ----------------------------------------------------------
# Create entrypoint.sh (only requires LINKEDIN_COOKIE)
# ----------------------------------------------------------
RUN echo '#!/bin/sh' > /app/entrypoint.sh && \
    echo 'set -e' >> /app/entrypoint.sh && \
    echo '' >> /app/entrypoint.sh && \
    echo 'if [ -z "$LINKEDIN_COOKIE" ]; then' >> /app/entrypoint.sh && \
    echo '  echo "ERROR: LINKEDIN_COOKIE is not set" >&2' >> /app/entrypoint.sh && \
    echo '  exit 1' >> /app/entrypoint.sh && \
    echo 'fi' >> /app/entrypoint.sh && \
    echo '' >> /app/entrypoint.sh && \
    # echo 'echo "Starting LinkedIn MCP Server..."' >> /app/entrypoint.sh && \
    # echo '' >> /app/entrypoint.sh && \
    echo 'if [ "$USE_UV" = "1" ]; then' >> /app/entrypoint.sh && \
    echo '  exec uv run -m linkedin_mcp_server' >> /app/entrypoint.sh && \
    echo 'else' >> /app/entrypoint.sh && \
    echo '  exec python -m linkedin_mcp_server' >> /app/entrypoint.sh && \
    echo 'fi' >> /app/entrypoint.sh && \
    chmod +x /app/entrypoint.sh

USER mcpuser

ENTRYPOINT ["/app/entrypoint.sh"]
