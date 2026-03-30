# iGate Installation Guide for Raspberry Pi

This guide will walk you through installing and setting up the iGate (APRS RX-only) service on your Raspberry Pi. The process involves downloading a script, running it, and configuring your iGate settings.

## Prerequisites

- A Raspberry Pi running Raspberry Pi OS (or a similar Linux distribution).
- An RTL-SDR USB stick.
- An active internet connection.
- Basic terminal knowledge.

## Step 1: Download the Installation Script

To begin, download the installation script to your Raspberry Pi using one of the following commands:

**Download the installer:**

```bash
wget https://raw.githubusercontent.com/paulwoodman/igate_rx/main/igate_install.sh
```
or

```bash
curl -O https://raw.githubusercontent.com/paulwoodman/igate_rx/main/igate_install.sh
```

## Step 2: Make the installer execuitable 
```
chmod +x igate_install.sh
```

## Step 3: Run the installer
```
./igate_install.sh
```

