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

echo "Installation complete!"
