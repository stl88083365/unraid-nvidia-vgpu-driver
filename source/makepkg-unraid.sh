#!/bin/bash
PLUGIN_NAME="nvidia-vgpu-driver"
BASE_DIR="/usr/local/emhttp/plugins"
TMP_DIR="/tmp/${PLUGIN_NAME}_"$(echo $RANDOM)""
VERSION="$(date +'%Y.%m.%d')"

mkdir -p $TMP_DIR/$VERSION
cd $TMP_DIR/$VERSION
cp -rf /mnt/user/appdata/nvidia-vgpu/source/$BASE_DIR/$PLUGIN_NAME $TMP_DIR/$VERSION/
chmod -R 755 $TMP_DIR/$VERSION/
rm $TMP_DIR/$VERSION/$BASE_DIR/$PLUGIN_NAME/README.md
makepkg -l y -c y $TMP_DIR/$PLUGIN_NAME-$VERSION.txz
md5sum $TMP_DIR/$PLUGIN_NAME-$VERSION.txz | awk '{print $1}' > $TMP_DIR/$PLUGIN_NAME-$VERSION.txz.md5
rm -R $TMP_DIR/$VERSION/
chmod -R 755 $TMP_DIR/*
cp -rf $TMP_DIR/$PLUGIN_NAME-$VERSION.txz* /mnt/user/appdata/nvidia-vgpu/packages/
#rm -R $TMP_DIR