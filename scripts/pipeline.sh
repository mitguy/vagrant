#!/usr/bin/env bash

# bash scripts/pipeline.sh Dockerfile.insecure insecure
# bash scripts/pipeline.sh

set -euo pipefail

REGISTRY="${REGISTRY:-192.168.56.10:5000}"
IMAGE_NAME="${IMAGE_NAME:-my-app}"
DOCKERFILE="${1:-Dockerfile}"
TAG="${2:-latest}"
SEVERITY="${SEVERITY:-CRITICAL,HIGH}"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="${ROOT_DIR}/app"
REPORT_DIR="${ROOT_DIR}/reports"
IMAGE="$REGISTRY/${IMAGE_NAME}:${TAG}"

mkdir -p "${REPORT_DIR}"

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
fail() {
  printf '\n\033[1;31mPIPELINE FAILED: %s\033[0m\n' "$*"
  exit 1
}

step "1/4 Проверка Dockerfile на опасные настройки (trivy config)"

trivy config --exit-code 1 --severity "${SEVERITY}" "${APP_DIR}/${DOCKERFILE}" || fail "в ${DOCKERFILE} есть опасные настройки"

step "2/4 Сборка образа ${IMAGE}"

docker build -t "${IMAGE}" -f "${APP_DIR}/${DOCKERFILE}" "${APP_DIR}" || fail "сборка не удалась"

step "3/4 Сканирование образа на уязвимости (trivy image)"

trivy image --quiet --format json -o "${REPORT_DIR}/${IMAGE_NAME}-${TAG}.json" "${IMAGE}"
trivy image --exit-code 1 --ignore-unfixed --severity "${SEVERITY}" "${IMAGE}" || fail "найдены исправимые уязвимости уровня ${SEVERITY}"

step "4/4 Публикация образа в реестр ${REGISTRY}"

docker push "${IMAGE}" || fail "не удалось отправить образ в реестр"

printf '\n\033[1;32mPIPELINE OK: %s опубликован\033[0m\n' "${IMAGE}"
