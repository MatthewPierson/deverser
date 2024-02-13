#! /bin/sh

if ! [ -w "$PWD" ]; then
    pre_echo E "The current user doesn't have permissions to write in $PWD. Please run Deverser in another directory."
    exit 7
fi

escape_nc='\033[0m'
os=""

delete_dump() {
    if [ -f "deverser_dump.raw" ]; then
        rm -rf deverser_dump.raw
    fi
    exit
}

trap delete_dump INT TERM

pre_echo() {
    if [ -n "$2" ]; then
        case $1 in
        [Ll] | log | LOG)
            shift
            printf "\033[0;32m$*$escape_nc\n" #print green
            ;;
        [Ee] | error | err | ERR | ERROR)
            shift
            printf "\033[0;31m$*$escape_nc\n" # print red
            ;;
        [Ww] | warn | WARN)
            shift
            printf "\033[0;33m$*$escape_nc\n" # print yellow
            ;;
        esac
    else
        printf "\033[0;32m$1$escape_nc\n" # print green
    fi
}

os_check() {
    unamestr=$(uname)
    if [ "$unamestr" = "Darwin" ]; then
        if sw_vers | grep -i -e '(ios|iphone|ipad)' >/dev/null; then
            OS=ios
            pre_echo "iOS/iPadOS detected!"
        elif sw_vers | grep -i mac >/dev/null; then
            OS=macos
            pre_echo "macOS detected!"
        fi
    elif [ "$unamestr" = "Linux" ]; then
        OS=ubuntu
        pre_echo "Linux detected!"
    else
        pre_echo E "Not running on Darwin (macOS/iPadOS/iOS) or Linux. exiting..."
        exit 1
    fi

    if [ "$os" != "ios" ] && [ "$on_device" = "1" ]; then
        pre_echo W "'on_device' was set, but a iPadOS/iOS device was not detected. Ignoring..."
        on_device="0"
    fi
}

get_firmware_ver() {
    if [ "$on_device" = "1" ]; then
        firmware_version="$(sw_vers -productVersion)"
    else
        pre_echo W "Enter the password for the mobile user if prompted."
        firmware_version="$(ssh mobile@$ip -p "$port_number" 'sw_vers -productVersion')"
    fi
}

detect_jbtype() {
    if [ "$os" = "ios" ]; then
        if [ -L "/var/jb" ] || [ -d "/private/preboot/$(cat /private/preboot/active)/procursus" ]; then
            jbtype="rootless"
            pre_echo "Rootless jailbreak detected!"
        elif [ -n "$(jbrand)" ] || [ -n "$(jbroot)" ]; then
            jbtype="roothide"
            pre_echo "Roothide-based jailbreak detected!"
        else
            jbtype="rootful"
            pre_echo "Rootful jailbreak detected!"
        fi
    elif [ -z "$jbtype" ]; then
        pre_echo "Please choose your jailbreak type below:"
        pre_echo "1. Rootless\n2. Roothide\n3. Rootful"
        while [ -z "$jbtype" ]; do
        read -r jbtype
            case $jbtype in

            1 | rootless | Rootless)
                jbtype="rootless"
                ;;
            2 | Roothide | roothide | RootHide)
                jbtype="roothide"
                ;;
            3 | rootful | Rootful)
                jbtype="rootful"
                ;;
            *)
                pre_echo W "Invalid entry."
                ;;
            esac
        done
    fi

    if [ $jbtype = "rootless" ] || [ "$jbtype" = "roothide"]; then
        ssh_user=mobile
    else
        ssh_user=root
    fi
}

check_img4tool() {
    if command -v img4tool >/dev/null; then
        pre_echo L "Found img4tool at $(command -v img4tool)!"
    else
        pre_echo W "img4tool is not installed, do you want Déverser to download and install img4tool for you? (If no then the script will close, img4tool is needed)"
        pre_echo L "Please enter 'Yes' or 'No':"
        read -r consent
        case $consent in
        [Yy]*)
            if [ "$on_device" != "1" ]; then
                if command -v curl >/dev/null; then
                    pre_echo "curl is installed!"
                else
                    pre_echo W "curl is required for this script to automatically download img4tool. Please install it or img4tool before running Dèverser again."
                    exit 2
                fi

                pre_echo "Downloading latest img4tool from tihmstar's repo..."

                latestBuild=$(curl --silent "https://api.github.com/repos/tihmstar/img4tool/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
                link="https://github.com/tihmstar/img4tool/releases/download/${latestBuild}/buildroot_${OS}-latest.zip"
                curl -L "$link" --output img4tool-latest.zip
                IMG4TOOL_TEMP=$(mktemp -d 'img4tool.XXXXXXX')
                unzip -q img4tool-latest.zip -d "$IMG4TOOL_TEMP"
                pre_echo W "Terminal may ask for permission to move the files into '/usr/local/bin' and '/usr/local/include', please enter your password if prompted."
                sudo mkdir -p /usr/local/bin /usr/local/include
                sudo install -m755 "$IMG4TOOL_TEMP/buildroot_$OS-latest/usr/local/bin/img4tool" /usr/local/bin/img4tool
                sudo cp -R "$IMG4TOOL_TEMP/buildroot_$OS-latest/usr/local/include/img4tool" /usr/local/include
                if command -v img4tool >/dev/null; then
                    pre_echo "img4tool is installed at $(command -v img4tool)!"
                fi
                rm -rf img4tool-latest.zip "$IMG4TOOL_TEMP"

            elif [ "$on_device" = "1" ]; then
                pre_echo W "At the moment, img4tool is only available from procursus. If you're not using a jailbreak with this repo or a bootstrap based on it, do not add it."
                sleep 2
                sudo apt install -y img4tool || pre_echo E "installing img4tool uaing apt has failed." && exit 8

            fi

            ;;
        *)
            pre_echo W "img4tool is needed for this script to function."
            if [ "$on_device" != "1" ]; then
                pre_echo W "If you want to manually install it, you can download img4tool from 'https://github.com/tihmstar/img4tool/releases/latest' and manually move the files to the correct locations."
            else
                pre_echo W "If you want to manually install it, run 'sudo apt install img4tool' or use your pacakge manager."
            fi
            exit 5
            ;;
        esac

    fi
}

