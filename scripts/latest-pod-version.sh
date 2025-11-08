#!/bin/bash
#
# CocoaPods trunk에서 pod의 최신 정식 버전(X.Y.Z)을 조회한다.
#
# 사용법:
#   scripts/latest-pod-version.sh Lynx           # 최신 버전
#   scripts/latest-pod-version.sh PrimJS 3.6     # 3.6.x 중 최신 (major.minor 필터)
#
set -euo pipefail

POD="$1"
PREFIX="${2:-}"   # 옵션: major.minor 필터 (예: "3.6")

curl -fsSL "https://trunk.cocoapods.org/api/v1/pods/${POD}" \
  | python3 -c '
import json, re, sys

prefix = sys.argv[1]
versions = [v["name"] for v in json.load(sys.stdin)["versions"]]
stable = [v for v in versions if re.fullmatch(r"\d+\.\d+\.\d+", v)]
if prefix:
    filtered = [v for v in stable if v.startswith(prefix + ".")]
    stable = filtered or stable  # 필터에 걸리는 게 없으면 전체 최신으로 폴백
if not stable:
    sys.exit(f"no stable version found")
print(max(stable, key=lambda v: tuple(map(int, v.split(".")))))
' "${PREFIX}"
