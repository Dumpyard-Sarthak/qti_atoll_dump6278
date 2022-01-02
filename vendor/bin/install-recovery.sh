#!/vendor/bin/sh
if ! applypatch --check EMMC:/dev/block/bootdevice/by-name/recovery:100663296:42f2c98b9da86fa32e3589539e0a409e1ed6157c; then
  applypatch  \
          --patch /vendor/recovery-from-boot.p \
          --source EMMC:/dev/block/bootdevice/by-name/boot:67108864:1a3793432c37dd45f2adcf96a82300e15bff53e9 \
          --target EMMC:/dev/block/bootdevice/by-name/recovery:100663296:42f2c98b9da86fa32e3589539e0a409e1ed6157c && \
      log -t recovery "Installing new oppo recovery image: succeeded" && \
      setprop ro.boot.recovery.updated true || \
      log -t recovery "Installing new oppo recovery image: failed" && \
      setprop ro.boot.recovery.updated false
else
  log -t recovery "Recovery image already installed"
  setprop ro.boot.recovery.updated true
fi
