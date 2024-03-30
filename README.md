# Unraid Nvidia vGPU Driver plugin

- Latest version currently supported: 6.12.9

- Support unraid docker video decoding and virtual machine add vgpu at the same time, 10 and 20 series common card unlock.

- Able big brother can also help to perfect this plug-in.o help to perfect this plug-in.

- If you have any questions, you can join the QQ group: 263813094  Telegram: https://t.me/+HQ4HqWjD111hY2Y1

- This is the repository for the Unraid Nvidia vGPU Driver plugin.

- 1.Install 'user scripts' in the unraid app store
- 2.Create a new run script. (Name customization)
- 3.Newly created script content

```shell
#!/bin/bash
# set -x

# Load drivers 
depmod -a
nvidia-modprobe

## Modify the following variables to suit your environment
WIN="2b6976dd-8620-49de-8d8d-ae9ba47a50db"
UBU="5fd6286d-06ac-4406-8b06-f26511c260d3"
NVPCI="0000:03:00.0"
MDEVLIST="nvidia-65"

if [ ! -d /boot/config/nvidia-vgpu ]; then
    mkdir -p /boot/config/nvidia-vgpu
fi

if [ ! -d /etc/vgpu_unlock/ ]; then
    mkdir -p /etc/vgpu_unlock/
fi

if [ -f /boot/config/nvidia-vgpu/profile_override.toml ]; then
  ln -sf /boot/config/nvidia-vgpu/profile_override.toml /etc/vgpu_unlock/profile_override.toml
else 
  touch /boot/config/nvidia-vgpu/profile_override.toml
  ln -sf /boot/config/nvidia-vgpu/profile_override.toml /etc/vgpu_unlock/profile_override.toml
fi

echo "unlock = false" > /etc/vgpu_unlock/config.toml

env LD_PRELOAD=/usr/local/lib/libvgpu_unlock_rs.so >/dev/null

if pgrep -x nvidia-vgpu-mgr > /dev/null
then
    nvidia-vgpud stop
    nvidia-vgpu-mgr stop
    killall nvidia-vgpu-mgr
fi
LD_PRELOAD=/usr/local/lib/libvgpu_unlock_rs.so nvidia-vgpud 
LD_PRELOAD=/usr/local/lib/libvgpu_unlock_rs.so nvidia-vgpu-mgr

sleep 3

arr=( "${WIN}" "${UBU}" )

for os in "${arr[@]}"; do
    if [[ "$(mdevctl list)" == *"$os"* ]]; then
        echo " [i] Found $os running, stopping and undefining..."
        mdevctl stop -u "$os"
        mdevctl undefine -u "$os"
    fi
done

for os in "${arr[@]}"; do
    echo " [i] Defining and running $os..."
    mdevctl define -u "$os" -p "$NVPCI" --type "$MDEVLIST"
    mdevctl start -u "$os"
done

echo " [i] Currently defined mdev devices:"
mdevctl list
```

- 4.Set the script to run when booting the array
- 5.Create the nvidia.conf file in the /boot/config/modprobe.d directory and add the content "options nvidia cudahost=1"

### Credits
- Thanks to the discord user @mbuchel for the experimental patches
- Thanks to the discord user @LIL'pingu for the extended 43 crash fix
- Special thanks to @DualCoder without his work (vGPU_Unlock) we would not be here
- and thanks to the discord user @snowman for creating this patcher
- thanks to the discord user @midi creating this shell scripts
