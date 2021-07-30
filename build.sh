# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2021, Tashfin Shakeer Rhythm <tashfinshakeerrhythm@gmail.com>

# COLORS
    green="\033[1;32m"
    yellow="\033[1;33m"
    blue="\033[1;34m"

path () {
# USER
    USER=tashar
    HOST=pop-os
    GCC_PATH=$HOME/toolchains/gcc64
    GCC_ARM32=$HOME/toolchains/gcc32/bin/arm-eabi-
    DEVICE=wayne
    DEVICE_VARIANT=Jasway
    BUILD=clean
    CAM_LIB=
    KERNEL_DIR=`pwd`
    cd $KERNEL_DIR
    ZIP_DIR=$HOME/AnyKernel3
    COMPILER=gcc
    rm -rf out
    mkdir out
    OUT=$KERNEL_DIR/out
    AKSH=$ZIP_DIR/anykernel.sh
    KERNEL=$DEVICE${CAM_LIB}_defconfig
    CONFIG=$KERNEL_DIR/arch/arm64/configs/$KERNEL
    S="            "
    compile
}

compile () {
    rm -rf $DEVICE
    mkdir -p $DEVICE
    make O=$DEVICE clean
    make O=$DEVICE mrproper

# BUILD-START
    DATE=`date +"%Y%m%d-%H%M"`
    BUILD_START=$(date +"%s")

    make O=$DEVICE ARCH=arm64 $KERNEL

    make O=$DEVICE -j$(nproc)         \
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

if [[ -f $KERNEL_DIR/$DEVICE/arch/arm64/boot/Image.gz-dtb ]]; then
    DIFF=$(($BUILD_END - $BUILD_START))	
    AK3_check
else
    echo -e ""
    echo -e "$red Error! Mission failed: We'll get them next time"
    exit
fi
}

AK3_check () {
if [[ -d $ZIP_DIR ]]; then
    repack
else
    echo -e ""
    echo -e "$red Error! Packing failed: AK3 missing"
    exit
fi
}

repack () {
    echo -e ""
    echo -e "$green Zipping Now"
    echo -e ""
    VARIANT=GCC_LTO
    source $DEVICE/.config
    FINAL_ZIP="a26x-new$CONFIG_LOCALVERSION-$VARIANT-`date +"%Y%m%d-%H%M"`"
    echo -e "$green Variant: $yellow$VARIANT"
    echo -e ""
    echo -e "$green Zipname: $yellow$FINAL_ZIP-signed.zip"
    echo -e "$blue"
    cd $ZIP_DIR
    cp $KERNEL_DIR/$DEVICE/arch/arm64/boot/Image.gz-dtb $ZIP_DIR/
if [[ "$DEVICE" == "jasway" || "$DEVICE" == "wayne" ]]; then
    sed -i 's/demo1/jasmine_sprout/g' $AKSH
    sed -i '/device.name1/ a device.name2=wayne' $AKSH
else
    sed -i s/demo1/$DEVICE/g $AKSH
fi
    zip -r9 "$FINAL_ZIP".zip * -x README.md *placeholder zipsigner-3.0.jar $LOGO
    java -jar zipsigner-3.0.jar "$FINAL_ZIP".zip "$FINAL_ZIP"-signed.zip
    mkdir $OUT/$COMPILER
    cp *-signed.zip $OUT/$COMPILER
    rm *.zip
    cd $KERNEL_DIR
    rm $ZIP_DIR/Image.gz-dtb
if [[ "$DEVICE" == "jasway" || "$DEVICE" == "wayne" ]]; then
    sed -i 's/jasmine_sprout/demo1/g' $AKSH
    sed -i '/device.name2/d' $AKSH
else
    sed -i s/$DEVICE/demo1/g $AKSH
fi

# BUILD-END
    BUILD_END=$(date +"%s")
    DIFF=$(($BUILD_END - $BUILD_START))
    exit
}
    path