ask_for_ip() {
    while [ "$ip_verify" = "0" ] || [ -z "$ip_verify" ]; do
        pre_echo W "Please enter your device's IP address (Found in wifi settings)"
        read -r ip
        pre_echo "You entered: $ip"
        pre_echo W "Is this correct? (yes/no)"
        read -r ip_ask
        case $ip_ask in
        [yY]*)
            ip_verify="1"
            ;;
        [nN]*)
            ip_verify="0"
            ;;
        *)
            pre_echo E "Option does not match 'yes/y' or 'n/no'"
            ip_verify="0"
            ;;
        esac
    done
    unset ip_verify
}

ask_for_port() {
    while [ "$port_verify" = "0" ] || [ -z "$port_verify" ] && [ -z $port_number ]; do
        pre_echo W "Please enter the port number for the device. If you don't know what this is, just press return/enter."
        read -r port_number
        if [ -n "$port_number" ]; then

            pre_echo "You entered: $port_number"
            pre_echo "Is this correct? (yes/no)"
            read -r ask
            case $ask in
            [yY]*)
                port_verify="1"
                ;;
            [nN]*)
                port_verify="0"
                ;;
            *)
                pre_echo W "Option does not match 'yes/y' or 'n/no'"
                port_verify="0"
                ;;
            esac
            unset port_verify
        else
            pre_echo W "Defaulting to port 22"
            port_number="22"
        fi
    done
}

dump_remote() {
    ask_for_ip
    ask_for_port
    detect_jbtype

    pre_echo W "Assuming given IP and port number to be correct, if connecting to the device fails. ensure you entered all details correctly and have a ssh server running."

    pre_echo W "Please enter the device's $ssh_user user password."

    if ssh -t $ssh_user@$ip -p $port_number 'sudo cat /dev/disk1 | dd of=deverser_dump.raw bs=256 count=$((0x4000))' >/dev/null 2>&1; then

        pre_echo W "Dumped onboard SHSH to device, about to copy to this machine..."
        pre_echo W "Please enter the device's $ssh_user password again."
        if scp -P $port_number $ssh_user@$ip:deverser_dump.raw deverser_dump.raw >/dev/null 2>&1; then
            :
        else
            pre_echo E "Failed to to copy 'dump.raw' from device to local machine."
            exit 3
        fi
        pre_echo "Copied dump.raw to this machine, about to convert to SHSH."
        img4tool --convert -s dumped.shsh deverser_dump.raw >/dev/null 2>&1
        if img4tool -s dumped.shsh | grep -q 'failed'; then
            pre_echo E "Failed to create SHSH from 'dump.raw'..."
            exit 4
        fi
    fi
}

dump_local() {
    if [ "$1" = "rootless" ] || [ "$1" = "roothide" ]; then
        pre_echo W "The password for the 'mobile' user is required to elevate permissions. Please enter it when prompted."
        sudo cat /dev/disk1 | dd of=deverser_dump.raw bs=256 count=$((0x4000)) >/dev/null
        if [ -f deverser_dump.raw ] && ! [ -O deverser_dump.raw ]; then
            sudo chown mobile deverser_dump.raw
            chmod 755 deverser_dump.raw
        fi
    else
        sudo cat /dev/disk1 | dd of=deverser_dump.raw bs=256 count=$((0x4000)) >/dev/null
    fi

    if [ -f deverser_dump.raw ]; then
        pre_echo "deverser_dump.raw created. about to convert to SHSH."
        img4tool --convert -s dumped.shsh deverser_dump.raw >/dev/null 2>&1
        if img4tool -s dumped.shsh | grep -q 'failed'; then
            pre_echo E "Failed to create SHSH from 'dump.raw'..."
            exit 4
        fi
    fi

}

finisher() {
    ecid=$(img4tool -s dumped.shsh | grep "ECID" | cut -c13-)
    mv dumped.shsh "$firmware_version-$ecid".dumped.shsh # Allows multiple devices to be dumped as each dump/converted SHSH will have a filename that links the SHSH to the device
    generator="$(cat "$ecid".dumped.shsh | grep "<string>0x" | cut -c10-27)"

    pre_echo W "SHSH should be dumped successfully at '$firmware_version-$ecid.dumped.shsh' (The number in the beginning of the filename after the version is your devices' ECID)!"
    pre_echo W "Your generator for the dumped SHSH is: $generator"
    pre_echo "Originally Written by Matty (@mosk_i), Modified by joshuah345 / Superuser#1958 - Enjoy!"
    exit
}

# main logic below

cat <<"intro"
Welcome to Déverser, a simple script to dump onboard SHSH (Blobs) with a valid Generator for iOS devices.
This script will allow you to use dumped blobs with futurerestore at a later date (depending on SEP/Baseband compatibility).
intro

os_check
check_img4tool
if [ "$on_device" = "1" ]; then
    detect_jbtype
    dump_local $jbtype
else
    dump_remote 
fi
get_firmware_ver
finisher
