# Déverser-linux
Original script by @moski_dev. If you are using Mac go to the [original repo](https://github.com/MatthewPierson/deverser). Go there to read the explanation of the script to know what the hell this is about.
## Requirements
On your PC:
- iproxy\
install it if you haven't already (debian):\
`sudo apt install libusbmuxd-tools`\
On your idevice:
- OpenSSH\
Install it with your package manager
## Before running the script
run:\
`iproxy 2222 22 > /dev/null &`\
Change the script permisions to run it.\
`chmod +x ./deverser-linux.sh`\
## Now we are good to run the script.
`./deverser-linux.sh`

# Credits
- @moski_dev for the original script
- me, @ilanmittelman for adapting it to linux and writing this
