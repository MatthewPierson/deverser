#!/bin/bash

if test -f "dump.raw"; then
    rm -rf dump.raw
fi
echo ""
echo "[!] Welcome to Déverser, a simple script to dump onboard SHSH (Blobs) with a valid Generator for iOS devices..."
echo "[!] This script will allow you to use dumped blobs with futurerestore at a later date (depending on SEP compatibility)..."
if test -f "/usr/local/bin/img4tool"; then
    echo "[!] Found img4tool at '/usr/local/bin/img4tool'!"
else
    echo "[#] img4tool is not installed, do you want Déverser to download and install img4tool? (If no then the script will close, img4tool is needed, you will need sudo for this installation to work properly)"
    echo "[*] Please enter 'Yes' or 'No':"
    read consent
    if [ $consent == 'Yes' ] | [ $consent == 'yes' ]; then
        echo "[!] Downloading latest img4tool from Tihmstar's repo..."
        latestBuild=$(curl --silent "https://api.github.com/repos/tihmstar/img4tool/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        link="https://github.com/tihmstar/img4tool/releases/download/${latestBuild}/buildroot_ubuntu-latest.zip"
        curl -L "$link" --output img4tool-latest.zip
        mkdir img4tool
        unzip -q img4tool-latest.zip -d img4tool
        echo "[*] Terminal may ask for permission to move the files into '/usr/local/bin' and '/usr/local/include', please enter your password if it does..."
        cp img4tool/buildroot_macos-latest/usr/local/bin/img4tool /usr/local/bin/img4tool
        cp -R img4tool/buildroot_macos-latest/usr/local/include/img4tool /usr/local/include
        chmod +x /usr/local/bin/img4tool
        rm -rf img4tool-latest.zip
        rm -rf img4tool/
        echo "[*] Installed img4tool"
    elif [ $consent == 'No' ] | [ $consent == 'no' ]; then
        echo "[#] img4tool is needed for this script to work..."
        echo "[#] If you want to manually install it, you can download img4tool from 'https://github.com/tihmstar/img4tool/releases/latest' and manually move the files to the correct locations..."
        exit
    else
        echo "[#] Unknown input, assuming to be a variant of 'No'..."
        echo "[#] img4tool is needed for this script to work..."
        echo "[#] If you want to manually install it, you can download img4tool from 'https://github.com/tihmstar/img4tool/releases/latest' and manually move the files to the correct locations..."
        exit
    fi  
fi
echo "[!] This script will use iproxy! please make sure to run "iproxy 2222 44" in another session for this to work!"
echo "[!] Please enter the device's root password (Default is 'alpine')..."
ssh root@$localhost -p 2222 "cat /dev/rdisk1 | dd of=dump.raw bs=256 count=$((0x4000))" &> /dev/null
echo "[!] Dumped onboard SHSH to device, about to copy to this machine..."
echo "[!] Please enter the device's root password again (Default is 'alpine')..."
scp -P 2222 root@$localhost:dump.raw dump.raw &> /dev/null
if test -f "dump.raw"; then
    echo ""
else
    echo "[#] Error: Failed to to copy 'dump.raw' from device to local machine..."
    exit
fi
echo "[!] Copied dump.raw to this machine, about to convert to SHSH..."
img4tool --convert -s dumped.shsh dump.raw &> /dev/null
if img4tool -s dumped.shsh | grep -q 'failed'; then
    echo "[#] Error: Failed to create SHSH from 'dump.raw'..."
    exit
fi
ecid=$(img4tool -s dumped.shsh | grep "ECID" | cut -c13-)
mv dumped.shsh ${ecid}.dumped.shsh # Allows multiple devices to be dumped as each dump/converted SHSH will have a filename that links the SHSH to the device
generator=$(cat ${ecid}.dumped.shsh | grep "<string>0x" | cut -c10-27)
echo "[!] SHSH should be dumped successfully at '${ecid}.dumped.shsh' (The number in the filename is your devices ECID)!"
echo "[!] Your Generator for the dumped SHSH is: ${generator}"
echo "[@] Written by Matty (@mosk_i) - Enjoy!"
echo ""
