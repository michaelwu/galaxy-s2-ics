#!/bin/bash

# Copyright (C) 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

DEVICE=galaxys2
COMMON=c1-common
MANUFACTURER=samsung

if [[ -z "${ANDROIDFS_DIR}" ]]; then
    DEVICE_BUILD_ID=`adb shell cat /system/build.prop | grep ro.build.display.id | sed -e 's/ro.build.display.id=//' | tr -d '\n'`
else
    DEVICE_BUILD_ID=`cat ${ANDROIDFS_DIR}/system/build.prop | grep ro.build.display.id | sed -e 's/ro.build.display.id=//' | tr -d '\n'`
fi

case "$DEVICE_BUILD_ID" in
"IML74K.XXLPQ")
  FIRMWARE=XXLPQ ;;
*)
  echo Your device has unknown firmware $DEVICE_BUILD_ID >&2
  exit 1 ;;
esac

BASE_PROPRIETARY_COMMON_DIR=vendor/$MANUFACTURER/$COMMON/proprietary
PROPRIETARY_DEVICE_DIR=../../../vendor/$MANUFACTURER/$DEVICE/proprietary
PROPRIETARY_COMMON_DIR=../../../$BASE_PROPRIETARY_COMMON_DIR

mkdir -p $PROPRIETARY_DEVICE_DIR

for NAME in audio cameradata egl firmware hw keychars wifi media
do
    mkdir -p $PROPRIETARY_COMMON_DIR/$NAME
done

# galaxys2


# c1-common
(cat << EOF) | sed s/__DEVICE__/$DEVICE/g | sed s/__MANUFACTURER__/$MANUFACTURER/g > ../../../vendor/$MANUFACTURER/$DEVICE/$DEVICE-vendor-blobs.mk
# Copyright (C) 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Prebuilt libraries that are needed to build open-source libraries
PRODUCT_COPY_FILES := \\

# All the blobs necessary for galaxys2 devices
PRODUCT_COPY_FILES += \\

EOF

COMMON_BLOBS_LIST=../../../vendor/$MANUFACTURER/$COMMON/c1-vendor-blobs.mk

(cat << EOF) | sed s/__COMMON__/$COMMON/g | sed s/__MANUFACTURER__/$MANUFACTURER/g > $COMMON_BLOBS_LIST
# Copyright (C) 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Prebuilt libraries that are needed to build open-source libraries
PRODUCT_COPY_FILES := device/sample/etc/apns-full-conf.xml:system/etc/apns-conf.xml

# All the blobs necessary for galaxys2 devices
PRODUCT_COPY_FILES += \\
EOF

# copy_file
# pull file from the device and adds the file to the list of blobs
#
# $1 = src name
# $2 = dst name
# $3 = directory path on device
# $4 = directory name in $PROPRIETARY_COMMON_DIR
copy_file()
{
    echo Pulling \"$1\"
    if [[ -z "${ANDROIDFS_DIR}" ]]; then
        adb pull /$3/$1 $PROPRIETARY_COMMON_DIR/$4/$2
    else
           # Hint: Uncomment the next line to populate a fresh ANDROIDFS_DIR
           #       (TODO: Make this a command-line option or something.)
           # adb pull /$3/$1 ${ANDROIDFS_DIR}/$3/$1
        cp ${ANDROIDFS_DIR}/$3/$1 $PROPRIETARY_COMMON_DIR/$4/$2
    fi

    if [[ -f $PROPRIETARY_COMMON_DIR/$4/$2 ]]; then
        echo   $BASE_PROPRIETARY_COMMON_DIR/$4/$2:$3/$2 \\ >> $COMMON_BLOBS_LIST
    else
        echo Failed to pull $1. Giving up.
        exit -1
    fi
}

# copy_files
# pulls a list of files from the device and adds the files to the list of blobs
#
# $1 = list of files
# $2 = directory path on device
# $3 = directory name in $PROPRIETARY_COMMON_DIR
copy_files()
{
    for NAME in $1
    do
        copy_file "$NAME" "$NAME" "$2" "$3"
    done
}

# copy_local_files
# puts files in this directory on the list of blobs to install
#
# $1 = list of files
# $2 = directory path on device
# $3 = local directory path
copy_local_files()
{
    for NAME in $1
    do
        echo Adding \"$NAME\"
        echo device/$MANUFACTURER/$DEVICE/$3/$NAME:$2/$NAME \\ >> $COMMON_BLOBS_LIST
    done
}

COMMON_LIBS="
	libsecril-client.so
	libsec-ril.so
        libMali.so
	libUMP.so
	libakm.so
	libs5pjpeg.so
	libtvoutservice.so
	libtvoutinterface.so
	libhdmiclient.so
	"

copy_files "$COMMON_LIBS" "system/lib" ""

if [[ -z "${ANDROIDFS_DIR}" ]]; then
   HCDNAME=`basename \`adb shell ls /system/bin/*.hcd\` | tr -d '\r'`
