#!/bin/bash
# Start integrated camera feed to v4l2loopback for app compatibility
# Usage: sudo ./start-camera.sh

set -e

# Load IPU6 driver stack
modprobe -a usbio gpio-usbio i2c-usbio intel-ipu6-psys 2>/dev/null || true
sleep 2

# Reload v4l2loopback
modprobe -r v4l2loopback 2>/dev/null || true
modprobe v4l2loopback video_nr=99 card_label="Integrated Camera" exclusive_caps=1

export GST_PLUGIN_PATH=/usr/lib/gstreamer-1.0

exec gst-launch-1.0 -e \
    icamerasrc buffer-count=7 \
    ! video/x-raw,format=NV12,width=1280,height=720 \
    ! videoconvert \
    ! video/x-raw,format=YUY2,width=1280,height=720,framerate=30/1 \
    ! identity drop-allocation=true \
    ! v4l2sink device=/dev/video99 sync=false
