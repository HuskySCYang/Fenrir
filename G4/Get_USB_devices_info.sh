#!/bin/bash
# Program:
#	List all of the USB port include vendor, product, and speed.
# Version:
#	1.2
# History:
#	V1.0 2018/07/03 Terry Hsu	First release
#	V1.1 2018/12/27 Terry Hsu	Modify script
#	V1.2 2021/10/21 Terry Hsu	Modify script



for USBX in $(ls /sys/bus/usb/devices/ | grep -v ":\|usb")
do
	#echo " Bus:  $(cat /sys/bus/usb/devices/${USBX}/busnum) Device:  $(cat /sys/bus/usb/devices/${USBX}/devnum)c : $(lsusb -d $(cat /sys/bus/usb/devices/${USBX}/idVendor):$(cat /sys/bus/usb/devices/${USBX}/idProduct) | cut -d " " -f 7-)"
	{	
	echo "================================================================="	
	echo " $(lsusb -d $(cat /sys/bus/usb/devices/${USBX}/idVendor):$(cat /sys/bus/usb/devices/${USBX}/idProduct) | cut -d " " -f 7-)"
	echo " Manufacturer:  $(cat /sys/bus/usb/devices/${USBX}/manufacturer 2> /dev/null) "
	echo " Product:  $(cat /sys/bus/usb/devices/${USBX}/product 2> /dev/null) "
	echo " Vendor ID:  $(cat /sys/bus/usb/devices/${USBX}/idVendor)  Device ID:  $(cat /sys/bus/usb/devices/${USBX}/idProduct) "
	echo " USB version: $(cat /sys/bus/usb/devices/${USBX}/version)  Speed:  $(cat /sys/bus/usb/devices/${USBX}/speed)M "
	echo " Max Power:  $(cat /sys/bus/usb/devices/${USBX}/bMaxPower)"
	echo "=================================================================="
	} > usb.log
	cat usb.log | grep -i virtual > /dev/null
	if [ "$?" == 0 ]; then
		continue
	else
		cat usb.log
	fi
done

