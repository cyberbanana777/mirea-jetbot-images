#!/usr/bin/env bash
# Сборка extra-humble-arm64-robot: ./build_image.sh [коммит]
# Коммит репозитория mirea_jetbot_full берётся из аргумента, иначе из REPO_COMMIT в .env.
# Образ строится на ros2:base-humble-arm64 из репозитория ros2-base-images.
# Реестр с базой (необязательно): REGISTRY=registry.local:5000 ./build_image.sh
set -euo pipefail
cd "$(dirname "$0")"
set -a; source ./.env; set +a
REPO_COMMIT="${1:-${REPO_COMMIT}}"
echo "Репозиторий: ${REPO_URL}  коммит: ${REPO_COMMIT}"
# Базовый образ приходит из репозитория ros2-base-images: сначала берём локальный
# (собранный там же или загруженный через load_image.sh), иначе скачиваем из реестра $REGISTRY.
BASE_TAG="ros2:base-humble-arm64"
if sudo docker image inspect "${BASE_TAG}" > /dev/null 2>&1; then
  BASE_IMAGE="${BASE_TAG}"
elif [ -n "${REGISTRY:-}" ]; then
  BASE_IMAGE="${REGISTRY}/${BASE_TAG}"
  echo "Локального образа ${BASE_TAG} нет, скачиваю ${BASE_IMAGE}..."
  sudo docker pull "${BASE_IMAGE}"
else
  cat >&2 <<EOF
Нет базового образа ${BASE_TAG}. Варианты:
  1. собрать его в репозитории ros2-base-images: ./base-humble-arm64/build_image.sh
  2. загрузить из .tar: ./base-humble-arm64/load_image.sh (в том же репозитории)
  3. скачать из реестра: REGISTRY=<адрес реестра> ./build_image.sh
EOF
  exit 1
fi
sudo docker build -t "jetbot:extra-humble-arm64-robot" \
    --build-arg BASE_IMAGE="${BASE_IMAGE}" \
    --build-arg REPO_URL="${REPO_URL}" \
    --build-arg REPO_COMMIT="${REPO_COMMIT}" \
    --build-arg BUILD_JOBS="${BUILD_JOBS:-2}" \
    --build-arg WITH_NAV2="${WITH_NAV2:-0}" \
    .
