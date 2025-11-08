#!/bin/bash
#
# Results/의 xcframework를 zip으로 묶고(dist/), 체크섬을 계산해
# GitHub Release 자산을 가리키는 url/checksum 기반 Package.swift를 생성한다.
#
# 사용법: scripts/make-manifest.sh <version> <owner/repo>
#   예:   scripts/make-manifest.sh 3.6.0 tkgka/Lynx-Xcframework
#
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="$1"
REPO="$2"
BASE_URL="https://github.com/${REPO}/releases/download/${VERSION}"

# Lynx_MiniApp(추출 앵커 타깃 산출물)은 배포 대상이 아니다
FRAMEWORKS=(
  Lynx
  LynxBase
  LynxService
  LynxServiceAPI
  PrimJS
  SDWebImage
  SDWebImageWebPCoder
  libwebp
)

rm -rf dist
mkdir -p dist

# 1) zip + checksum (Package.swift를 다시 쓰기 전에 전부 계산한다)
declare -a CHECKSUMS=()
for f in "${FRAMEWORKS[@]}"; do
  src="Results/${f}.xcframework"
  [[ -d "${src}" ]] || { echo "✗ ${src} 없음 — 먼저 ./build.sh를 실행하세요" >&2; exit 1; }
  echo "▶︎ zip: ${f}"
  ditto -c -k --keepParent "${src}" "dist/${f}.xcframework.zip"
  CHECKSUMS+=("$(swift package compute-checksum "dist/${f}.xcframework.zip")")
done

# 2) Package.swift 생성
{
  cat <<EOF
// swift-tools-version: 5.9
//
// ⚠️ scripts/make-manifest.sh가 생성하는 파일 — 직접 수정하지 말 것.
// 바이너리는 GitHub Release(${VERSION}) 자산을 가리킨다.
import PackageDescription

let package = Package(
    name: "Lynx",
    platforms: [.iOS(.v12)],
    products: [
        // 바이너리 간 전이 링크가 자동으로 걸리지 않으므로 제품 하나로 전부 묶는다
        .library(
            name: "Lynx",
            targets: [
EOF
  for f in "${FRAMEWORKS[@]}"; do
    echo "                \"${f}\","
  done
  cat <<EOF
            ]
        )
    ],
    targets: [
EOF
  for i in "${!FRAMEWORKS[@]}"; do
    f="${FRAMEWORKS[$i]}"
    cat <<EOF
        .binaryTarget(
            name: "${f}",
            url: "${BASE_URL}/${f}.xcframework.zip",
            checksum: "${CHECKSUMS[$i]}"
        ),
EOF
  done
  cat <<EOF
    ]
)
EOF
} > Package.swift

# 3) 매니페스트 검증
swift package dump-package > /dev/null
echo "✅ Package.swift 생성 완료 (${VERSION} → ${BASE_URL})"
