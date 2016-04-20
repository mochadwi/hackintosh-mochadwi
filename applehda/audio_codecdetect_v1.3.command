#!/bin/sh
# Maintained by: toleda for: github.com/toleda/audio_realtekALC
gFile="File: audio_codecdetect.command_v1.4"
# Credit: pikeralpha, ?? 
#
# OS X: Detect and identify installed audio codecs, device name and layout-id
#
# Requirement
# 1. AppleHDA.kext
#
# Installation
# 1. Double click: Downloads/audio_codecdetect.command
#
#initial global variables
gDebug=0
gSysVer=`sw_vers -productVersion`
gSysName="El Capitan"
#
# debug
if [ $gDebug = 2 ]; then
echo "gDebug = $gDebug"
fi
#
# initialize local variables
ghdefpciname=NONE
intel=n
amd=n
nvidia=n
realtek=n
unknown=n
validdevice=n
validname=n
validaudioid=n
index=0
#
#
echo $gFile
#
# verify system version
case ${gSysVer} in

10.11* ) gSysName="El Capitan"
gSID=$(csrutil status)
;;

10.10* ) gSysName="Yosemite"
;;

10.9* ) gSysName="Mavericks"
;;

10.8* ) gSysName="Mountain Lion"
;;

* )
echo "OS X Version: $gSysVer is not supported"
echo "No system files were changed"
echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
exit 1
;;

esac

# debug
if [ $gDebug = 2 ]; then
# gSysVer=10.9
echo "System version: supported"
echo "gSysVer = $gSysVer"
fi

#
# detect installed codecs
gCodecsinstalled=$(ioreg -rxn IOHDACodecDevice | grep VendorID | awk '{ print $4 }' | sed -e 's/ffffffff//')

# gCodecsinstalled=0x10ec0900  ## debug

# debug
if [ $gDebug = 2 ]; then
echo "gCodecsinstalled:"
echo "${gCodecsinstalled[*]}"
# gCodecsinstalled=0x10ec0887
# gCodecsinstalled=0x10ec0900 ## debug
# gCodecsinstalled=0x10ec0898
# gCodecsinstalled=0x10134206
# echo "gCodecsinstalled = $gCodecsinstalled"
fi

# no codecs detected
if [ -z "${gCodecsinstalled}" ]; then
# if [ -z "$gCodecsinstalled" ]; then
echo ""
echo "No audio codec detected"
echo "Verify BIOS, hardware, etc."
echo ""
exit 0
fi

# identify installed codecs
for codec in $gCodecsinstalled
do

case ${codec:2:4} in

8086 ) Codecintelhdmi=$codec
intel=y
;;
1002 ) Codecamdhdmi=$codec
amd=y
;;
10de ) Codecnvidiahdmi=$codec
nvidia=y
;;
10ec ) realtekaudiocodec=$codec
realtek=y
;;
*) Codecunknownaudio=$codec
unknown=y

;;
esac
index=$((index + 1))
done

# report installed codes
echo ""
echo "HDMI audio codec(s)"
if [ $intel = y ]; then
echo "Intel:    $Codecintelhdmi"
fi
if [ $amd = y ]; then
echo "AMD:      $Codecamdhdmi"
fi
if [ $nvidia = y ]; then
echo "Nvidia:   $Codecnvidiahdmi"
fi
echo ""
echo "Onboard audio codec"
if [ $realtek = y ]; then
case ${realtekaudiocodec:6:4} in
0269|0283|0885|0887|0888|0889|0892|0899|0900 )
echo "Realtek: $realtekaudiocodec"
validdevice=y
;;

*)
echo "Device: Not supported"
echo "Realtek: $realtekaudiocodec"
;;
esac

fi

# special names
if [ $realtek = y ]; then
gCodecDevice=${realtekaudiocodec:6:4}

# debug
if [ $gDebug = 2 ]; then
echo "gCodecDevice = $gCodecDevice"
fi

if [ ${gCodecDevice:0:1} = 0 ]; then
gCodecName=${gCodecDevice:1:3}
fi

if [ $gCodecDevice = "0899" ]; then
gCodecName=898
fi

if [ $gCodecDevice = "0900" ]; then
gCodecName=1150
fi

# debug
if [ $gDebug = 2 ]; then
echo "Codec identification: success"
fi

fi

