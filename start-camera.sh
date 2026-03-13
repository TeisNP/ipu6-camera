#!/bin/bash
# Start integrated camera feed to v4l2loopback for app compatibility
# Usage: sudo ./start-camera.sh

set -e

# Load IPU6 driver stack
modprobe -a usbio gpio-usbio i2c-usbio intel-ipu6-psys 2>/dev/null || true
sleep 3
udevadm settle --timeout=30 2>/dev/null || true

# Wait for Intel IPU6 ISYS video devices to appear
for i in $(seq 1 30); do
    grep -rql "Intel IPU6 ISYS" /sys/class/video4linux/*/name 2>/dev/null && break
    sleep 1
done

# Reprobe sensor if it failed to probe at boot (race with USB-IO bridge)
if [ ! -e /dev/v4l-subdev0 ]; then
    modprobe -r ov02c10 2>/dev/null || true
    sleep 1
    modprobe ov02c10
    sleep 3
fi

# Reload v4l2loopback
modprobe -r v4l2loopback 2>/dev/null || true
modprobe v4l2loopback video_nr=99 card_label="Integrated Camera" exclusive_caps=1

export GST_PLUGIN_PATH=/usr/lib/gstreamer-1.0
export CAMHAL_PROFILE_DIR=/etc/camera/ipu6epmtl

exec gst-launch-1.0 -e \
    icamerasrc buffer-count=7 \
    ! video/x-raw,format=NV12,width=1920,height=1080 \
    ! videoflip method=rotate-180 \
    ! videoconvert \
    ! video/x-raw,format=YUY2,width=1920,height=1080,framerate=30/1 \
    ! identity drop-allocation=true \
    ! v4l2sink device=/dev/video99 sync=false
