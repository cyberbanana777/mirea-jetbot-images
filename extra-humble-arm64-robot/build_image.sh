#!/usr/bin/env bash
# Сборка образа registry.cookcloud.ru/jetbot_mirea/extra-humble-arm64-robot:<VERSION>: ./build_image.sh [коммит]
# Версия образа, версия базы и коммит репозитория mirea_jetbot_full берутся из .env;
# коммит можно передать аргументом. Базовый образ docker скачает из реестра сам, если его нет локально.
# Публикация: source .env && sudo docker push registry.cookcloud.ru/jetbot_mirea/extra-humble-arm64-robot:$VERSION
set -euo pipefail
cd "$(dirname "$0")"
set -a; source ./.env; set +a
REPO_COMMIT="${1:-${REPO_COMMIT:-}}"
[ -n "${REPO_COMMIT}" ] || { echo "Не задан REPO_COMMIT: впиши его в .env или передай аргументом" >&2; exit 1; }
BASE_IMAGE="registry.cookcloud.ru/base_images/ros2-base-humble-arm64:${BASE_VERSION}"
echo "Образ: registry.cookcloud.ru/jetbot_mirea/extra-humble-arm64-robot:${VERSION}  база: ${BASE_IMAGE}"
echo "Репозиторий: ${REPO_URL}  коммит: ${REPO_COMMIT}"
sudo docker build -t "registry.cookcloud.ru/jetbot_mirea/extra-humble-arm64-robot:${VERSION}" \
    --build-arg BASE_IMAGE="${BASE_IMAGE}" \
    --build-arg REPO_URL="${REPO_URL}" \
    --build-arg REPO_COMMIT="${REPO_COMMIT}" \
    --build-arg BUILD_JOBS="${BUILD_JOBS:-2}" \
    --build-arg WITH_NAV2="${WITH_NAV2:-0}" \
    .
