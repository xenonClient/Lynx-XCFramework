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
#   SLIM_HEADERS=0 ./build.sh     # PrivateHeaders 유지 (기본은 제거 — 배포 크기 약 22% 감소)
#
set -euo pipefail
cd "$(dirname "$0")"

WORKSPACE="Lynx-XcFramework.xcworkspace"
SCHEME="Lynx-XcFramework"
CONFIGURATION="Release"
OUTPUT_DIR="./Results"
BUILD_DIR="./build"

# 추출 대상 — 소비 측이 링크하는 8개. scripts/make-manifest.sh의 FRAMEWORKS와 같아야 한다.
#
# 앵커 타깃 산출물(Lynx_XcFramework)은 여기 넣지 않는다. 배포 대상이 아닐 뿐 아니라
# (make-manifest.sh / Package.swift 모두 제외), MACH_O_TYPE=staticlib이라 LTO를 켜면
# 바이너리가 Mach-O가 아닌 LLVM 비트코드(0xb17c0de)로 남아 create-xcframework가 실패한다.
# 앵커의 역할은 아카이브 때 모든 pod를 함께 빌드시키는 것뿐이고, 그건 -scheme으로 이미 수행된다.
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

PLATFORMS="${PLATFORMS:-both}"      # both | device | sim
SIGN_IDENTITY="${SIGN_IDENTITY-TFLQDNW4Z9}"  # 빈 값이면 서명하지 않는다
# dSYM을 xcframework에 넣으면 실기기 크래시 심볼리케이션이 되지만 산출물이 ~860MB로 커진다.
# 소비 측 저장소가 바이너리를 직접 커밋하고 있으므로 기본은 제외한다.
INCLUDE_DSYM="${INCLUDE_DSYM:-0}"
# 이미 만들어 둔 아카이브를 재사용해 xcframework만 다시 만든다 (아카이브는 수 분 걸린다).
REUSE_ARCHIVE="${REUSE_ARCHIVE:-0}"
# 완성된 xcframework에서 PrivateHeaders를 제거한다. 어느 프레임워크에도
# module.private.modulemap이 없어 모듈로는 노출되지 않는 헤더들이고
# (Lynx 909개 6.3MB, LynxBase 137개 1.7MB 등, 슬라이스당 ~8MB),
# 앱 바이너리 크기와는 무관한 순수 배포 용량이다. Lynx.xcframework.zip 기준 13.98 → 10.93MB.
# 소비 측이 #import <Lynx/…>로 내부 헤더를 직접 당겨 쓰고 있다면 0으로 끈다.
SLIM_HEADERS="${SLIM_HEADERS:-1}"

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
  # 크기 최적화 설정 — CLI로 넘겨 모든 pod 타깃에 강제 적용한다.
  #   GCC_OPTIMIZATION_LEVEL=z          : -Oz. C/C++/ObjC++에서 -Os 대비 코드 크기 추가 감소 (Lynx는 C++ 비중이 크다)
  #   SWIFT_OPTIMIZATION_LEVEL=-Osize   : Swift 크기 우선 최적화 (+ wholemodule)
  #   LLVM_LTO=YES_THIN                 : Incremental(Thin) LTO — 링크 시점 크로스 파일 최적화
  #   DEAD_CODE_STRIPPING=YES           : 미사용 코드 링크 시 제거
  #   DEPLOYMENT_POSTPROCESSING=YES + STRIP_INSTALLED_PRODUCT=YES + STRIP_STYLE=non-global
  #                                     : 디버그·로컬 심볼 스트립. non-global이라 export 심볼은 유지된다
  #                                       (all로 바꾸면 소비 측 링크가 깨진다). dSYM은 스트립 전에
  #                                       생성되므로 INCLUDE_DSYM=1은 그대로 동작한다.
  #   CLANG_CXX_INLINES_HIDDEN=YES      : -fvisibility-inlines-hidden. C++ 인라인/템플릿 인스턴스만
  #                                       hidden으로 내린다 (Lynx에만 weak 심볼이 1,548개 있다).
  #                                       ObjC 클래스 심볼에는 영향이 없고, 프레임워크 간에 coalesce되는
  #                                       weak 심볼은 std::__1::piecewise_construct 하나뿐이라
  #                                       (상태 없는 태그 객체) 싱글톤 중복 위험도 없다.
  #
  #   GCC_SYMBOLS_PRIVATE_EXTERN(Symbols Hidden by Default)은 여기서 넣지 않는다 —
  #   모든 타깃에 일괄 적용되면 프레임워크 간 심볼 링크(Lynx→LynxBase/PrimJS,
  #   SDWebImageWebPCoder→libwebp)와 ObjC 클래스 export가 깨진다.
  #   Lynx 엔진 C/C++ 소스에 한정한 -fvisibility=hidden은 Podfile의 post_install이
  #   파일 단위로 붙인다 (HIDE_SYMBOLS=0으로 끌 수 있다).
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
    GCC_OPTIMIZATION_LEVEL=z \
    SWIFT_OPTIMIZATION_LEVEL=-Osize \
    SWIFT_COMPILATION_MODE=wholemodule \
    LLVM_LTO=YES_THIN \
    DEAD_CODE_STRIPPING=YES \
    CLANG_CXX_INLINES_HIDDEN=YES \
    DEPLOYMENT_POSTPROCESSING=YES \
    STRIP_INSTALLED_PRODUCT=YES \
    STRIP_STYLE=non-global \
    COPY_PHASE_STRIP=YES \
    DEBUG_INFORMATION_FORMAT=dwarf-with-dsym \
    ASSETCATALOG_COMPILER_OPTIMIZATION=space \
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

  # 서명 전에 제거해야 _CodeSignature가 실제 내용과 어긋나지 않는다.
  if [[ "${SLIM_HEADERS}" == "1" ]]; then
    while IFS= read -r private_headers; do
      [[ -n "${private_headers}" ]] || continue
      echo "  · PrivateHeaders 제거: ${private_headers#"${OUTPUT_DIR}/"} ($(du -sh "${private_headers}" | cut -f1))"
      rm -rf "${private_headers}"
    done < <(find "${OUTPUT_DIR}/${framework}.xcframework" -type d -name PrivateHeaders)
  fi

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
