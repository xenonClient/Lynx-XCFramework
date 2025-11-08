#!/bin/bash
#
# Lynx CocoaPods 산출물 → XCFramework 추출 스크립트.
#
# device(arm64) + simulator(arm64/x86_64) 슬라이스를 모두 빌드해 하나의 XCFramework로 합친다.
# 시뮬레이터 슬라이스만 있으면 실기기 빌드에서
# "building for iOS, but linking in object file built for iOS Simulator"로 실패한다.
#
# 사용법:
#   ./build.sh                    # device + simulator (기본)
#   PLATFORMS=sim ./build.sh      # 시뮬레이터만 (빠른 반복용)
#   PLATFORMS=device ./build.sh   # 실기기만
#   SIGN_IDENTITY= ./build.sh     # 코드사인 생략
#   INCLUDE_DSYM=1 ./build.sh     # dSYM 동봉 (크래시 심볼리케이션용, 산출물 ~860MB)
#   REUSE_ARCHIVE=1 ./build.sh    # 기존 build/*.xcarchive 재사용 (xcframework만 다시 만듦)
#
set -euo pipefail
cd "$(dirname "$0")"

WORKSPACE="Lynx-MiniApp.xcworkspace"
SCHEME="Lynx-MiniApp"
CONFIGURATION="Release"
OUTPUT_DIR="./Results"
BUILD_DIR="./build"

# 추출 대상. 앞의 8개가 LynxMiniFramework가 링크하는 프레임워크이고,
# Lynx_MiniApp은 이 추출용 프로젝트 자체의 샘플 코드다 (소비 측에서는 불필요).
FRAMEWORKS=(
  Lynx
  LynxBase
  LynxService
  LynxServiceAPI
  PrimJS
  SDWebImage
  SDWebImageWebPCoder
  libwebp
  Lynx_MiniApp
)

PLATFORMS="${PLATFORMS:-both}"      # both | device | sim
SIGN_IDENTITY="${SIGN_IDENTITY-TFLQDNW4Z9}"  # 빈 값이면 서명하지 않는다
# dSYM을 xcframework에 넣으면 실기기 크래시 심볼리케이션이 되지만 산출물이 ~860MB로 커진다.
# 소비 측 저장소가 바이너리를 직접 커밋하고 있으므로 기본은 제외한다.
INCLUDE_DSYM="${INCLUDE_DSYM:-0}"
# 이미 만들어 둔 아카이브를 재사용해 xcframework만 다시 만든다 (아카이브는 수 분 걸린다).
REUSE_ARCHIVE="${REUSE_ARCHIVE:-0}"

DEVICE_ARCHIVE="${BUILD_DIR}/ios_device.xcarchive"
SIM_ARCHIVE="${BUILD_DIR}/ios_sim.xcarchive"

# 프레임워크만 뽑을 것이므로 서명은 아카이브 단계에서 생략하고, 완성된 xcframework에만 서명한다.
archive() {
  local destination="$1"
  local archive_path="$2"
  if [[ "${REUSE_ARCHIVE}" == "1" && -d "${archive_path}" ]]; then
    echo "▶︎ archive 재사용: ${archive_path}"
    return
  fi
  echo "▶︎ archive: ${destination}"
  xcodebuild archive \
    -workspace "${WORKSPACE}" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -destination "${destination}" \
    -archivePath "${archive_path}" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" \
    > "${archive_path%.xcarchive}.log" \
    || { echo "✗ 아카이브 실패 — 로그: ${archive_path%.xcarchive}.log" >&2; exit 1; }
}

if [[ "${REUSE_ARCHIVE}" != "1" ]]; then
  rm -rf "${BUILD_DIR}"
fi
mkdir -p "${BUILD_DIR}" "${OUTPUT_DIR}"

ARCHIVES=()
case "${PLATFORMS}" in
  both)
    archive "generic/platform=iOS" "${DEVICE_ARCHIVE}"
    archive "generic/platform=iOS Simulator" "${SIM_ARCHIVE}"
    ARCHIVES=("${DEVICE_ARCHIVE}" "${SIM_ARCHIVE}")
    ;;
  device)
    archive "generic/platform=iOS" "${DEVICE_ARCHIVE}"
    ARCHIVES=("${DEVICE_ARCHIVE}")
    ;;
  sim)
    archive "generic/platform=iOS Simulator" "${SIM_ARCHIVE}"
    ARCHIVES=("${SIM_ARCHIVE}")
    ;;
  *)
    echo "PLATFORMS는 both / device / sim 중 하나여야 합니다 (받은 값: ${PLATFORMS})" >&2
    exit 1
    ;;
esac

for framework in "${FRAMEWORKS[@]}"; do
  args=()
  for archive_path in "${ARCHIVES[@]}"; do
    framework_path="${archive_path}/Products/Library/Frameworks/${framework}.framework"
    if [[ ! -d "${framework_path}" ]]; then
      echo "⚠︎ ${framework}: $(basename "${archive_path}")에 없음 — 건너뜁니다" >&2
      continue
    fi
    args+=(-framework "${framework_path}")

    dsym_path="${archive_path}/dSYMs/${framework}.framework.dSYM"
    if [[ "${INCLUDE_DSYM}" == "1" && -d "${dsym_path}" ]]; then
      args+=(-debug-symbols "$(cd "${archive_path}/dSYMs" && pwd)/${framework}.framework.dSYM")
    fi
  done

  if [[ ${#args[@]} -eq 0 ]]; then
    echo "✗ ${framework}: 아카이브에서 찾지 못했습니다" >&2
    continue
  fi

  echo "▶︎ create-xcframework: ${framework}"
  rm -rf "${OUTPUT_DIR}/${framework}.xcframework"
  xcrun xcodebuild -create-xcframework "${args[@]}" -output "${OUTPUT_DIR}/${framework}.xcframework" > /dev/null

  if [[ -n "${SIGN_IDENTITY}" ]]; then
    codesign --timestamp -s "${SIGN_IDENTITY}" "${OUTPUT_DIR}/${framework}.xcframework"
  fi
done

echo
echo "✅ 완료 — ${OUTPUT_DIR} (슬라이스 확인)"
for framework in "${FRAMEWORKS[@]}"; do
  xcframework="${OUTPUT_DIR}/${framework}.xcframework"
  [[ -d "${xcframework}" ]] || continue
  slices=$(find "${xcframework}" -mindepth 1 -maxdepth 1 -type d ! -name "_CodeSignature" -exec basename {} \; | sort | tr '\n' ' ')
  printf "  %-22s %s\n" "${framework}" "${slices}"
done
