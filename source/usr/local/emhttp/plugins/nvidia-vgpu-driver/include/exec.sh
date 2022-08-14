#!/bin/bash

function update(){
KERNEL_V="$(uname -r)"
PACKAGE="nvidia"
vgpu_V="515.57"
CURENTTIME=$(date +%s)
CHK_TIMEOUT=300
if [ -f /tmp/nvidia_vgpu_driver ]; then
  FILETIME=$(stat /tmp/nvidia_vgpu_driver -c %Y)
  DIFF=$(expr $CURENTTIME - $FILETIME)
  if [ $DIFF -gt $CHK_TIMEOUT ]; then
    echo -n "$(wget -qO- https://api.github.com/repos/stl88083365/unraid-nvidia-vgpu-driver/releases/tags/${KERNEL_V} | jq -r '.assets[].name' | grep "${PACKAGE}" | grep -E -v '\.md5$' | awk -F "-" '{print $3}' | sort -V | tail -10)" > /tmp/nvidia_vgpu_driver
    if [ ! -s /tmp/nvidia_vgpu_driver ]; then
      echo -n "$(modinfo nvidia | grep "version:" | awk '{print $2}' | head -1)" > /tmp/nvidia_vgpu_driver
    fi
  fi
else
  echo -n "$(wget -qO- https://api.github.com/repos/stl88083365/unraid-nvidia-vgpu-driver/releases/tags/${KERNEL_V} | jq -r '.assets[].name' | grep "${PACKAGE}" | grep -E -v '\.md5$' | awk -F "-" '{print $3}' | sort -V | tail -10)" > /tmp/nvidia_vgpu_driver
  if [ ! -s /tmp/nvidia_vgpu_driver ]; then
    echo -n "$(modinfo nvidia | grep "version:" | awk '{print $2}' | head -1)" > /tmp/nvidia_vgpu_driver
  fi
fi
if [ -f /tmp/nvidia_branches ]; then
  FILETIME=$(stat /tmp/nvidia_branches -c %Y)
  DIFF=$(expr $CURENTTIME - $FILETIME)
  if [ $DIFF -gt $CHK_TIMEOUT ]; then
    echo -n "$(wget -q -N -O /tmp/nvidia_branches https://raw.githubusercontent.com/stl88083365/versions/master/nvidia_vgpu_versions)"
    if [ ! -s /tmp/nvidia_branches ]; then
      rm -rf /tmp/nvidia_branches
    fi
  fi
else
  echo -n "$(wget -q -N -O /tmp/nvidia_branches https://raw.githubusercontent.com/stl88083365/versions/master/nvidia_vgpu_versions)"
fi
}

function update_version(){
sed -i "/driver_version=/c\driver_version=${1}" "/boot/config/plugins/nvidia-vgpu-driver/settings.cfg"
if [[ "${1}" != "latest" && "${1}" != "latest_prb" && "${1}" != "latest_nfb" ]]; then
  sed -i "/update_check=/c\update_check=false" "/boot/config/plugins/nvidia-vgpu-driver/settings.cfg"
  echo -n "$(crontab -l | grep -v '/usr/local/emhttp/plugins/nvidia-vgpu-driver/include/update-check.sh &>/dev/null 2>&1'  | crontab -)"
fi
/usr/local/emhttp/plugins/nvidia-vgpu-driver/include/download.sh
}

function get_latest_version(){
KERNEL_V="$(uname -r)"
echo -n "$(cat /tmp/nvidia_vgpu_driver | tail -1)"
}

function get_prb(){
echo -n "$(comm -12 /tmp/nvidia_vgpu_driver <(echo "$(cat /tmp/nvidia_branches | grep 'PRB' | cut -d '=' -f2 | sort -V)") | tail -1)"
}

function get_nfb(){
echo -n "$(comm -12 /tmp/nvidia_vgpu_driver <(echo "$(cat /tmp/nvidia_branches | grep 'NFB' | cut -d '=' -f2 | sort -V)") | tail -1)"
}

function get_selected_version(){
echo -n "$(cat /boot/config/plugins/nvidia-vgpu-driver/settings.cfg | grep "driver_version" | cut -d '=' -f2)"
}

function get_installed_version(){
echo -n "$(modinfo nvidia | grep -w "version:" | awk '{print $2}')"
}

function update_check(){
echo -n "$(cat /boot/config/plugins/nvidia-vgpu-driver/settings.cfg | grep "update_check" | cut -d '=' -f2)"
}

function get_nvidia_pci_id(){
echo -n "$(nvidia-smi --query-gpu=index,name,gpu_bus_id,uuid --format=csv,noheader | tr "," "\n" | sed 's/^[ \t]*//' | sed -e s/00000000://g | sed -n '3p')"
}

function get_mdev_list(){
echo -n "$(mdevctl list)"
}

function get_uuid_gen(){
echo -n "$(uuidgen)"
}

function get_types_num(){
idgen=$(uuidgen)
pcid=$(nvidia-smi --query-gpu=index,name,gpu_bus_id,uuid --format=csv,noheader | tr "," "\n" | sed 's/^[ \t]*//' | sed -e s/00000000://g | sed -n '3p')
mdevlist_conf=$(mdevctl start -u $idgen -p "0000:"$pcid -t nvidia-"${1}")
get_sleep=$(cat /boot/config/nvmdev | grep "sleep")
if [ ! -n "$get_sleep" ]; then
	echo "sleep 5" >> /boot/config/nvmdev
	echo $mdevlist_conf >> /boot/config/nvmdev
else
	echo $mdevlist_conf >> /boot/config/nvmdev
fi
echo $$mdevlist_conf
}

function get_flash_id(){
aaa="$(udevadm info -q all -n /dev/sda1 | grep -i by-uuid | head -1)" && echo "${aaa:0-9:9}"
}
function change_update_check(){
sed -i "/update_check=/c\update_check=${1}" "/boot/config/plugins/nvidia-vgpu-driver/settings.cfg"
if [ "${1}" == "true" ]; then
  if [ ! "$(crontab -l | grep "/usr/local/emhttp/plugins/nvidia-vgpu-driver/include/update-check.sh")" ]; then
    echo -n "$((crontab -l ; echo ""$((0 + $RANDOM % 59))" "$(shuf -i 8-9 -n 1)" * * * /usr/local/emhttp/plugins/nvidia-vgpu-driver/include/update-check.sh &>/dev/null 2>&1") | crontab -)"
  fi
elif [ "${1}" == "false" ]; then
  echo -n "$(crontab -l | grep -v '/usr/local/emhttp/plugins/nvidia-vgpu-driver/include/update-check.sh &>/dev/null 2>&1'  | crontab -)"
fi

}

$@
