#!/bin/bash

#Disabling wifi on the ZTE MF910 mifi
#
#This script automatically disables the wifi on the ZTE MF910 mifi, something
#which is not possible through the normal UI. Disabling is done by prepending
#exit to two init-scripts which are responsible for setting up wifi on the
#device.
#
#The mifi is actually an Android-device. The first step is to log in, and then
#the device is switched to Android-mode. We then make use of adb and sed to
#insert the exit-commands in the two files. After this is done, we reboot the
#device. The script has worked on all devices I have tried with, but checking
#some devices manually is probably a good idea in case of firmware differences.
#
#In order to run the script, jq (for processing some JSON returned by the modem)
#and adb must be installed. Note that we have assumed that the machine the
#script is run on is not connected to any network where the IP range overlaps
#with the one provided by the mifi (normally 192.168.0.0/24 or 192.168.8.0/24).
#We have also assumed that the mifi is the only android device connected to the
#machine

LOGIN_URL="/goform/goform_set_cmd_process?isTest=false&goformId=LOGIN&password=YWRtaW4%3D";
MODE_SWITCH_URL="/goform/goform_set_cmd_process?goformId=USB_MODE_SWITCH&usb_mode=6";

login_mifi()
{
    echo "Attempting MF910 login ...";

    while true;
    do
        local http_code=`curl -sL -w "%{http_code}" -o "$2" \
            -H "Referer: http://$1/index.html" \
            -H "Host: $1" \
            --connect-timeout 5 \
            "$1/$LOGIN_URL"`;

        if [ $? -ne 0 -a $http_code -ne 200 ];
        then
            echo "MF910 login failed (curl), will retry ...";
            sleep 5;
        fi

        local result=`jq '.result' $2`
        rm $2

        if [ "$result" == '"0"' ];
        then
            echo "MF910 login successful ...";
            return;
        else
            echo "MF910 login failed, will retry ...";
            sleep 5;
        fi
    done
}

switch_mifi()
{
    echo "Attempting MF910 switch to Android ...";

    while true;
    do
        local http_code=`curl -sL -w "%{http_code}" -o "$2" \
            -H "Referer: http://$1/index.html" \
            -H "Host: $1" \
            --connect-timeout 5 \
            "$1/$MODE_SWITCH_URL"`;

        if [ $? -ne 0 -a $http_code -ne 200 ];
        then
            echo "MF910 switch failed (curl), will retry ...";
            sleep 5;
        fi

        local result=`jq '.result' $2`
        rm $2

        if [ "$result" == '"success"' ];
        then
            echo "MF910 switch successful ...";
            return;
        else
            echo "MF910 switch failed, will retry ...";
            sleep 5;
        fi
    done

}

wait_for_device()
{
    while true;
    do
        adb devices | grep ZTE > /dev/null;

        if [ $? -ne 0 ];
        then
            echo "ZTE Android device not seen, sleeping five sec ...";
            sleep 5;
            continue;
        else
            echo "ZTE Android device found ...";
            break;
        fi
    done
}

disable_wifi()
{
    echo "Disabling wifi ...";

    while true;
    do
        adb shell "sed -i '2i exit 0' /etc/init.d/wlan && sed -i '2i exit 0' /etc/init.d/wlan_hsic && reboot"
        sleep 5;

        #adb returns zero as long as the application is run successfully (i.e., ignores
        #return value of command on device). Use the fact that MF910 is not seen as
        #Android device by default (after reboot) as a successs criteria
        adb devices | grep ZTE > /dev/null;

        if [ $? -eq 0 ];
        then
            echo "Failed to disable wifi on device, will retry ...";
            continue;
        else
            echo "Sucessfully disabled wifi init scripts";
            break;
        fi
    done
}

#Address of device is first paramter (typically 192.168.0.1 or 192.168.8.1)
#Second paramter is where to store data returned by modem (will cleaned up)
if [ $# -ne 2 ];
then
    echo "./disable_wifi_mf910.sh <IP of device> <temporary JSON storage path>";
    exit 0;
fi

while true;
do
    login_mifi $1 $2
    switch_mifi $1 $2
    wait_for_device
    disable_wifi

    read -p "Press enter to disable wifi on next device";
done
