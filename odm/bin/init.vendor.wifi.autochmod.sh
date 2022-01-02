#!/vendor/bin/sh
#***********************************************************
#** Copyright (C), 2019-2029, OPPO Mobile Comm Corp., Ltd
#** All rights reserved.
#**
#** File: - vendor.wifi.autochmod.sh
#** Description: vendor domain operation
#**
#** Version: 1.1
#** Date : 2020/02/20
#** Author: JiaoBo
#** TAG: CONNECTIVITY.WIFI.BASIC.HARDWARE
#** ---------------------Revision History: ---------------------
#**  <author>    <data>       <version >       <desc>
#**  Jiao.Bo       2020/02/20     1.0     build this module
#****************************************************************/

config="$1"


#ifdef OPLUS_FEATURE_WIFI_RUSUPGRADE
#JiaoBo@CONNECTIVITY.WIFI.BASIC.HARDWARE.2795386, 2020/02/20
#add for: support auto update function, include mtk fw, mtk wifi.cfg, qcom fw, qcom bdf, qcom ini
#common info
defaultVersion="20190101000000"
nullVersion="null"
rusEntityConfigXmlfile=/odm/etc/vendor_wifi_rus_config.xml
isConfigXmlParseDone="false"
#mtk platform info
mtkWifirusEntityVersionList="null;null;null;null;null"
mtkWifirusEntityTypeList=("wifi.cfg" "wifi.fw" "wifi.nv")
mtkWifirusEntityVersionFileNameList=(
"wifi.cfg"
"WIFI_RAM_CODE_soc2_0_3a_1.bin"
"WIFI")
mtkWifirusEntityFileNameList=(
"wifi.cfg"
"WIFI_RAM_CODE_soc2_0_3a_1.bin;soc2_0_ram_wifi_3a_1_hdr.bin;soc2_0_ram_bt_3a_1_hdr.bin;soc2_0_ram_mcu_3a_1_hdr.bin;soc2_0_patch_mcu_3a_1_hdr.bin"
"WIFI")
mtkWifirusEntityVendorPathList=(
"/vendor/firmware/"
"/vendor/firmware/"
"/vendor/firmware/")
#qcom paltform info
qcomWifirusEntityVersionList="null;null;null"
qcomWifirusEntityTypeList=("wifi.ini" "wifi.fw" "wifi.bdf")
qcomWifirusEntityVersionFileNameList=(
"WCNSS_qcom_cfg.ini"
"wlandsp.mbn"
"bin_version")
qcomWifirusEntityFileNameList=(
"WCNSS_qcom_cfg.ini"
"wlandsp.mbn"
"bin_version;bdwlan.bin")
qcomWifirusEntityVendorPathList=(
"/vendor/firmware_mnt/"
"/vendor/firmware_mnt/"
"/vendor/firmware_mnt/")

#function: get the entity type index
function getrusEntityTypeIdx() {
    local platform=$1
    local type=$2
    if [ "$platform" = "mtk" ]; then
        if [ "$type" = "wifi.cfg" ]; then
            return 0
        elif [ "$type" = "wifi.fw" ]; then
            return 1
        elif [ "$type" = "wifi.nv" ]; then
            return 2
        fi
    elif [ "$platform" = "qcom" ]; then
        if [ "$type" = "wifi.ini" ]; then
            return 0
        elif [ "$type" = "wifi.fw" ]; then
            return 1
        elif [ "$type" = "wifi.bdf" ]; then
            return 2
        fi
    fi
    return 0
}