if [ $unknown = y ]; then
echo "Codec: Not supported"
echo "Unknown: $Codecunknownaudio"
echo "Unsupported codec, consider Voodoo/Google search for compatible AppleHDA.kext"
# echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
# echo ""
# exit 0
fi

# echo ""
# echo "Codec: ALC$gCodecName"

# get acpi pcie hdef device name
numname=5
ghdefname[1]=HDEF@1B
ghdefname[2]=AZAL@1B
ghdefname[3]=ALZA@1B
ghdefname[4]=HDAS@1F,3
ghdefname[5]=HDAU@1B

index=1

# debug
if [ $gDebug = 2 ]; then
echo "index = $index"
echo "numname = $numname"
fi

while [ $index -le $numname ]; do
hdefpciname=$(ioreg -rxn ${ghdefname[$index]} | grep vendor-id| awk '{ print $4 }')

# debug
if [ $gDebug = 2 ]; then
echo "index = $index"
echo "ghdefname = ${ghdefname[$index]}"
echo "hdefpciname = $hdefpciname"
fi

if [ -n "${hdefpciname}" ]; then
hdefindex1=$index
index=$(($numname + 1))
fi

index=$(($index + 1))
done

ghdefpciname=${ghdefname[$hdefindex1]}

# debug
if [ $gDebug = 2 ]; then
echo "hdefindex1 = $hdefindex1"
echo "hdefpciname = $hdefpciname"
fi

# debug
if [ $gDebug = 2 ]; then
# validname=n
# ghdefpciname="HDAS@1F,3"  ## debug
# ghdefpciname="HDAU@1B"  ## debug
# ghdefpciname="HDEF@1B"  ## debug
echo "validname = $validname"
echo "ghdefpciname = $ghdefpciname"
fi

ghdefpcinamel=$(echo "${ghdefpciname:0:4}" | tr '[:upper:]' '[:lower:]')


# debug
if [ $gDebug = 2 ]; then
echo "ghdefpcinamel = $ghdefpcinamel"
fi

# valid os x/ioreg audio device
case ${ghdefpciname:0:4} in

HDEF )
validname=y
validaudioid1=3
ghdefpciname1="with_ioreg/${ghdefpcinamel}"
;;

ALZA )
validaudioid1=1
ghdefpciname1="x99-${ghdefpcinamel}"
;;

AZAL )
validaudioid1=1
ghdefpciname1="with_ioreg/${ghdefpcinamel}"
;;

HDAS )
validaudioid1=3
ghdefpciname1="100-${ghdefpcinamel}"
;;

HDAU )
echo "Unsupported ssdt, remove"
echo "No system files were changed"
echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
exit 1
;;

NONE )
echo "Error: audio device not found, unknown acpi PCI0 name"
echo "https://github.com/toleda/audio_ALCInjection/tree/master/ssdt_hdef/ssdt_hdef-1-no_ioreg/hdef"
echo "No system files were changed"
echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
exit 1
;;

esac

# debug
if [ $gDebug = 2 ]; then
echo "validaudioid1 = $validaudioid1"
echo "ghdefpciname1 = $ghdefpciname1"
fi


# debug
if [ $gDebug = 2 ]; then
echo "validname = $validname"
echo "ghdefpciname = $ghdefpciname"
fi

echo
echo "OS X/$gSysVer Onboard Audio"
echo "Device: ${ghdefpciname}"

# ioreg -rxn HDEF@1B | grep layout-id | sed -e 's/.*<//' -e 's/>//'
# echo $(cat /tmp/HDEF.txt | grep -c HDEF@1B)

# verify ioreg/HDEF
ioreg -rw 0 -p IODeviceTree -n $ghdefpciname > /tmp/HDEF.txt

