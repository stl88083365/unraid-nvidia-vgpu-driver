#!/bin/bash

# Define Variables
export KERNEL_V="$(uname -r)"
export PACKAGE="nvidia"
export DRIVER_AVAIL="$(wget -qO- https://api.github.com/repos/stl88083365/unraid-nvidia-vgpu-driver/releases/tags/${KERNEL_V} | jq -r '.assets[].name' | grep -E ${PACKAGE} | grep -E -v '\.md5$' | sort -V)"
export BRANCHES="$(wget -qO- https://raw.githubusercontent.com/stl88083365/unraid-nvidia-vgpu-driver/master/nvidia_vgpu_versions | grep -v "UPDATED")"
export DL_URL="https://github.com/stl88083365/unraid-nvidia-vgpu-driver/releases/download/${KERNEL_V}"
export SET_DRV_V="$(grep "driver_version" "/boot/config/plugins/nvidia-vgpu-driver/settings.cfg" | cut -d '=' -f2)"
export CUR_V="$(ls -p /boot/config/plugins/nvidia-vgpu-driver/packages/${KERNEL_V%%-*} 2>/dev/null | grep -E -v '\.md5' | sort -V | tail -1)"

#Download Nvidia vGPU Driver Package
download() {
if wget -q -nc --show-progress --progress=bar:force:noscroll -O "/boot/config/plugins/nvidia-vgpu-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}" "${DL_URL}/${LAT_PACKAGE}" ; then
  wget -q -nc --show-progress --progress=bar:force:noscroll -O "/boot/config/plugins/nvidia-vgpu-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}.md5" "${DL_URL}/${LAT_PACKAGE}.md5"
  if [ "$(md5sum /boot/config/plugins/nvidia-vgpu-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE} | awk '{print $1}')" != "$(cat /boot/config/plugins/nvidia-vgpu-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}.md5 | awk '{print $1}')" ]; then
    echo
    echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
    echo "--------------------------------CHECKSUM ERROR!---------------------------------"
    rm -rf /boot/config/plugins/nvidia-vgpu-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}
    exit 1
  fi
  echo
  echo "-----------Successfully downloaded Nvidia vGPU Driver Package v$(echo $LAT_PACKAGE | cut -d '-' -f3)-----------"
else
  echo
  echo "---------------Can't download Nvidia vGPU Driver Package v$(echo $LAT_PACKAGE | cut -d '-' -f3)----------------"
  exit 1
fi
}

#Check if driver is already downloaded
check() {
if ! ls -1 /boot/config/plugins/nvidia-vgpu-driver/packages/${KERNEL_V%%-*}/ | grep -q "${PACKAGE}-$(echo $LAT_PACKAGE | cut -d '-' -f3)" ; then
  echo
  echo "+=============================================================================="
  echo "| WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING"
  echo "|"
  echo "| Don't close this window with the red 'X' in the top right corner until the 'DONE' button is displayed!"
  echo "|"
  echo "| WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING"
  echo "+=============================================================================="
  echo
  echo "----------------Downloading Nvidia vGPU Driver Package v$(echo $LAT_PACKAGE | cut -d '-' -f3)-----------------"
  echo "---------This could take some time, please don't close this window!------------"
  download
else
  echo
  echo "---------Noting to do, Nvidia vGPU Drivers v$(echo $LAT_PACKAGE | cut -d '-' -f3) already downloaded!---------"
  echo
  echo "------------------------------Verifying CHECKSUM!------------------------------"
  if [ "$(md5sum /boot/config/plugins/nvidia-vgpu-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE} | awk '{print $1}')" != "$(cat /boot/config/plugins/nvidia-vgpu-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}.md5 | awk '{print $1}')" ]; then
    rm -rf /boot/config/plugins/nvidia-vgpu-driver/packages/${LAT_PACKAGE}
    echo
    echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR-----"
    echo "--------------------------------CHECKSUM ERROR!--------------------------------"
    echo
    echo "---------------Trying to redownload the Nvidia Vgpu Driver v$(echo $LAT_PACKAGE | cut -d '-' -f3)-------------"
    echo
    echo "+=============================================================================="
    echo "| WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING"
    echo "|"
    echo "| Don't close this window with the red 'X' in the top right corner until the 'DONE' button is displayed!"
    echo "|"
    echo "| WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING"
    echo "+=============================================================================="
    download
  else
    echo
    echo "----------------------------------CHECKSUM OK!---------------------------------"
  fi
  exit 0
fi
}

if [ ! -d "/boot/config/plugins/nvidia-vgpu-driver/packages/${KERNEL_V%%-*}" ]; then
  mkdir -p "/boot/config/plugins/nvidia-vgpu-driver/packages/${KERNEL_V%%-*}"
fi

if [ "${SET_DRV_V}" == "latest" ]; then
  export LAT_PACKAGE="$(echo "$DRIVER_AVAIL" | tail -1)"
  if [ -z "$LAT_PACKAGE" ]; then
    if [ -z "${CUR_V}" ]; then
      echo
      echo "-----ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR - ERROR------"
      echo "---Can't get latest Nvidia driver version and found no installed local driver---"
      echo "-----Please wait for an hour and try it again, if it then also fails please-----"
      echo "------go to the Support Thread on the Unraid forums and make a post there!------"
      exit 1
    else
      LAT_PACKAGE=$CUR_V
    fi
  fi
fi

#Begin Check
check

#Check for old packages that are not suitable for this Kernel and not suitable for the current Nvidia driver version
rm -f $(ls -d /boot/config/plugins/nvidia-vgpu-driver/packages/${KERNEL_V%%-*}/* 2>/dev/null | grep -v "${KERNEL_V%%-*}")
rm -f $(ls /boot/config/plugins/nvidia-vgpu-driver/packages/${KERNEL_V%%-*}/* 2>/dev/null | grep -v "$LAT_PACKAGE")

#Display message to reboot server both in Plugin and WebUI
echo
echo "----To install the new Nvidia vGPU Driver v$(echo $LAT_PACKAGE | cut -d '-' -f3) please reboot your Server!----"
/usr/local/emhttp/plugins/dynamix/scripts/notify -e "Nvidia vGPU Driver" -d "To install the new Nvidia vGPU Driver v$(echo $LAT_PACKAGE | cut -d '-' -f3) please reboot your Server!" -i "alert" -l "/Main"
