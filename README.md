# Basic install script for receieve only Igate device for Raspberry pi and a RTL dongle

# Download the script to the Pi
wget https://raw.githubusercontent.com/paulwoodman/igate_rx/main/igate_install.sh
or
curl -O https://raw.githubusercontent.com/paulwoodman/igate_rx/main/igate_install.sh

# Make the file executable
chmod +x igate_install.sh

# Run the script and follow the prompts
./igate_install.sh

# Make sure to reboot the raspberry pi
sudo reboot

# You can verify if the igate is running
sudo systemctl start rtl_fm_direwolf.service

Should look like this


igate@igate:~ $ sudo systemctl status rtl_fm_direwolf.service
● rtl_fm_direwolf.service - RTL-SDR and Direwolf Service for APRS
     Loaded: loaded (/etc/systemd/system/rtl_fm_direwolf.service; enabled; preset: enabled)
     Active: active (running) since Sun 2026-03-29 21:37:05 PDT; 9s ago
 Invocation: 8bcfe37299564f54b175e0bf0717f58a
   Main PID: 1324 (bash)
      Tasks: 21 (limit: 3920)
        CPU: 2.308s
     CGroup: /system.slice/rtl_fm_direwolf.service
             ├─1324 /bin/bash -c "rtl_fm -s 22050 -g 49 -f 144.39M 2X /dev/null | direwolf -t 0 -r 22050 - > /home/igate/direwolf.log"
             ├─1326 rtl_fm -s 22050 -g 49 -f 144.39M 2X /dev/null
             └─1327 direwolf -t 0 -r 22050 -

Mar 29 21:37:05 igate systemd[1]: Started rtl_fm_direwolf.service - RTL-SDR and Direwolf Service for APRS.
