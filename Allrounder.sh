# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2021, Divyanshu-Modi <divyan.m05@gmail.com>

# COLORS
    red="\033[1;31m"
    green="\033[1;32m"
    yellow="\033[1;33m"
    blue="\033[1;34m"

path () {
#USER
    USER=tashar
    HOST=pop-os

#CLANG
    CLANG_PATH=$HOME/toolchains/proton-clang
    CC_ARM64=aarch64-linux-gnu-
    CC_ARM32=arm-linux-gnueabi-

#GCC
    GCC_PATH=$HOME/toolchains/gcc64
    GCC_ARM32=$HOME/toolchains/gcc32/bin/arm-eabi-

    DEVICE=wayne
    BUILD=clean
    CAM_LIB=
    KERNEL_DIR=`pwd`
    ZIP_DIR=$HOME/AnyKernel3
if [[ ! -d $KERNEL_DIR/out ]]; then
    mkdir out
fi
    OUT=$KERNEL_DIR/out
    AKSH=$ZIP_DIR/anykernel.sh
if [[ -d $KERNEL_DIR/arch/arm64/configs/AtomX ]]; then
    KERNEL=AtomX/AtomX-$DEVICE${CAM_LIB}_defconfig
else
    LOGO=banner
    KERNEL=$DEVICE${CAM_LIB}_defconfig
fi
    CONFIG=$KERNEL_DIR/arch/arm64/configs/$KERNEL
    date=`date +"%Y%m%d-%H%M"`
    S="            "
    clear
    compiler_selection
}

error () {
    clear
    echo -e "$red Error! Unrecognised Variable reloading"
    echo -e ""
}

compiler_selection () {
    echo -e "$green Compiler Selection $red                                 "
    echo -e " ╔════════════════════════════════════════════════════════════╗"
    echo -e " ║$green 1. CLANG                                       $S$red║"
    echo -e " ║$green 2. GCC                                         $S$red║"
    echo -e " ║$green e. EXIT                                        $S$red║"
    echo -e " ╚════════════════════════════════════════════════════════════╝"
    echo -ne "$green \n Enter your choice or press 'e' for back to shell: "

    read -r selector
if [[ "$selector" == "1" ]]; then
    COMPILER=clang
    PATH_1=$CLANG_PATH
    clear
    lto_selection
elif [[ "$selector" == "2" ]]; then
    COMPILER=gcc
    PATH_1=$GCC_PATH
    clear
    lto_selection
elif [[ "$selector" == "e" ]]; then
    clear || exit
else
    error
    compiler_selection
fi
}

lto_selection () {
    echo -e "$green Compiler Selection $red                                 "
    echo -e " ╔════════════════════════════════════════════════════════════╗"
    echo -e " ║$green 1.LTO                                          $S$red║"
if [[ "$COMPILER" == "clang" ]]; then
    echo -e " ║$green 2.THIN-LTO                                     $S$red║"    
    echo -e " ║$green 3.NO-LTO                                       $S$red║"
else
    echo -e " ║$green 2.NO-LTO                                       $S$red║"
fi
    echo -e " ║$green e.EXIT                                         $S$red║"
    echo -e " ╚════════════════════════════════════════════════════════════╝"
    echo -ne "$green \n Enter your choice or press 'e' for back to shell: "

    read -r lto

if [[ "$lto" == "1" || "$COMPILER" == "clang" && ("$lto" == "2" || "$lto" == "3") || "$COMPILER" == "gcc" && "$lto" == "2" ]]; then
   compile
elif [[ "$lto" == "e" ]]; then
   clear || exit
else
   error
   lto_selection
fi
}

