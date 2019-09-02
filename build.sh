#!/bin/bash

if [ "$1" == "-o" ]; then
	echo "Build for Oreo firmware"
	git apply ./oreo_firmware.patch || exit 1
else
	echo "Build for Pie firmware"
fi

[ "$1" == "--llvm" ] && use_llvm=true || use_llvm=false

yellow='\033[0;33m'
white='\033[0m'
red='\033[0;31m'
gre='\e[0;32m'
ZIMG=./out/arch/arm64/boot/Image.gz-dtb

export LOCALVERSION=-v1.9
if $use_llvm; then
	export LOCALVERSION=${LOCALVERSION}-llvm
else
	export LOCALVERSION=${LOCALVERSION}-clang
fi

rm -f $ZIMG
Start=$(date +"%s")

export ARCH=arm64
export SUBARCH=arm64
export HEADER_ARCH=arm64
if $use_llvm; then
	export CLANG_PATH=/home/pzqqt/bin/snapdragon-llvm-8.0.6-linux64/toolchains/llvm-Snapdragon_LLVM_for_Android_8.0/prebuilt/linux-x86_64
else
	export CLANG_PATH=/home/pzqqt/bin/android_prebuilts_clang_host_linux-x86_clang-5799447
fi
export KBUILD_COMPILER_STRING=$($CLANG_PATH/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

export KBUILD_BUILD_HOST="lenovo"
export KBUILD_BUILD_USER="pzqqt"

make mrproper O=out
make whyred-perf_defconfig O=out
$use_llvm && set CONFIG_LLVM_POLLY=y
make -j6 \
	O=out \
	CC="ccache $CLANG_PATH/bin/clang" \
	CLANG_TRIPLE=aarch64-linux-gnu- \
	CROSS_COMPILE=/home/pzqqt/bin/gcc-linaro-7.4.1-2019.02-rc1-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu- \
	CROSS_COMPILE_ARM32=/home/pzqqt/bin/gcc-linaro-7.4.1-2019.02-rc1-x86_64_arm-linux-gnueabi/bin/arm-linux-gnueabi-

End=$(date +"%s")
Diff=$(($End - $Start))
if [ -f $ZIMG ]; then
	echo -e "$gre << Build completed in $(($Diff / 60)) minutes and $(($Diff % 60)) seconds >> \n $white"
else
	echo -e "$red << Failed to compile zImage, fix the errors first >>$white"
fi

if [ "$1" == "-o" ]; then
	git apply -R ./oreo_firmware.patch || exit 1
fi
