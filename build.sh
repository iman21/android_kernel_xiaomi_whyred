#!/bin/bash

yellow='\033[0;33m'
white='\033[0m'
red='\033[0;31m'
gre='\e[0;32m'
ZIMG=./out/arch/arm64/boot/Image.gz-dtb

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

make mrproper O=out && make whyred-perf_defconfig O=out || exit 1
arg_1="$1"
if [ "$arg_1" == "dtbs" ]; then

	oc_flag=false
	uv_flag=false

	shift
	arg_2="$1"
	if [ "$arg_2" == "-oc" ]; then
		oc_flag=true
		git apply ./oc.patch || exit 1
	elif [ "$arg_2" == "-uv" ]; then
		uv_flag=true
		git apply ./40mv_uv.patch || exit 1
	fi

	shift
	arg_3="$1"
	if [ "$arg_3" != "$arg_2" ]; then
		if [ "$1" == "-oc" ]; then
			oc_flag=true
			git apply ./oc.patch || exit 1
		elif [ "$1" == "-uv" ]; then
			uv_flag=true
			git apply ./40mv_uv.patch || exit 1
		fi
	fi

	make dtbs \
		O=out \
		CC="ccache $CLANG_PATH/bin/clang" \
		CLANG_TRIPLE=aarch64-linux-gnu- \
		CROSS_COMPILE=/home/pzqqt/bin/gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu/bin/aarch64-linux-gnu- \
		CROSS_COMPILE_ARM32=/home/pzqqt/bin/gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabi/bin/arm-linux-gnueabi-
	exit_code=$?

	$oc_flag && { git apply -R ./oc.patch || exit 1; }
	$uv_flag && { git apply -R ./40mv_uv.patch || exit 1; }

	if [ $exit_code -eq 0 ]; then
		echo -e "$gre << Build completed >> \n $white"
	else
		echo -e "$red << Failed to compile dtbs, fix the errors first >>$white"
		exit $exit_code
	fi
else
	Start=$(date +"%s")

	make -j6 \
		O=out \
		CC="ccache $CLANG_PATH/bin/clang" \
		CLANG_TRIPLE=aarch64-linux-gnu- \
		CROSS_COMPILE=/home/pzqqt/bin/gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu/bin/aarch64-linux-gnu- \
		CROSS_COMPILE_ARM32=/home/pzqqt/bin/gcc-arm-8.3-2019.03-x86_64-arm-linux-gnueabi/bin/arm-linux-gnueabi-

	End=$(date +"%s")
	Diff=$(($End - $Start))

	if [ -f $ZIMG ]; then
		echo -e "$gre << Build completed in $(($Diff / 60)) minutes and $(($Diff % 60)) seconds >> \n $white"
	else
		echo -e "$red << Failed to compile Image.gz-dtb, fix the errors first >>$white"
		exit 1
	fi
fi
