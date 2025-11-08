#!/bin/bash
#
# Podfile의 Lynx 버전 고정을 갱신한다.
#
# Lynx만 고정하면 된다 — PrimJS/LynxService/SDWebImage 등 나머지 pod의 버전은
# podspec 의존성 제약(예: Lynx 3.9.0 → PrimJS/quickjs 3.8.0-alpha.6 정확 고정)을
# pod install이 해석해 결정하고 Podfile.lock에 기록된다.
#
# 사용법: scripts/set-lynx-version.sh <lynx_version>
#   예:   scripts/set-lynx-version.sh 3.9.0
#
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="$1"
[[ "${VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "✗ 버전 형식이 X.Y.Z가 아님: ${VERSION}" >&2; exit 1; }

# -i.bak: macOS(BSD)와 Linux(GNU) sed 양쪽에서 동작하는 in-place 편집
sed -i.bak -E "s/(pod 'Lynx', ')[0-9.]+(')/\1${VERSION}\2/" Podfile
rm -f Podfile.bak

echo "Podfile 갱신: Lynx=${VERSION}"
grep "pod 'Lynx'" Podfile
