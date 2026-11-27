# Pinned base image (CI can pin further by digest).
FROM python:3.12.16-slim-trixie

# Provenance, set by CI: --build-arg VERSION=... VCS_REF=$(git rev-parse HEAD) BUILD_DATE=...
ARG VERSION=dev
ARG VCS_REF=unknown
ARG BUILD_DATE=unknown
LABEL org.opencontainers.image.title="shop-client" \
      org.opencontainers.image.description="Marvellous Mischief Co. shop front and Kafka producer" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Unprivileged user with a fixed numeric UID, so Kubernetes "runAsNonRoot"
# can verify it. The code stays owned by root: the app cannot modify itself.
RUN useradd --system --uid 10001 --no-create-home --shell /usr/sbin/nologin app
USER 10001

EXPOSE 5000

# Production WSGI server instead of the Flask dev server. No --preload: each
# worker must create its own Kafka Producer after the fork (librdkafka threads
# do not survive fork()). No control socket: it needs a writable home directory.
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--threads", "4", \
     "--graceful-timeout", "20", "--no-control-socket", "--access-logfile", "-", "wsgi:app"]
