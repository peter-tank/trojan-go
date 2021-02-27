#!/bin/bash

type setopt >/dev/null 2>&1

PLATFORMS="windows/amd64 windows/386"
PLATFORMS="$PLATFORMS linux/amd64 linux/arm64 linux/armv7 linux/mips64-softfloat linux/mips64le-softfloat linux/ppc64 linux/ppc64le openbsd/386"
PLATFORMS="$PLATFORMS linux/mips.cli-softfloat linux/mips-softfloat"
PLATFORMS="$PLATFORMS linux/mips.cli-hardfloat linux/mips-hardfloat"
PLATFORMS="$PLATFORMS android/arm64.router android/arm64"
PLATFORMS="$PLATFORMS android/armv7"

SCRIPT_NAME=`basename "$0"`
FAILURES=""
SHA="$1"
OUT="$2"
FORCE_UPX="$3"
[ -n "${FORCE_UPX}" ] || DIFF="_upx"
shift 3

prepare_ndk() {
  local HOST NDK NDK_TOOLS NDK_VER NDK_DL APREFIX
  NDK="20.0.5594570"
  HOST="linux-x86_64"
  NDK_TOOLS="${ANDROID_HOME}/ndk-bundle"
  [ -f "${NDK}" ] || {
    echo ">>> Start Android NDK(${NDK}) env..."
    ${ANDROID_HOME}/tools/bin/sdkmanager "ndk;${NDK}"
    echo "\$?=$?"
    if [ $? -ne 0 ]; then
      NDK_VER="r20"
      NDK_DL="android-ndk-${NDK_VER}-${HOST}.zip"
      NDK_TOOLS=${HOME}/android-ndk-${NDK_VER}
      curl -LOs https://dl.google.com/android/repository/${NDK_DL}
      unzip -q ${NDK_DL} -d ${HOME}
      rm -vrf "${NDK_DL}"
    fi
    touch ${NDK}
    export PATH=${PATH}:${NDK_TOOLS}/toolchains/llvm/prebuilt/${HOST}/bin
  }

  case ${1} in
    "armv7" )   APREFIX="armv7a-linux-androideabi19-";;
    "386" )   APREFIX="i686-linux-android19-";;
    "arm64" ) APREFIX="aarch64-linux-android21-";;
    "amd64" ) APREFIX="x86_64-linux-android21-";;
    * )       echo "Skiped architech: [${1}]";;
  esac
  export CC=${APREFIX:+${APREFIX}clang}
  export CXX=${APREFIX:+${APREFIX}c++}
  export STRIP=${APREFIX:+${APREFIX}strip}
}

trojan_lite() {
	git checkout -- "${1}"
	packages_skip=($2)
	echo ">>> Enable: simplelog"
	sed -i "s/\(.*\)\/\/\(_.*\/simplelog\"\)$/\1\2/" "${1}"
	echo -n ">>> not-buildin modules: "
	for rmp in ${packages_skip[@]}; do
		[[ -z "${rmp}" ]] && continue
		if [[ -n $(sed -n "s/.*\/"${rmp}"\"$/&/gp" "${1}") ]]; then
     echo -n "${rmp}, "
     sed -i "/.*\/"${rmp}"\"$/d" "${1}"
  else
    echo -n "-${rmp}-, "
  fi
	done
	echo
	[ $? -eq 0 ] || cat -n "${1}"
}

