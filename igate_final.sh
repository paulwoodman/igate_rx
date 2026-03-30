#!/bin/bash

# Updating the package lists to get the latest version of repositories
echo "Updating package list..."
sudo apt update -y

# Installing Direwolf, RTL-SDR, and required dependencies
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
  python3-venv  # Install python3-venv for virtual environments

# Verifying if the installation was successful
if command -v direwolf &>/dev/null && command -v rtl_test &>/dev/null; then
    echo "Installation successful!"
else
    echo "There was an error during the installation process."
    exit 1
fi

# Enabling SPI by uncommenting the dtparam=spi=on line in /boot/firmware/config.txt
echo "Enabling SPI interface..."

# Uncomment dtparam=spi=on if it's commented out
sudo sed -i '/#dtparam=spi=on/s/^#//g' /boot/firmware/config.txt

# Verify the line has been uncommented (optional step)
if grep -q "dtparam=spi=on" /boot/firmware/config.txt; then
    echo "SPI interface enabled successfully!"
else
    echo "Failed to enable SPI interface."
    exit 1
fi

# Prompt the user for their callsign and aprs password
echo -n "Enter your callsign: (UPPERCASE ONLY!!) "
read CALLSIGN

echo -n "Enter your APRS password: (https://apps.magicbug.co.uk/passcode/) "
read -s MAGICBUG_PASSWORD
echo  # just to add a new line after the password input for neatness

# Prompt the user for the frequency (default US frequency is 144.39M)
echo -n "Enter the frequency (default is 144.39M for US, 144.80M for UK or type your own): "
read FREQ
FREQ=${FREQ:-144.39M}  # If user doesn't provide input, default to 144.39M

# Prompt the user for their latitude and longitude
echo -n "Enter your latitude (https://www.latlong.net/): "
read LAT
LAT=${LAT:-39.911}  # Default to 39.911 if no input is given

echo -n "Enter your longitude (https://www.latlong.net/): "
read LONG
LONG=${LONG:-"-122.935"}  # Default to -122.935 if no input is given

# Get the username of the current user
USER=$(whoami)

# Create the direwolf.conf file with dynamic content
echo "Generating direwolf.conf file..."
cat <<EOL > direwolf.conf
MYCALL $CALLSIGN
IGSERVER noam.aprs2.net
IGLOGIN $CALLSIGN $MAGICBUG_PASSWORD
PBEACON sendto=IG compress=1 delay=00:15 every=30:00 symbol="igate" overlay=X lat=$LAT long=$LONG comment="Direwolf Rx-only igate"
AGWPORT 8000
KISSPORT 8001
ADEVICE null
EOL

echo "direwolf.conf file has been created successfully!"

# Give the user write permissions to the direwolf.log file
USER_HOME=$(eval echo ~$USER)
touch /tmp/direwolf.log
sudo chown $USER:$USER /tmp/direwolf.log

# Create a Python virtual environment named 'igate'
echo "Creating Python virtual environment 'igate'..."
python3 -m venv igate

# Activate the virtual environment
echo "Activating the virtual environment 'igate'..."
source igate/bin/activate

# Install aprslib within the virtual environment
echo "Installing aprslib in the virtual environment..."
pip install aprslib

# Verifying installation of aprslib
if python -c "import aprslib" &>/dev/null; then
    echo "aprslib installation successful!"
else
    echo "Failed to install aprslib."
    exit 1
fi

# Deactivate the virtual environment
echo "Deactivating the virtual environment..."
deactivate

# Create a systemd service to run rtl_fm and direwolf on boot
echo "Creating systemd service to start rtl_fm and Direwolf on boot..."

sudo tee /etc/systemd/system/rtl_fm_direwolf.service > /dev/null <<EOL
[Unit]
Description=RTL-SDR and Direwolf Service for APRS
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash -c "rtl_fm -s 22050 -g 49 -f $FREQ 2X /dev/null | direwolf -c $USER_HOME/direwolf.conf -r 24000 -D 1 - > /tmp/direwolf.log"
Restart=always
User=$USER
Group=$USER
StandardOutput=append:/tmp/direwolf.log
StandardError=append:/tmp/direwolf.log
WorkingDirectory=$USER_HOME
Environment=HOME=$USER_HOME

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd to apply the new service configuration
sudo systemctl daemon-reload

# Enable the service to start at boot
sudo systemctl enable rtl_fm_direwolf.service

# Start the service immediately to check if everything is working
sudo systemctl start rtl_fm_direwolf.service

# Verify the service status
echo "Verifying the service status..."
sudo systemctl status rtl_fm_direwolf.service

echo "rtl_fm and Direwolf service created and running!"

# Final installation message
echo "Installation complete!"
echo "Please reboot your Raspberry Pi to start the service and ensure everything is running smoothly."

# Remount the root filesystem as read-only after installation
echo "Setting root filesystem to read-only to prevent SD card corruption..."

# Remount the root filesystem as read-only
sudo mount -o remount,ro /

# Ensure /home, /var/log, and /tmp are read-write for logging and configuration
sudo mount -o remount,rw /home
sudo mount -o remount,rw /var/log
sudo mount -o remount,rw /tmp

# Suggest a reboot
echo "Filesystem is now read-only, but some directories remain writable for logging and configuration."
echo "You can reboot your Raspberry Pi now to make sure everything is set up properly."
