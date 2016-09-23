#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/util.sh

usage ()
{
cat << EOF

Usage:
   $0 [OPTIONS]

WebRTC build script.

OPTIONS:
   -h             Show this message
   -m MSVSVER     Microsoft Visual Studio (C++) version (e.g. 2013). Default is Chromium build default.
   -o OUTDIR      Output directory. Default is 'out'
   -r REVISION    Git SHA revision. Default is latest revision.
   -t TARGET OS   The target os for cross-compilation. Default is the host OS such as 'linux', 'mac', 'win'. Other values can be 'android', 'ios'.
   -c TARGET CPU  The target cpu for cross-compilation. Default is 'x64'. Other values can be 'x86', 'arm64', 'arm'.
   -b BLACKLIST   Blacklisted *.o objects to exclude from the static library.
   -e ENABLE_RTTI Compile WebRTC with RTII enabled.
EOF
}

while getopts :m:o:r:t:c:b:e: OPTION; do
  case $OPTION in
  m) MSVSVER=$OPTARG ;;
  o) OUTDIR=$OPTARG ;;
  r) REVISION=$OPTARG ;;
  t) TARGET_OS=$OPTARG ;;
  c) TARGET_CPU=$OPTARG ;;
  b) BLACKLIST=$OPTARG ;;
  e) ENABLE_RTTI=$OPTARG ;;
  ?) usage; exit 1 ;;
  esac
done

OUTDIR=${OUTDIR:-out}
PROJECT_NAME=webrtcbuilds
REPO_URL="https://chromium.googlesource.com/external/webrtc"
DEPOT_TOOLS_URL="https://chromium.googlesource.com/chromium/tools/depot_tools.git"
DEPOT_TOOLS_DIR=$DIR/depot_tools
DEPOT_TOOLS_WIN_TOOLCHAIN=0
PATH=$DEPOT_TOOLS_DIR:$DEPOT_TOOLS_DIR/python276_bin:$PATH

mkdir -p $OUTDIR
OUTDIR=$(cd $OUTDIR && pwd -P)

# Compiler options
BLACKLIST=${BLACKLIST:-}
ENABLE_RTTI=${ENABLE_RTTI:-0}

# If a Microsoft Visual Studio (C++) version is given, override the Chromium build default.
MSVSVER=${MSVSVER:-}
if [ -n "$MSVSVER" ]; then
  export GYP_MSVS_VERSION=$MSVSVER
fi

detect-platform
TARGET_OS=${TARGET_OS:-$PLATFORM}
TARGET_CPU=${TARGET_CPU:-x64}
echo "Host OS: $PLATFORM"
echo "Target OS: $TARGET_OS"
echo "Target CPU: $TARGET_CPU"

# echo Checking webrtcbuilds dependencies
# check::webrtcbuilds::deps $PLATFORM
#
# echo Checking depot-tools
# check::depot-tools $PLATFORM $DEPOT_TOOLS_URL $DEPOT_TOOLS_DIR

# If no revision given, then get the latest revision from git ls-remote
REVISION=${REVISION:-$(latest-rev $REPO_URL)} || \
  { echo "Could not get latest revision" && exit 1; }
REVISION_NUMBER=$(revision-number $REPO_URL $REVISION) || \
  { echo "Could not get revision number" && exit 1; }
echo "Building revision: $REVISION"
echo "Associated revision number: $REVISION_NUMBER"

# echo "Checking out WebRTC revision (this will take awhile): $REVISION"
# checkout "$TARGET_OS" $OUTDIR $REVISION
#
# echo Checking WebRTC dependencies
# check::webrtc::deps $PLATFORM $OUTDIR "$TARGET_OS"

echo Patching WebRTC source
patch $PLATFORM $OUTDIR $ENABLE_RTTI

# echo Compiling WebRTC
# compile $PLATFORM $OUTDIR "$TARGET_OS" "$TARGET_CPU"

# echo Packaging WebRTC
# # label is <projectname>-<rev-number>-<short-rev-sha>-<target-os>-<target-cpu>
# LABEL=$PROJECT_NAME-$REVISION_NUMBER-$(short-rev $REVISION)-$TARGET_OS-$TARGET_CPU
# package $PLATFORM $OUTDIR $LABEL $DIR/resource

echo Build successful