rm -rf "${OUT}"
rm -rf ./trojan-go-*
rm -rf ./*.dat
mkdir -vp "${OUT}"

#wget https://github.com/v2ray/domain-list-community/raw/release/dlc.dat -O geosite.dat
#wget https://github.com/v2ray/geoip/raw/release/geoip.dat -O geoip.dat

for PLATFORM in ${PLATFORMS}; do
  go clean
  GOOS="${PLATFORM%/*}"
  GOARCH="${PLATFORM#*/}"
  SUB="${GOARCH#*\.}"
  GOARCH="${GOARCH%\.*}"
  CGO=0; unset GOMIPS UPX APP DST ZIP_FILENAME
  LITE="golog mysql redis custom${FORCE_UPX:+ service control router server}"
  TYPE="${SUB#*-}"
  [ -n "${OP}" ] && APP=1 && [ "${SUB}" == "${TYPE}" ] && SUB=""
  case ${TYPE} in
    "router" ) LITE+=" server";;
    "cli" ) LITE+=" service control router server";;
    "srv" ) LITE+=" service control client adapter socks http forward dokodemo nat tproxy";;
    * )     SUB="${SUB#*-}"; GOARCH="${GOARCH%-*}"; APP=1;;
  esac
  [ "${GOARCH}" == "${SUB}" ] && SUB="";
  case ${SUB#*-} in
    "upx" ) UPX=1;;
    "cgo" ) CGO=1;;
    "softfloat" | "hardfloat" ) GOMIPS=${SUB#*-};;
    * )     APP=1;;
  esac

  trojan_lite "main.go" "${LITE}"
  DST="trojan-go-${GOOS}-${GOARCH}${SUB:+-${SUB#*-}}"
  ZIP_FILENAME="${DST}.zip"

  unset GOARM MIPS64 GO386 CC CXX STRIP CMD BIN CLI
  [ "x${GOOS}" = "xandroid" ] && prepare_ndk "${GOARCH}" && CGO=1
  [[ "${GOARCH}" =~ mips64 ]] && MIPS64=1
  [ "x${GOARCH}" == "xarmv8" ] && GOARCH=arm64
  [ "x${GOOS}" = "xopenbsd" ] && [ "x${GOARCH}" = "x386" ] && GO386=387
  [[ "x${GOARCH}" =~ xarmv[5-7] ]] && GOARM="${GOARCH:4:1}" && GOARCH="arm"
  echo ">>> \$PATH=${PATH}"

  CMD="env -v ${CC:+CC=${CC}} ${CXX:+CXX=${CXX}} CGO_ENABLED=${CGO}"
  CMD+=" GOOS=${GOOS} GOARCH=${GOARCH} ${GO386:+GO386=${GO386}} ${GOARM:+GOARM=${GOARM}} ${GOMIPS:+GOMIPS${MIPS64:+64}=${GOMIPS}}"
  CMD+=" go build -o \"${DST}\" $@ -ldflags=\"-s -w\""
  echo "${CMD}" >> ./new_bin
  [ -d "${DST}" ] || mkdir "${DST}"
  eval ${CMD} || FAILURES="${CMD}"

  BIN=$(find "${DST}" -maxdepth 1 -name "trojan-go*" -type f -executable -newer ./new_bin)
  if [ -n "${BIN}" ]; then
    if [ -n "${SUB}" ] && [ -z "${OP}" ]; then
      mv "${BIN}" "${BIN}${SUB:+-${SUB}}"
      BIN="${BIN}${SUB:+-${SUB}}"
    fi
    [ -n "${STRIP}" ] && which ${STRIP} && ${STRIP} -v "${BIN}"
    CLI=$(find "${DST}" -maxdepth 1 -name "trojan-go-cli*" -type f -executable -newer ./new_bin)
    [ -n "${CLI}${UPX}${FORCE_UPX}" ] && upx -q --ultra-brute ${DIFF:+-o "${BIN}${DIFF}"} "${BIN}" && [ -n "${STRIP}" ] && which ${STRIP} && ${STRIP} -v "${BIN}${DIFF}"
  fi

  if [ -n "${APP}" ]; then
    echo ">>> ${ZIP_FILENAME}"
    zip -du ${OUT}/${ZIP_FILENAME} -j ${DST}/* || continue
    zip ${OUT}/${ZIP_FILENAME} example/*
    echo "<<< ---- ${ZIP_FILENAME}"
  fi
done

sha1sum ${OUT}/*.zip > "${SHA}"
sha1sum ./trojan-go-*/trojan-go* >> "${SHA}"
stat -c "%y %s  %n" ./trojan-go-*/trojan-go* >> "${SHA}"
cat -n "${SHA}"
sha1sum "${SHA}"

# eval errors
if [[ "${FAILURES}" != "" ]]; then
  eval "${FAILURES} -x"
  echo ""
  echo "${SCRIPT_NAME} last failed on: ${FAILURES}"
fi
