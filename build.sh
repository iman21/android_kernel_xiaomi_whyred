#!/bin/bash

yellow='\033[0;33m'
white='\033[0m'
red='\033[0;31m'
gre='\e[0;32m'
ZIMG=./out/arch/arm64/boot/Image.gz-dtb

disable_mkclean=false
mkdtbs=false
oc_flag=false
uv_flag=false
more_uv_flag=false

for arg in $@; do
	case $arg in
		"--noclean") disable_mkclean=true;;
		"--dtbs") mkdtbs=true;;
		"-oc") oc_flag=true;;
		"-40uv") uv_flag=true;;
		"-80uv") more_uv_flag=true;;
	esac
done

$uv_flag && $more_uv_flag && {
	echo "Parameter -40uv and parameter -80uv cannot exist at the same time"
	exit 1
}

export LOCALVERSION=-v3.6
export LOCALVERSION="-Q"${LOCALVERSION}

rm -f $ZIMG

export ARCH=arm64
export SUBARCH=arm64
export HEADER_ARCH=arm64
export CLANG_PATH=/home/pzqqt/bin/android_prebuilts_clang_host_linux-x86_clang-10.0.1
export KBUILD_COMPILER_STRING=$($CLANG_PATH/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

export KBUILD_BUILD_HOST="lenovo"
export KBUILD_BUILD_USER="pzqqt"

$oc_flag && { git apply ./oc.patch || exit 1; }
$uv_flag && { git apply ./40mv_uv.patch || exit 1; }
$more_uv_flag && { git apply ./80mv_uv.patch || exit 1; }

$disable_mkclean || make mrproper O=out || exit 1
make whyred-perf_defconfig O=out || exit 1

Start=$(date +"%s")

if $mkdtbs; then
	make dtbs \
		O=out \
		CC="ccache $CLANG_PATH/bin/clang" \
		CLANG_TRIPLE=aarch64-linux-gnu- \
		CROSS_COMPILE=/home/pzqqt/bin/gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu/bin/aarch64-linux-gnu- \
		CROSS_COMPILE_ARM32=/home/pzqqt/bin/gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabi/bin/arm-linux-gnueabi-
else
	make -j6 \
		O=out \
		CC="ccache $CLANG_PATH/bin/clang" \
		CLANG_TRIPLE=aarch64-linux-gnu- \
		CROSS_COMPILE=/home/pzqqt/bin/gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu/bin/aarch64-linux-gnu- \
		CROSS_COMPILE_ARM32=/home/pzqqt/bin/gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabi/bin/arm-linux-gnueabi-
fi

exit_code=$?
End=$(date +"%s")
Diff=$(($End - $Start))

$oc_flag && { git apply -R ./oc.patch || exit 1; }
$uv_flag && { git apply -R ./40mv_uv.patch || exit 1; }
$more_uv_flag && { git apply -R ./80mv_uv.patch || exit 1; }

if $mkdtbs; then
	if [ $exit_code -eq 0 ]; then
		echo -e "$gre << Build completed >> \n $white"
	else
		echo -e "$red << Failed to compile dtbs, fix the errors first >>$white"
		exit $exit_code
	fi
else
	if [ -f $ZIMG ]; then
		echo -e "$gre << Build completed in $(($Diff / 60)) minutes and $(($Diff % 60)) seconds >> \n $white"
	else
		echo -e "$red << Failed to compile Image.gz-dtb, fix the errors first >>$white"
		exit $exit_code
	fi
fi
