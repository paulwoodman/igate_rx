#!/bin/bash

# -------------------------
# iGate Install Script with Read-Only Root (OverlayFS)
# -------------------------

set -e

echo "Updating package list..."
sudo apt update -y

echo "Installing Direwolf, RTL-SDR, and required packages..."
sudo apt-get install -y \
  direwolf \
  rtl-sdr \
  git \
  python3-pip \
  fonts-dejavu \
  python3-pil \
  python3-pyinotify \
  python3-numpy \
  python3-venv

if command -v direwolf &>/dev/null && command -v rtl_test &>/dev/null; then
    echo "Installation successful!"
else
    echo "Error during installation. Exiting."
    exit 1
fi

# Enable SPI
echo "Enabling SPI interface..."
sudo sed -i '/#dtparam=spi=on/s/^#//' /boot/firmware/config.txt
if ! grep -q "^dtparam=spi=on" /boot/firmware/config.txt; then
    echo "Failed to enable SPI. Exiting."
    exit 1
fi

# Prompt user for iGate info
read -p "Enter your callsign (UPPERCASE ONLY): " CALLSIGN
read -s -p "Enter your APRS password: " MAGICBUG_PASSWORD
echo
read -p "Enter frequency (default 144.39M US, 144.80M UK): " FREQ
FREQ=${FREQ:-144.39M}
read -p "Enter latitude (default 39.911): " LAT
LAT=${LAT:-39.911}
read -p "Enter longitude (default -122.935): " LONG
LONG=${LONG:-"-122.935"}

USER=$(whoami)
USER_HOME=$(eval echo ~$USER)

# Generate direwolf.conf
echo "Generating direwolf.conf..."
cat <<EOL > $USER_HOME/direwolf.conf
MYCALL $CALLSIGN
IGSERVER noam.aprs2.net
IGLOGIN $CALLSIGN $MAGICBUG_PASSWORD
PBEACON sendto=IG compress=1 delay=00:15 every=30:00 symbol="igate" overlay=R lat=$LAT long=$LONG comment="Direwolf Rx-only igate"
AGWPORT 8000
KISSPORT 8001
ADEVICE null
EOL

touch $USER_HOME/direwolf.log
sudo chown $USER:$USER $USER_HOME/direwolf.log

# Create Python virtual environment
echo "Creating Python virtual environment 'igate'..."
python3 -m venv $USER_HOME/igate
source $USER_HOME/igate/bin/activate
pip install aprslib
deactivate

# Create systemd service
echo "Creating systemd service..."
sudo tee /etc/systemd/system/rtl_fm_direwolf.service > /dev/null <<EOL
[Unit]
Description=RTL-SDR and Direwolf Service for APRS
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash -c "rtl_fm -s 22050 -g 49 -f $FREQ 2X - | direwolf -c $USER_HOME/direwolf.conf -r 22050 -D 1 - > /tmp/direwolf.log 2>&1"
Restart=always
User=$USER
Group=$USER
WorkingDirectory=$USER_HOME
Environment=HOME=$USER_HOME

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload
sudo systemctl enable rtl_fm_direwolf.service
sudo systemctl start rtl_fm_direwolf.service

# -------------------------
# Enable Overlay File System (read-only root)
# -------------------------
echo "Enabling OverlayFS for read-only root..."
sudo raspi-config nonint do_overlayfs 0

echo "OverlayFS enabled. SD writes are now protected, root is read-only."
echo "Reboot the Raspberry Pi to apply read-only root and start the iGate service."
