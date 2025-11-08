#!/bin/bash
#
# Podfile의 Lynx 계열 버전 고정을 갱신한다.
# - Lynx / LynxService / XElement: 지정한 버전으로 통일
# - PrimJS: 같은 major.minor 중 최신 (예: Lynx 3.6.0 ↔ PrimJS 3.6.1)
#
# 사용법: scripts/set-lynx-version.sh <lynx_version>
#   예:   scripts/set-lynx-version.sh 3.6.0
#
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="$1"
[[ "${VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "✗ 버전 형식이 X.Y.Z가 아님: ${VERSION}" >&2; exit 1; }

PRIMJS_VERSION="$(scripts/latest-pod-version.sh PrimJS "${VERSION%.*}")"

# -i.bak: macOS(BSD)와 Linux(GNU) sed 양쪽에서 동작하는 in-place 편집
sed -i.bak -E \
  -e "s/(pod 'Lynx', ')[0-9.]+(')/\1${VERSION}\2/" \
  -e "s/(pod 'LynxService', ')[0-9.]+(')/\1${VERSION}\2/" \
  -e "s/(pod 'XElement', ')[0-9.]+(')/\1${VERSION}\2/" \
  -e "s/(pod 'PrimJS', ')[0-9.]+(')/\1${PRIMJS_VERSION}\2/" \
  Podfile
rm -f Podfile.bak

echo "Podfile 갱신: Lynx/LynxService/XElement=${VERSION}, PrimJS=${PRIMJS_VERSION}"
grep -E "pod '(Lynx|LynxService|XElement|PrimJS)'" Podfile
