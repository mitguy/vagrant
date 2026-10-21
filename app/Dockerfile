FROM python:3.15-slim-trixie

ENV PYTHONDONTWRITEBYTECODE=1 \
  PYTHONUNBUFFERED=1 \
  PIP_NO_CACHE_DIR=1 \
  PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

RUN groupadd --system --gid 10001 app \
  && useradd --system --uid 10001 --gid app \
  --no-create-home --shell /usr/sbin/nologin app

COPY requirements.txt .

# fix false positives
RUN pip install --no-cache-dir -r requirements.txt \
    && rm -f /usr/local/lib/python3.15/site-packages/pip/_vendor/bom.cdx.json

COPY app.py .
USER app
EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD ["python", "-c", "import urllib.request as u; u.urlopen('http://localhost:5000/health')"]

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--access-logfile", "-", "app:app"]
