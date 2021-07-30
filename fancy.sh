# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2021, Tashfin Shakeer Rhythm <tashfinshakeerrhythm@gmail.com>

# COMPILER
	COMPILER="GCC"

# User config
	USER=tashar
	HOST=pop-os
	VERSION=2.0
# GCC
	GCC_PATH=$HOME/toolchains/gcc64
	GCC_COMPAT=$HOME/toolchains/gcc32/bin/arm-eabi-

# Device config
	NAME='Mi A2 / Mi 6X'
	DEVICE=wayne
	CAM_LIB=

	KERNEL_DIR=$HOME/tempest-CAF
	ZIP_DIR=$HOME/AnyKernel3
	AKSH=$ZIP_DIR/anykernel.sh
	cd $KERNEL_DIR
	mkdir $COMPILER

# Defconfig
	DFCF=$DEVICE${CAM_LIB}_defconfig
	CONFIG=$KERNEL_DIR/arch/arm64/configs/$DFCF

# Compilation
 compile () {
    BUILD_START=$(date +"%s")
    
    make O=$COMPILER ARCH=arm64 $CONFIG

    make O=$COMPILER -j$(nproc)       \
      ARCH=arm64                      \
      PATH=$GCC_PATH/bin:$PATH        \
      KBUILD_BUILD_USER=$USER         \
      KBUILD_BUILD_HOST=$HOST         \
      CC=aarch64-elf-gcc              \
      HOSTCXX=aarch64-elf-g++         \
      HOSTLD=ld.lld                   \
      AS=llvm-as                      \
      AR=llvm-ar                      \
      NM=llvm-nm                      \
      OBJCOPY=llvm-objcopy            \
      OBJDUMP=llvm-objdump            \
      STRIP=llvm-strip                \
      CROSS_COMPILE_ARM32=$GCC_ARM32  \
      LD_LIBRARY_PATH=$GCC_PATH/lib:$LD_LIBRARY_PATH
}

if [[ -f $KERNEL_DIR/$COMPILER/arch/arm64/boot/Image.gz-dtb ]]; then
    source $COMPILER/.config
    FINAL_ZIP="a26x-new$CONFIG_LOCALVERSION-$COMPILER_LTO-`date +"%Y%m%d-%H%M"`"
    cd $ZIP_DIR
    cp $KERNEL_DIR/$DEVICE/arch/arm64/boot/Image.gz-dtb $ZIP_DIR/
    sed -i 's/demo1/$DEVICE/g' $AKSH
    if [[ "$DEVICE2" ]]; then
    sed -i "/device.name1/ a device.name2=$DEVICE2" $AKSH
    fi
    zip -r9 "$FINAL_ZIP".zip * -x README.md *placeholder zipsigner-3.0.jar $LOGO
    java -jar zipsigner-3.0.jar "$FINAL_ZIP".zip "$FINAL_ZIP"-signed.zip
    FINAL_ZIP="$FINAL_ZIP-signed.zip"
    telegram-send --file $ZIP_DIR/$FINAL_ZIP
    rm *.zip Image.gz-dtb
    sed -i "s/$DEVICE/demo1/g" $AKSH
    if [[ "$DEVICE2" ]]; then
    sed -i "/device.name2/d" $AKSH
    fi

    BUILD_END=$(date +"%s")
    DIFF=$(($BUILD_END - $BUILD_START))

    cd $KERNEL_DIR
    telegram-send --format html "\
    **************Project Tempest**************
    Compiler: <code>$CONFIG_CC_VERSION_TEXT</code>
    Linux Version: <code>$(make kernelversion)</code>
    Builder Version: <code>$VERSION</code>
    Maintainer: <code>$USER</code>
    Device: <code>$NAME</code>
    Codename: <code>$DEVICE</code>
    Camlib: <code>$CAM</code>
    Build Date: <code>$(date +"%Y-%m-%d %H:%M")</code>
    Build Duration: <code>$(($DIFF / 60)).$(($DIFF % 60)) mins</code>
    Changelog: <a href='$SOURCE'> Here </a>"
else
    telegram-send "You and your bad luck stroke again. Go cry now"
    exit 1
fi
