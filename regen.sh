#bin/#!/bin/bash

echo "  _____    ______   _____    ______   ___    _  "
echo " |  __ \  |  ____| / ____|  |  ____| |   \  | | "
echo " | |__| } | |___  | /  ___  | |___   | .\ \ | | "
echo " |  _  /  |  ___| | | |_  | |  ___|  | | \ \| | "
echo " | | \ \  | |____ | \___| | | |____  | |  \ ' | "
echo " |_|  \_\ |______| \_____/  |______| |_|   \__| "

regen() {
make O=out ARCH=arm64 ${DEVICE}${SUFFIX}_defconfig
rm -rf arch/arm64/configs/${DEVICE}${SUFFIX}_defconfig
mv out/.config arch/arm64/configs/${DEVICE}${SUFFIX}_defconfig
}

SUFFIX=

tulip() {
DEVICE=tulip
regen
}

whyred() {
DEVICE=whyred
regen
}

jasmine() {
DEVICE=wayne
regen
}

lavender() {
DEVICE=lavender
regen
}

jason() {
DEVICE=jason
regen
}

tulip
whyred
jasmine
lavender
jason
rm -rf out

git add .
git commit -m "arm64/configs: Regenerate defconfigs" --signoff
