# Déverser
Simple macOS script to dump onboard SHSH with a valid Generator for iOS devices

## What is this/What does this do

Déverser is a simple macOS script to dump onboard SHSH from iOS devices and convert it to useable SHSH which contains a generator! This is different to just dumping 'ApTicket.der' from the device's filesystem, like some jailbreaks such as Unc0ver allow for, as the 'ApTicket.der' doesn't contain the generator for the ApNonce it is valid for, meaning restores/downgrades using converted ApTicket.der's are not possible unless you know the generator.

This script simply dumps iBoot from /dev/rdisk1 on the device, copies the dump to your computer then converts the dump to valid SHSH using [img4tool](https://github.com/tihmstar/img4tool). This is all possible and easy to do manually, this script just allows for those who are less comfortable with the command line or less knowledgeable to have a simple method to dump onboard SHSH.

Even though this script will give you valid SHSH for the currently installed iOS version on your device, you are still limited by signed SEP compatiblity when restoring/downgrading with this dumped SHSH, so please bare that in mind when using this script.

Déverser is just a small project I made in 2 hours while I was bored, if it's useful to someone then that's great, I hope you enjoy it! Don't expect fast support or any features to be added to this script, it works as-is and that's all I care about.

## Requirements

A macOS machine (OS version shouldn't matter as long as img4tool supports it)

A jailbroken device with OpenSSH installed (Specific jailbreak doesn't matter, E.G checkra1n, Unc0ver, chimera, etc)

img4tool installed (If img4tool is not installed, the script will download the latest release from Tihmstar's repo and install it after getting the users permission)

## Usage

1. Either run 'git clone https://github.com/MatthewPierson/deverser.git' or [download the .zip from here](https://github.com/MatthewPierson/deverser/archive/master.zip) and extract to a folder on your machine
2. 'cd' to the deverser folder and then run 'chmod +x deverser.sh'
3. Run './deverser.sh'
4. Follow what the script asks you to do (Mostly just entering your device's IP address and root password for SSH/SCP)

## Issues/Bugs/Fixes/Improvements

If you have any bugs/issues open an issue [here](https://github.com/MatthewPierson/deverser/issues) with details about your macOS machine (OS version, other basic info), iOS device (iOS version, jailbreak, etc) and details about what is not working.

Any ideas/fixes/improvements can be sent in a pull request [here](https://github.com/MatthewPierson/deverser/pulls).

## Credits

Matty (Me) - [@mosk_i](https://twitter.com/mosk_i) - For writing the script

Tihmstar - [@tihmstar](https://twitter.com/tihmstar) - For creating img4tool
