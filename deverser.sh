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


if command -v img4tool >/dev/null; then
    echo "[!] Found img4tool at $(command -v img4tool)!"
else
    echo "[#] img4tool is not installed, do you want Déverser to download and install img4tool? (If no then the script will close, img4tool is needed)"
    echo "[*] Please enter 'Yes' or 'No':"
    read -r consent
    case $consent in
        [Yy]* )
            
            if which curl >/dev/null; then
                echo "[i] curl is installed!"
            else
                echo "[!] curl is required for this script to download img4tool. Please install it or img4tool before running Dèverser again."
                exit 2
            fi
            
            echo "[!] Downloading latest img4tool from tihmstar's repo..."
            
            latestBuild=$(curl --silent "https://api.github.com/repos/tihmstar/img4tool/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
            link="https://github.com/tihmstar/img4tool/releases/download/${latestBuild}/buildroot_${OS}-latest.zip"
            curl -L "$link" --output img4tool-latest.zip
            IMG4TOOL_TEMP=$(mktemp -d 'img4tool.XXXXXXX')
            unzip -q img4tool-latest.zip -d "$IMG4TOOL_TEMP"
            echo "[*] Terminal may ask for permission to move the files into '/usr/local/bin' and '/usr/local/include', please enter your password if it does..."
            sudo install -m755 "$IMG4TOOL_TEMP/buildroot_$OS-latest/usr/local/bin/img4tool" /usr/local/bin/img4tool
            sudo cp -R "$IMG4TOOL_TEMP/buildroot_$OS-latest/usr/local/include/img4tool" /usr/local/include
            if command -v img4tool >/dev/null; then
                echo "[!] img4tool is installed at $(command -v img4tool)!"
            fi
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
ssh root@$ip 'cat /dev/disk1 | dd of=dump.raw bs=256 count=$((0x4000))' >/dev/null 2>&1
echo "[!] Dumped onboard SHSH to device, about to copy to this machine..."
echo "[!] Please enter the device's root password again (Default is 'alpine')..."
if scp root@$ip:dump.raw dump.raw >/dev/null 2>&1; then
    :
else
    echo "[#] Error: Failed to to copy 'dump.raw' from device to local machine..."
    exit 3
fi
echo "[!] Copied dump.raw to this machine, about to convert to SHSH..."
img4tool --convert -s dumped.shsh dump.raw >/dev/null 2>&1
if img4tool -s dumped.shsh | grep -q 'failed'; then
    echo "[#] Error: Failed to create SHSH from 'dump.raw'..."
    exit 4
fi
ecid=$(img4tool -s dumped.shsh | grep "ECID" | cut -c13-)
mv dumped.shsh $ecid.dumped.shsh # Allows multiple devices to be dumped as each dump/converted SHSH will have a filename that links the SHSH to the device
generator=$(cat $ecid.dumped.shsh | grep "<string>0x" | cut -c10-27)

echo "[!] SHSH should be dumped successfully at '$ecid.dumped.shsh' (The number in the filename is your devices ECID)!"
echo "[!] Your Generator for the dumped SHSH is: $generator"
echo "[@] Originally Written by Matty (@mosk_i), Modified by joshuah345 / Superuser#1958 - Enjoy!"
exit