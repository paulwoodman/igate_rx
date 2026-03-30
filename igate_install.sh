#!/bin/bash

# Check if the script is running in an interactive shell
if ! [ -t 0 ]; then
  echo "This script requires an interactive terminal session."
  exit 1
fi

# Debug: Start of interactive session
echo "Interactive terminal session detected. Proceeding with prompts..."

# Prompt the user for their callsign and magicbug password
echo -n "Enter your callsign: "
read CALLSIGN
echo "User entered callsign: $CALLSIGN"  # Debug output

echo -n "Enter your Magicbug password: "
read -s MAGICBUG_PASSWORD
echo  # just to add a new line after the password input for neatness
echo "User entered Magicbug password: (hidden for security)"  # Debug output

# Prompt the user for the frequency (default US frequency is 144.39M)
echo -n "Enter the frequency (default is 144.39M for US, or type your own): "
read FREQ
FREQ=${FREQ:-144.39M}  # If user doesn't provide input, default to 144.39M
echo "User selected frequency: $FREQ"  # Debug output

# Prompt the user for their latitude and longitude
echo -n "Enter your latitude (default is 39.911): "
read LAT
LAT=${LAT:-39.911}  # Default to 39.911 if no input is given
echo "User entered latitude: $LAT"  # Debug output

echo -n "Enter your longitude (default is -122.935): "
read LONG
LONG=${LONG:-"-122.935"}  # Default to -122.935 if no input is given
echo "User entered longitude: $LONG"  # Debug output

# Rest of the script continues below...
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

# Create the direwolf.conf file with dynamic content
echo "Generating direwolf.conf file..."
cat <<EOL > direwolf.conf
MYCALL $CALLSIGN
IGSERVER noam.aprs2.net
IGLOGIN $CALLSIGN $MAGICBUG_PASSWORD
PBEACON sendto=IG compress=1 delay=00:15 every=30:00 symbol="igate" overlay=X lat=$LAT long=$LONG comment="Direwatch Rx-only igate"
AGWPORT 8000
KISSPORT 8001
ADEVICE null
EOL

echo "direwolf.conf file has been created successfully!"

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

# Get the user's home directory for log file creation
USER_HOME=$(eval echo ~$USER)
LOG_FILE="$USER_HOME/direwolf.log"

# Create a systemd service to run rtl_fm and direwolf on boot
echo "Creating systemd service to start rtl_fm and Direwolf on boot..."

sudo tee /etc/systemd/system/rtl_fm_direwolf.service > /dev/null <<EOL
[Unit]
Description=RTL-SDR and Direwolf Service for APRS
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash -c "rtl_fm -s 22050 -g 49 -f $FREQ 2X /dev/null | direwolf -t 0 -r 22050 - > $LOG_FILE"
Restart=always
User=$USER
Group=$USER
StandardOutput=append:$LOG_FILE
StandardError=append:$LOG_FILE
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