#function: get the vendor suppprt Entity file name which include version information
function parseSupportrusEntityConfigXml() {
    local board=`getprop ro.board.platform`
    if [ "$isConfigXmlParseDone" = "false" ]; then
        local cmd=`sed -n -e 's/<Entity //' -e 's/\/>//p' $rusEntityConfigXmlfile | sed -e 's/platform="//' -e 's/type="//' -e 's/versionFileName="//' -e 's/fileNameList="//' -e 's/"//g'`
        execute=($(echo $cmd))
        local length=${#execute[*]}
        local i=0
        while [ i -lt length ]
        do
            local platform=${execute[i]}
            local type=${execute[++i]}
            local versionFileName=${execute[++i]}
            local fileNameList=${execute[++i]}
            local typeIdx
            if [[ $board == *"mt"* ]] || [[ $board == *"Mt"*  ]] || [[ $board == *"MT"*  ]];then
                getrusEntityTypeIdx "mtk" $type
                typeIdx=$?
                if [ "$platform" = "$board" ]; then
                    mtkWifirusEntityVersionFileNameList[typeIdx]=$versionFileName
                    mtkWifirusEntityFileNameList[typeIdx]=$fileNameList
                    echo "index=$i Entity$typeIdx: platform:$platform type:$type"
                    echo "         versionFileName:${mtkWifirusEntityVersionFileNameList[typeIdx]}"
                    echo "         fileNameList:${mtkWifirusEntityFileNameList[typeIdx]}"
                fi
            else
                getrusEntityTypeIdx "qcom" $type
                typeIdx=$?
                if [ "$platform" = "$board" ]; then
                    qcomWifirusEntityVersionFileNameList[typeIdx]=$versionFileName
                    qcomWifirusEntityFileNameList[typeIdx]=$fileNameList
                    echo "index=$i Entity$typeIdx: platform:$platform type:$type"
                    echo "         versionFileName:${qcomWifirusEntityVersionFileNameList[typeIdx]}"
                    echo "         fileNameList:${qcomWifirusEntityFileNameList[typeIdx]}"
                fi
            fi
            i=$((i+1))
        done
        isConfigXmlParseDone="true"
    else
        echo "already parse done."
    fi
}

#function: get all vendor suppprt Entity version for mtk
function rusMtkWifiObjsVendorVerGet() {
    parseSupportrusEntityConfigXml
    mtkWifirusEntityVersionList=""
    local length=${#mtkWifirusEntityTypeList[@]}
    local i=0
    while [ i -lt length ]
    do
        local type=${mtkWifirusEntityTypeList[i]}
        local file=${mtkWifirusEntityVendorPathList[i]}${mtkWifirusEntityVersionFileNameList[i]}
        if [ -f $file ]; then
            if [ "$type" = "wifi.cfg" ]; then
                str=`head -c 25 $file`
                version=${str:9:14}
            elif [ "$type" = "wifi.fw" ]; then
                str=`tail -c 19 $file`
                version=${str:0:14}
            elif [ "$type" = "wifi.nv" ]; then
                #default not support update this entity
                version=$nullVersion
            else
                version=$nullVersion
            fi
        else
            version=$nullVersion
        fi
        mtkWifirusEntityVersionList+=$version";"
        i=$((i+1))
    done
    mtkWifirusEntityVersionList=${mtkWifirusEntityVersionList%;*}
    echo "mtkWifirusEntityVersionList=$mtkWifirusEntityVersionList"
}

#function: get all vendor suppprt Entity version for qcom
function rusQcomWifiObjsVendorVerGet() {
    parseSupportrusEntityConfigXml
    qcomWifirusEntityVersionList=""
    local length=${#qcomWifirusEntityTypeList[@]}
    local i=0
    while [ i -lt length ]
    do
        local type=${qcomWifirusEntityTypeList[i]}
        local file=${qcomWifirusEntityVendorPathList[i]}${qcomWifirusEntityVersionFileNameList[i]}
        if [ -f $file ]; then
            if [ "$type" = "wifi.ini" ]; then
                #default not support update this entity
                version=$nullVersion
            elif [ "$type" = "wifi.fw" ]; then
                #default not support update this entity
                version=$nullVersion
            elif [ "$type" = "wifi.bdf" ]; then
                #default not support update this entity
                version=$nullVersion
            else
                version=$nullVersion
            fi
        else
            version=$nullVersion
        fi
        qcomWifirusEntityVersionList+=$version";"
        i=$((i+1))
    done
    qcomWifirusEntityVersionList=${qcomWifirusEntityVersionList%;*}
    echo "qcomWifirusEntityVersionList=$qcomWifirusEntityVersionList"
}

#function: set the versionlist to attribute when bootup
function rusWifiVendorVerBootCheck() {
    local platform
    local board=`getprop ro.board.platform`
    if [[ $board == *"mt"* ]] || [[ $board == *"Mt"*  ]] || [[ $board == *"MT"*  ]];then
        platform="mtk"
    else
        platform="qcom"
    fi

    if [ "$platform" = "mtk" ]; then
        rusMtkWifiObjsVendorVerGet
        setprop vendor.oplus.wifi.rus.version $mtkWifirusEntityVersionList
    elif [ "$platform" = "qcom" ]; then
        rusQcomWifiObjsVendorVerGet
        setprop vendor.oplus.wifi.rus.version $qcomWifirusEntityVersionList
    fi
    setprop vendor.oplus.wifi.rus.upgrade.ctl "vendor-bootcheck-done"
}

#function: set the versionlist to attribute when rus upgrade
function rusWifiVendorVerUpgradeCheck() {
    local platform
    local board=`getprop ro.board.platform`
    if [[ $board == *"mt"* ]] || [[ $board == *"Mt"*  ]] || [[ $board == *"MT"*  ]];then
        platform="mtk"
    else
        platform="qcom"
    fi
    echo "rusWifiVendorVerUpgradeCheck platform=$platform"

    if [ "$platform" = "mtk" ]; then
        rusMtkWifiObjsVendorVerGet
        setprop vendor.oplus.wifi.rus.version $mtkWifirusEntityVersionList
    elif [ "$platform" = "qcom" ]; then
        rusQcomWifiObjsVendorVerGet
        setprop vendor.oplus.wifi.rus.version $qcomWifirusEntityVersionList
    fi
    setprop vendor.oplus.wifi.rus.upgrade.ctl "vendor-upgradeCheck-done"
}
#endif /* OPLUS_FEATURE_WIFI_RUSUPGRADE */

#ifdef OPLUS_FEATURE_WIFI_DUMP
#JiaoBo@CONNECTIVITY.WIFI.BASIC.LOG.1162003, 2018/7/02
#add for wifi dump related log collection and DCS handle, dynamic enable/disable wifi core dump, offer trigger wifi dump API.
QCOM_DUMP_PATH="/data/vendor/tombstones/rfs/modem/*"
QCOM_ATOLL_DUMP_PATH="/data/vendor/ramdump/ramdump_wlan*"
MTK_DUMP_PATH="/data/vendor/connsyslog/wifi/*"
function clearWifiDumpFile() {
    local platform=`getprop ro.board.platform`
    if [[ $platform == *"mt"* ]] || [[ $platform == *"Mt"*  ]] || [[ $platform == *"MT"*  ]];then
        rm -rf $MTK_DUMP_PATH
    else
        if [ "x${platform}" == "xatoll" ];then
            rm -rf $QCOM_ATOLL_DUMP_PATH
        else
            rm -rf $QCOM_DUMP_PATH
        fi
    fi
}

# suppot: 1. qcom minidump; 2. mtk soc3 coredump; 3. mtk soc2 coredump
function triggerwifidump() {
    platform=`getprop ro.board.platform`
    if [[ $platform == *"mt"* ]] || [[ $platform == *"Mt"*  ]] || [[ $platform == *"MT"*  ]];then
        echo "mtk trigger firmware assert"
        if ["$platform" = 'mt6779'] || ["$platform" = 'mt6853'] || ["$platform" = 'mt6873'] || ["$platform" = 'mt6771'] ; then
            echo DB9DB9 > /proc/driver/wmt_dbg
            echo 4 0 > /proc/driver/wmt_dbg
        elif ["$platform" = 'mt6885'] || ["$platform" = 'mt6889']; then
            /odm/bin/iwpriv_vendor wlan0 driver 'SET_WFSYS_RESET'
        else
            echo "unsupport platform."
        fi
    else
        echo "qcom trigger firmware assert"
            /odm/bin/iwpriv_vendor wlan0 crash_inject 1 0
    fi
}
#endif /* OPLUS_FEATURE_WIFI_DUMP */

case "$config" in
    #ifdef OPLUS_FEATURE_WIFI_DUMP
    #JiaoBo@CONNECTIVITY.WIFI.BASIC.LOG.1162003, 2018/7/02
    #add for wifi dump related log collection and DCS handle, dynamic enable/disable wifi core dump, offer trigger wifi dump API.
    "clearWifiDumpFile")
    clearWifiDumpFile
    ;;
    "triggerwifidump")
    triggerwifidump
    ;;
    #endif /* OPLUS_FEATURE_WIFI_DUMP */
    #ifdef OPLUS_FEATURE_WIFI_RUSUPGRADE
    #JiaoBo@CONNECTIVITY.WIFI.BASIC.HARDWARE.2795386, 2020/02/20
    #add for: support auto update function, include mtk fw, mtk wifi.cfg, qcom fw, qcom bdf, qcom ini
    "rusWifiVendorVerBootCheck")
    rusWifiVendorVerBootCheck
    ;;
    "rusWifiVendorVerUpgradeCheck")
    rusWifiVendorVerUpgradeCheck
    ;;
    #endif /* OPLUS_FEATURE_WIFI_RUSUPGRADE */
esac
