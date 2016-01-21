# zte-mf910-scripts

The commonly used ZTE MF910 mifi device is an Android device in
disguise. It turns out that it is possible to run adb shell and get root access
to device, enabling us to disable/change the configuration in more or less
any way we want. Be warned that if you do something wrong, the whole
device might crash. However, resetting the device (the small white button next
to the SIM card slot) seems to solve most problems.

The following scripts are available:

* disable\_wifi\_mf910.sh : When connected to a Linux-machine, the MF910 is seen
  as an rndis\_host device. Having wifi enabled is a bit of a waste, as well as
  a potential security risk. However, by default, disabling the 2.4 GHz wifi is
  not possible in the UI. This script disables the 2.4 GHz wifi. I have assumed that the
  MF910 is the only Android device connected to the host, as well as that
  there are no overlapping IP ranges (the script starts out by switching the
  MF910 to Android mode). 

Pull requests are always welcome!