else
   HCDNAME=`basename ${ANDROIDFS_DIR}/system/bin/*.hcd`
fi
COMMON_BINS="
	playlpm
	immvibed
	lpmkey
	rild
	${HCDNAME}
	"
copy_files "$COMMON_BINS" "system/bin" ""

COMMON_CAMERADATA="
	datapattern_420sp.yuv
	datapattern_front_420sp.yuv
	"
copy_files "$COMMON_CAMERADATA" "system/cameradata" "cameradata"

COMMON_EGL="
	egl.cfg
	libEGL_mali.so
	libGLES_android.so
	libGLESv1_CM_mali.so
	libGLESv2_mali.so
	"
copy_files "$COMMON_EGL" "system/lib/egl" "egl"

COMMON_FIRMWARE="
	RS_M5LS_TB.bin
	"
copy_files "$COMMON_FIRMWARE" "system/etc/firmware" "firmware"
copy_files "libpn544_fw.so" "system/vendor/firmware" "firmware"

COMMON_HW="
	alsa.default.so
	audio.a2dp.default.so
	audio_policy.default.so
	audio_policy.exynos4.so
	audio.primary.default.so
	audio.primary.exynos4.so
	audio.primary.goldfish.so
	camera.exynos4.so
	gps.exynos4.so
	gralloc.exynos4.so
	hwcomposer.exynos4.so
	lights.exynos4.so
	sensors.default.so
	"
copy_files "$COMMON_HW" "system/lib/hw" "hw"

COMMON_IDC="
	melfas_ts.idc
	qwerty2.idc
	sec_touchscreen.idc
	mxt224_ts_input.idc
	qwerty.idc
	"
copy_local_files "$COMMON_IDC" "system/usr/idc" "idc"

COMMON_KEYCHARS="
	Generic.kcm
	qwerty.kcm
	qwerty2.kcm
	Virtual.kcm
	"
copy_files "$COMMON_KEYCHARS" "system/usr/keychars" "keychars"

COMMON_WIFI="
	bcm4330_apsta.bin
	bcm4330_mfg.bin
	bcm4330_p2p.bin
	bcm4330_sta.bin
	nvram_mfg.txt
	nvram_net.txt
	nvram_net.txt_AU
	nvram_net.txt_IL
	nvram_net.txt_murata
	nvram_net.txt_murata_AU
	nvram_net.txt_murata_IL
	nvram_net.txt_murata_SG
	nvram_net.txt_murata_TN
	nvram_net.txt_SG
	nvram_net.txt_TN
	wpa_supplicant.conf
	"
copy_files "$COMMON_WIFI" "system/etc/wifi" "wifi"

COMMON_MDNIE_MODE="
	mdnie_tune_bypass_mode
	mdnie_tune_camera_mode
	mdnie_tune_camera_outdoor_mode
	mdnie_tune_dynamic_mode
	mdnie_tune_gallery_mode
	mdnie_tune_movie_mode
	mdnie_tune_outdoor_mode
	mdnie_tune_standard_mode
	mdnie_tune_ui_dynamic_mode
	mdnie_tune_ui_movie_mode
	mdnie_tune_ui_standard_mode
	mdnie_tune_video_cold_mode
	mdnie_tune_video_cold_outdoor_mode
	mdnie_tune_video_mode
	mdnie_tune_video_warm_mode
	mdnie_tune_video_warm_outdoor_mode
	"
copy_files "$COMMON_MDNIE_MODE" "system/etc" "etc"

COMMON_WIFI_LIBS="
	libhardware_legacy.so
	libnetutils.so
	"
copy_files "$COMMON_WIFI_LIBS" "system/lib" "wifi"

COMMON_AUDIO="
	libmediayamahaservice.so
	libsamsungSoundbooster.so
	libsamsungAcousticeq.so
	libsoundalive.so
	libsoundspeed.so
	libaudiohw.so
	"
copy_files "$COMMON_AUDIO" "system/lib" "audio"

COMMON_MEDIA="
	battery_batteryerror.qmg
	battery_charging_45.qmg
	battery_charging_85.qmg
	battery_charging_100.qmg
	battery_charging_50.qmg
	battery_charging_90.qmg
	battery_charging_10.qmg
	battery_charging_55.qmg
	battery_charging_95.qmg
	battery_charging_15.qmg
	battery_charging_5.qmg
	battery_error.qmg
	battery_charging_20.qmg
	battery_charging_60.qmg
	bootsamsungloop.qmg
	battery_charging_25.qmg
	battery_charging_65.qmg
	bootsamsung.qmg
	battery_charging_30.qmg
	battery_charging_70.qmg
	chargingwarning.qmg
	battery_charging_35.qmg
	battery_charging_75.qmg
	Disconnected.qmg
	battery_charging_40.qmg
	battery_charging_80.qmg
"
copy_files "$COMMON_MEDIA" "system/media" "media"

./setup-makefiles.sh
