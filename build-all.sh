#!/bin/bash

PLATFORMS="linux/mips-srv linux/mips-cli linux/mips"
PLATFORMS="$PLATFORMS windows/amd64 windows/386"
PLATFORMS="$PLATFORMS linux/amd64"
PLATFORMS="$PLATFORMS linux/arm64"

type setopt >/dev/null 2>&1

rm -rd release
rm -rd ./trojan-go-*
rm ./*.dat

mkdir release

wget https://github.com/v2ray/domain-list-community/raw/release/dlc.dat -O geosite.dat
wget https://github.com/v2ray/geoip/raw/release/geoip.dat -O geoip.dat


SCRIPT_NAME=`basename "$0"`
FAILURES=""
SHA="./SHA-1.txt"

trojan_lite() {
	git checkout -- "${1}"
	packages_skip=($2)
	echo ">>> Enable: simplelog"
	sed -i "s/\(.*\)\/\/\(_.*\/simplelog\"\)$/\1\2/" "${1}"
	echo -n ">>> not-buildin modules: "
	for rmp in ${packages_skip[@]}; do
		[[ -z "${rmp}" ]] && continue
		echo -n "${rmp}, "
		sed -i "/.*\/"${rmp}"\"$/d" "${1}"
	done
	echo
	[ $? -eq 0 ] || cat -n "${1}"
}

for PLATFORM in ${PLATFORMS}; do
  GOOS="${PLATFORM%/*}"
  GOARCH="${PLATFORM#*/}"
  SUB="${GOARCH#*-}"
  GOARCH="${GOARCH%-*}"
  LITE="mysql db redis golog"
  CGO=0
  case ${SUB} in
    "cli" ) LITE+=" cert relay service control mixed server";;
    "srv" ) LITE+=" service control mixed client";;
    "cgo" ) CGO=1;;
    * ) SUB="";;
  esac
  trojan_lite "main.go" "${LITE}"
  DST="trojan-go-${GOOS}-${GOARCH}"
  ZIP_FILENAME="${DST}.zip"
  [ -d "${DST}" ] || mkdir "${DST}"
  CMD="CGO_ENABLE=${CGO} GOOS=${GOOS} GOARCH=${GOARCH} go build -o \"${DST}\" $@ -ldflags=\"-s -w\""
  echo "${CMD}" >> ./new_bin
  eval $CMD || FAILURES="${FAILURES} ${CMD}"
  BIN=$(find "${DST}" -maxdepth 1 -name "trojan-go*" -type f -executable -newer ./new_bin)
  if [ -n "${SUB}" ]; then
    mv "${BIN}" "${BIN}${SUB:+-${SUB}}"
    BIN="${BIN}${SUB:+-${SUB}}"
  fi
  LITE=$(find "${DST}" -maxdepth 1 -name "trojan-go*-*" -type f -executable)
  [ -z "${LITE}" ] || upx -q --ultra-brute -o "${BIN}_upx" "${BIN}"
  if [ -z "${SUB}" ]; then
    echo ">>> ${ZIP_FILENAME}"
    zip -du release/${ZIP_FILENAME} -j ${DST}/*
    zip release/${ZIP_FILENAME} example/*
  fi
done
sha1sum ./release/*.zip > "${SHA}"
sha1sum ./trojan-go-*/trojan-go* >> "${SHA}"
stat -c "%y %s  %n" ./trojan-go-*/trojan-go* >> "${SHA}"
cat -n "${SHA}"
sha1sum "${SHA}"

# eval errors
if [[ "${FAILURES}" != "" ]]; then
  echo ""
  echo "${SCRIPT_NAME} failed on: ${FAILURES}"
fi