compile () {
    clear
if [[ "$BUILD" == "clean" ]]; then
    rm -rf $DEVICE || mkdir $DEVICE
else
    make O=$DEVICE clean mrproper
fi

# BUILD-START
    echo -e "$green Build type: $yellow$BUILD"
    echo -e "$green"
    echo -e " Starting Compilation for $yellow$DEVICE$CAM_LIB$green"
    BUILD_START=$(date +"%s")

    source $CONFIG
if [[ "$lto" == "1" || "$COMPILER" == "clang" && "$lto" == "2" ]]; then
    sed -i '/CONFIG_LTO_NONE=y/d' $CONFIG
fi
if [[ "$COMPILER" == "gcc" ]]; then
    sed -i '/CONFIG_LLVM_POLLY/ a CONFIG_GCC_GRAPHITE=y' $CONFIG
    sed -i 's/# CONFIG_OPTIMIZE_INLINING is not set/CONFIG_OPTIMIZE_INLINING=y/g' $CONFIG
    if [[ "$lto" == "1" ]]; then
        sed -i 's/# CONFIG_LTO_GCC is not set/CONFIG_LTO_GCC=y/g' $CONFIG
    fi
elif [[ "$COMPILER" == "clang" ]]; then
    if [[ "$lto" != "3" ]]; then
        sed -i 's/# CONFIG_LTO_CLANG is not set/CONFIG_LTO_CLANG=y/g' $CONFIG
        sed -i 's/# CONFIG_LLVM_POLLY is not set/CONFIG_LLVM_POLLY=y/g' $CONFIG
    fi
    if [[ "$lto" == "1" ]]; then
        sed -i '/CONFIG_ARCH_SUPPORTS_THINLTO/ a # CONFIG_THINLTO is not set' $CONFIG
    fi
fi
    make O=$DEVICE $KERNEL
if [[ "$lto" == "1" || "$COMPILER" == "clang" && "$lto" == "2" ]]; then
    sed -i '/CONFIG_ARCH_SUPPORTS_THINLTO/ a CONFIG_LTO_NONE=y' $CONFIG
fi
if [[ "$COMPILER" == "gcc" ]]; then
    sed -i '/CONFIG_GCC_GRAPHITE=y/d' $CONFIG
    sed -i 's/CONFIG_OPTIMIZE_INLINING=y/# CONFIG_OPTIMIZE_INLINING is not set/g' $CONFIG
    if [[ "$lto" == "1" ]]; then
        sed -i 's/CONFIG_LTO_GCC=y/# CONFIG_LTO_GCC is not set/g' $CONFIG
    fi
elif [[ "$COMPILER" == "clang" ]]; then
    if [[ "$lto" != "3" ]]; then
        sed -i 's/CONFIG_LTO_CLANG=y/# CONFIG_LTO_CLANG is not set/g' $CONFIG
        sed -i 's/CONFIG_LLVM_POLLY=y/# CONFIG_LLVM_POLLY is not set/g' $CONFIG
    fi
    if [[ "$lto" == "1" ]]; then
        sed -i '/# CONFIG_THINLTO is not set/d' $CONFIG
    fi
fi

if [[ "$COMPILER" == "clang" ]]; then
    make O=$DEVICE -j8                \
      PATH=$PATH_1/bin:$PATH          \
      KBUILD_BUILD_USER=$USER         \
      KBUILD_BUILD_HOST=$HOST         \
      CC="ccache $PATH_1/bin/clang"   \
      HOSTCC=clang                    \
      HOSTCXX=clang++                 \
      HOSTLD=ld.lld                   \
      AS=llvm-as                      \
      AR=llvm-ar                      \
      NM=llvm-nm                      \
      OBJCOPY=llvm-objcopy            \
      OBJDUMP=llvm-objdump            \
      STRIP=llvm-strip                \
      CROSS_COMPILE=$CC_ARM64         \
      CROSS_COMPILE_ARM32=$CC_ARM32
elif [[ "$COMPILER" == "gcc" ]]; then
    make O=$DEVICE -j8              \
      PATH=$PATH_1/bin:$PATH        \
      KBUILD_BUILD_USER=$USER       \
      KBUILD_BUILD_HOST=$HOST       \
      CC=aarch64-elf-gcc            \
      HOSTCXX=aarch64-elf-g++       \
      HOSTLD=aarch64-elf-ld         \
      AS=aarch64-elf-as             \
      LD=aarch64-elf-ld             \
      AR=aarch64-elf-ar             \
      NM=aarch64-elf-nm             \
      OBJCOPY=aarch64-elf-objcopy   \
      OBJDUMP=aarch64-elf-objdump   \
      STRIP=aarch64-elf-strip       \
      CROSS_COMPILE_ARM32=$GCC_ARM32\
      LD_LIBRARY_PATH=$PATH_1/lib:$LD_LIBRARY_PATH
fi

# BUILD-END
    BUILD_END=$(date +"%s")
    check
}

check () {
if [[ -f $KERNEL_DIR/$DEVICE/arch/arm64/boot/Image.gz-dtb ]]; then
    DIFF=$(($BUILD_END - $BUILD_START))	
    AK3_check
else
    echo -e ""
    echo -e "$red Error! Compilaton failed: Kernel Image missing"
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
if [[ "$lto" == "1" ]]; then
    VARIANT=FULL_LTO
elif [[ "$COMPILER" == "clang" && "$lto" == "2" ]]; then
    VARIANT=THIN_LTO
else
    VARIANT=NO_LTO
fi
    source $DEVICE/.config
    FINAL_ZIP="$DEVICE$CAM_LIB$CONFIG_LOCALVERSION-$VARIANT-$date"
    echo -e "$green Variant: $yellow$VARIANT"
    echo -e ""
    echo -e "$green Zipname: $yellow$FINAL_ZIP"
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
if [[ ! -d $OUT/$COMPILER ]]; then
    mkdir $OUT/$COMPILER
fi
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
    echo -e "Compiled $yellow$DEVICE$CAM_LIB$green in $(($DIFF / 60)).$(($DIFF % 60)) minute(s)."
    exit
}
    path
