# Anki Sync Server for Railway: the official ankitects sync server
# (`python -m anki.syncserver`, the Rust server bundled in the `anki` wheel
# published by Ankitects on PyPI). Upstream publishes no container image, so we
# pin the Python base image by version and digest, and the `anki` wheel and all
# of its dependencies by version and sha256 hash (requirements.txt).
FROM python:3.14.9-slim-trixie@sha256:35caba83af2fe6da9a5d922f9b0156f21d1246a48278c58a08bd253303ba42e8

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

COPY requirements.txt /tmp/requirements.txt
RUN pip install --require-hashes --only-binary=:all: -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt \
    && python -c "import anki.buildinfo as b; print('anki', b.version)"

COPY start.sh /usr/local/bin/start.sh
RUN chmod 755 /usr/local/bin/start.sh && mkdir -p /anki_data

# Collections and media live here; mount a volume on it.
VOLUME /anki_data
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import os,urllib.request; urllib.request.urlopen('http://127.0.0.1:%s/health' % os.environ.get('PORT','8080'), timeout=4)" || exit 1

ENTRYPOINT ["/usr/local/bin/start.sh"]
