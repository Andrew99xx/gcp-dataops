# 1) Build stage: install dependencies in an isolated image
FROM python:3.11-slim AS builder

# Install build tools for packages that need compilation
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      gcc \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /install

# Copy only requirements so we can cache this layer when code changes
COPY requirements.txt .

# Install into an isolated prefix so we can copy just the libs later
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir --prefix=/install -r requirements.txt

# 2) Runtime stage: smallest possible image with only runtime artifacts
FROM python:3.11-slim

# Create a non‑root user for better security
RUN groupadd --gid 1000 appuser \
 && useradd --uid 1000 --gid appuser --shell /usr/sbin/nologin --create-home appuser

WORKDIR /app

# Copy installed Python packages from builder
COPY --from=builder /install /usr/local

# Copy your FastAPI application code
COPY main.py .

# Drop privileges to the unprivileged user
USER appuser

# Expose port and set environment
ENV PORT=8080
EXPOSE 8080

# Optional: simple healthcheck
HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl --fail http://127.0.0.1:${PORT}/health || exit 1

# Final command
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
