# Déverser-linux
Original script by @moski_dev. If you are using Mac this script with the folling procedure should also wok. Here's the [original repo](https://github.com/MatthewPierson/deverser), go there to read the explanation of the script to know what the hell this is about.
## Requirements
On your PC/Mac:
- `iproxy`\
install it if you haven't already.\
Debian/Ubuntu:\
`sudo apt install libusbmuxd-tools`\
MacOS: ([brew](brew.sh) required)\
`brew install libimobiledevice`
On your idevice:
- OpenSSH\
Install it with your package manager.
## Before running the script
Start `iproxy` on the background:\
`iproxy 2222 22 > /dev/null &`\
Change the script permisions to run it:\
`chmod +x ./deverser-linux.sh`\
## Now we are good to run the script.
`./deverser-linux.sh`
if you did everything correctly, you should have your .shsh2 file in your folder.
# Credits
- @moski_dev for the original script
- me, @ilanmittelman for adding linux support
