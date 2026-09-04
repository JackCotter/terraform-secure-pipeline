# ---- Build stage: compile dependencies, nothing here ships in the final image ----
FROM python:3.12-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# ---- Final stage: minimal runtime image ----
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DJANGO_SETTINGS_MODULE=leaderboard_game.settings

# Only the runtime lib for psycopg2, not the full -dev/build toolchain
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /install /usr/local

WORKDIR /app
COPY . .

RUN groupadd -r appgroup && useradd -r -g appgroup -d /app appuser \
    && mkdir -p /app/staticfiles \
    && chown -R appuser:appgroup /app

USER appuser

# DJANGO_SECRET_KEY is required by settings.py just to import — this build-time
# value is never used for anything security-relevant and is overridden by the
# real secret key (from .env / SSM) at container runtime.
RUN DJANGO_SECRET_KEY=build-time-placeholder-unused-at-runtime python manage.py collectstatic --noinput

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD curl -f http://127.0.0.1:8000/ || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "3", \
     "--timeout", "30", "--access-logfile", "-", "--error-logfile", "-", \
     "leaderboard_game.wsgi:application"]