if [[ $(cat /tmp/HDEF.txt | grep -c $ghdefpciname) != 0 ]]; then
gLayoutidioreg=$(cat /tmp/HDEF.txt | grep layout-id | sed -e 's/.*<//' -e 's/>//')
gLayoutidhex="${gLayoutidioreg:6:2}${gLayoutidioreg:4:2}${gLayoutidioreg:2:2}${gLayoutidioreg:0:2}"
hexNum=$gLayoutidhex
hexNum=${hexNum#*x}
gAudioid=$((16#$hexNum))

# gAudioid=0  ## debug
# ghdefpciname="HDAS@1F,3"  ## debug



# debug
if [ $gDebug = 2 ]; then
echo "gLayoutidioreg = $gLayoutidioreg"
echo "gLayoutidhex = $gLayoutidhex"
echo "hexNum = $hexNum"
echo "gAudioid = $gAudioid"
fi

else
echo "Error: no IOReg/HDEF; BIOS/audio/disabled or ACPI problem"
echo "If ACPI problem, try ssdt_hdef-1-no_ioreg/hdef"
echo "No system files were changed"
echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
exit 0  ##
fi

# exit if error
if [ "$?" != "0" ]; then
echo "Error: codec detection failed"
rm -R /tmp/HDEF.txt
echo "No system files were changed"
echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
exit 1
fi

# debug
if [ $gDebug = 2 ]; then
# gAudioid=0
# gAudioid=1  ## debug
# gAudioid=2
# gAudioid=3
# ghdefpciname="HDAS"  ## debug
echo "Realtek: $realtekaudiocodec"
echo "gAudioid = $gAudioid"
echo "ghdefpciname = $ghdefpciname"
fi

case ${realtekaudiocodec:6:4} in

0269|0283|0885 )
validaudioid1=1
if [ $gAudioid = 1 ]; then
validaudioid=y
fi
;;

0887|888|889|0892|0899|0900 )
validaudioid1=3
if [[ $gAudioid = 1 || $gAudioid = 2 || $gAudioid = 3 ]]; then
validaudioid=y
fi
;;

esac

rm -R /tmp/HDEF.txt

if [ $validaudioid = y ]; then
echo "Audio ID: $gAudioid"
fi

# ssdt_hdef-1-100-hdas.zip
# ssdt_hdef-3-100-hdas
# ssdt_hdef-1-with_ioreg/azal.zip
# ssdt_hdef-1-no_ioreg/hdef
# ssdt_hdef-2-no_ioreg/hdef
# ssdt_hdef-1-with_ioreg/hdef.zip
# ssdt_hdef-1-x99-alza
# ssdt_hdef-1-x99-alza
# echo "$(echo "$y" | tr '[:upper:]' '[:lower:]')"
# ghdefpciname="HDEF@1B"
# echo "$(echo "${ghdefpciname:0:4}" | tr '[:upper:]' '[:lower:]')"

# validname=n  ## debug

# debug
if [ $gDebug = 2 ]; then
echo "validaudioid = $validaudioid"
echo "validname = $validname"
fi

if [[ $validname = n || $validaudioid = n ]]; then

if [ $validaudioid = n ]; then
echo "Audio ID: Not supported"
echo "Currrent Audio ID: $gAudioid (set: 1, 2, or 3)"
fi

if [ $validname = n ]; then
echo "Device: Not supported"
echo "Currrent Device: $ghdefpciname (HDEF required)"
fi

echo "Fix, try:"

case $validaudioid1 in

1 )
echo "1. https://github.com/toleda/audio_ALCInjection/tree/master/ssdt_hdef/"
echo "ssdt_hdef-1-${ghdefpciname1}.zip (select View Raw)"
if [ ${ghdefpciname:0:4} = "HDEF" ]; then
echo "2. CLOVER/config.plist/Devices/Audio/Inject/1"
fi
echo ""
echo "No system files were changed"
echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
exit 0
;;

3 )
echo "1. https://github.com/toleda/audio_ALCInjection/tree/master/ssdt_hdef/"
echo "ssdt_hdef-1-${ghdefpciname1}.zip (or -2 or -3, select View Raw)"
if [ ${ghdefpciname:0:4} = "HDEF" ]; then
echo "2. CLOVER/config.plist/Devices/Audio/Inject/1 (or 2 or 3)"
fi
echo ""
echo "No system files were changed"
echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
exit 0
;;
esac

fi

if [ $unknown = y ]; then
echo "Unsupported codec, consider Voodoo/Google search"
echo "No system files were changed"
# echo "To save a Copy of this Terminal session: Terminal/Shell/Export Text As ..."
# echo ""
# exit 0
fi


if [[ $realtek = y || validdevice = y || $validname = y || $validaudioid = y ]]; then
echo ""
echo "Valid audio codec, audio device and Audio ID; audio injection is working"
fi

echo "Finished"
echo ""

exit

y="HDEF"
echo "$(echo "$y" | tr '[:upper:]' '[:lower:]')"