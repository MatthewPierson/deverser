#!/bin/sh

if [ -f "dump.raw" ]; then
    rm -rf dump.raw
fi

cat << "intro"
[!] Welcome to Déverser, a simple script to dump onboard SHSH (Blobs) with a valid Generator for iOS devices...
[!] This script will allow you to use dumped blobs with futurerestore at a later date (depending on SEP compatibility)...
intro

unamestr=$(uname)
if [ "$unamestr" = "Darwin" ]; then
    OS=macos
    echo "[!] macOS detected!"
elif [ "$unamestr" = "Linux" ]; then
    OS=ubuntu
    echo "[!] Linux detected!"
else
    echo "Not running on macOS or Linux. exiting..."
    exit 1
fi

if which curl >/dev/null; then
    echo "[i] curl is installed!"
else
    echo "[!] Please install curl before running this script"
    exit 2
fi

if which img4tool >/dev/null; then
    echo "[!] Found img4tool at $(which img4tool)!"
else
    echo "[#] img4tool is not installed, do you want Déverser to download and install img4tool? (If no then the script will close, img4tool is needed)"
    echo "[*] Please enter 'Yes' or 'No':"
    read -r consent
    case $consent in 
        [Yy]* )
            echo "[!] Downloading latest img4tool from Tihmstar's repo..."
            latestBuild=$(curl --silent "https://github.com/tihmstar/img4tool/releases" | grep -Eo "/tihmstar/img4tool/releases/download/\d+" | head -1)
            curl -L "https://github.com/$latestBuild/buildroot_$OS-latest.zip" -o img4tool-latest.zip
            
            IMG4TOOL_TEMP=$(mktemp -d 'img4tool.XXXXXXX')
            unzip -q img4tool-latest.zip -d "$IMG4TOOL_TEMP"
            echo "[*] Terminal may ask for permission to move the files into '/usr/local/bin' and '/usr/local/include', please enter your password if it does..."
            sudo install -m755 "$IMG4TOOL_TEMP/buildroot_$OS-latest/usr/local/bin/img4tool" /usr/local/bin/img4tool
            sudo cp -R "$IMG4TOOL_TEMP/buildroot_$OS-latest/usr/local/include/img4tool" /usr/local/include

            rm -rf img4tool-latest.zip "$IMG4TOOL_TEMP"
            ;;
        * )
            echo "[#] img4tool is needed for this script to work..."
            echo "[#] If you want to manually install it, you can download img4tool from 'https://github.com/tihmstar/img4tool/releases/latest' and manually move the files to the correct locations..."
            exit
            ;;
    esac
fi
echo "[!] Please enter your device's IP address (Found in wifi settings)..."
read -r ip
echo "Device's IP address is $ip"
echo "[*] Assuming given IP to be correct, if connecting to the device fails ensure you entered the IP correctly and have OpenSSh installed..."
echo "[!] Please enter the device's root password (Default is 'alpine')..."
ssh root@$ip 'cat /dev/rdisk1 | dd of=dump.raw bs=256 count=$((0x4000))' >/dev/null 2>&1
echo "[!] Dumped onboard SHSH to device, about to copy to this machine..."
echo "[!] Please enter the device's root password again (Default is 'alpine')..."
if scp root@$ip:dump.raw dump.raw >/dev/null 2>&1; then
   :
else
    echo "[#] Error: Failed to to copy 'dump.raw' from device to local machine..."
    exit
fi
echo "[!] Copied dump.raw to this machine, about to convert to SHSH..."
img4tool --convert -s dumped.shsh dump.raw >/dev/null 2>&1
if img4tool -s dumped.shsh | grep -q 'failed'; then
    echo "[#] Error: Failed to create SHSH from 'dump.raw'..."
    exit
fi
ecid=$(img4tool -s dumped.shsh | grep "ECID" | cut -c13-)
mv dumped.shsh $ecid.dumped.shsh # Allows multiple devices to be dumped as each dump/converted SHSH will have a filename that links the SHSH to the device
generator=$(cat $ecid.dumped.shsh | grep "<string>0x" | cut -c10-27)

echo "[!] SHSH should be dumped successfully at '$ecid.dumped.shsh' (The number in the filename is your devices ECID)!"
echo "[!] Your Generator for the dumped SHSH is: $generator"
echo "[@] Written by Matty (@mosk_i) - Enjoy!"
exit 0
