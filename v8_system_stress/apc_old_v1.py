import telnetlib
import time
import sys

#apc_ip = sys.argv[1]
#print (apc_ip)
#print(time.asctime())
#command_1 = "tn" + " " + "=" + " " + 'telnetlib.Telnet("' + sys.argv[3] + '")'
#tn = telnetlib.Telnet("192.168.100.220")
#print (command_1)
#command_1

print(" ")	
#print(time.asctime())

tn = telnetlib.Telnet("192.168.2.12",23,10)
time.sleep(0.4)
data = ''
data = tn.read_very_eager().decode('ascii')
##print(data)
#tn.read_until(b"User Name :")
if "User Name" in data:
	tn.write(b"apc" + b"\r\n")
#	print ("login")
else:
	print ("Can't establish telnet session with APC" + " " + sys.argv[1])
	exit (1)
	
time.sleep(0.4)
data = ''
data = tn.read_very_eager().decode('ascii')
##print(data)
#tn.read_until(b"Password  :")
if "Password" in data:
	tn.write(b"apc" + b"\r\n")
#	print ("Password enter")
else:
	print ("Can't fill-in password..")
	exit (1)

time.sleep(0.4)
data = ''
data = tn.read_very_eager().decode('ascii')
#print(data)



#print ("3")
#tn.read_until(b"Main Menu")
if "Main Menu" in data:
	tn.write(b"apc" + b"\r\n")
	#print ("Password enter")
else:
	print ("Can't fill-in password..")
	exit (1)

time.sleep (0.4)
################################## Device Manager
#print ("debug1")
tn.write(b"1"+ b"\r")
time.sleep(0.4)
data = ''
#data = tn.read_very_eager().decode('ascii')
#print(data)

################################## Outlet Management
#print ("debug2")
#tn.read_until(b"Outlet Management")
#print(data)

tn.write(b"2"+ b"\r")
time.sleep (0.4)

################################## Outlet Control/Configuration
#print ("debug3")

data = ''
#data = tn.read_very_eager().decode('ascii')
#print(data)
#tn.read_until(b"Outlet Control")
tn.write(b"1"+ b"\r")
time.sleep (0.4)

################################## outlet port 
#print ("debug4")
data = ''
#data = tn.read_very_eager().decode('ascii')
#print(data)
#tn.read_until(b"Master")
if sys.argv[1] == "1":
	tn.write(b"1"+ b"\r")
elif sys.argv[1] == "2":
	tn.write(b"2"+ b"\r")
elif sys.argv[1] == "3":
	tn.write(b"3"+ b"\r")
elif sys.argv[1] == "4":
	tn.write(b"4"+ b"\r")
elif sys.argv[1] == "5":
	tn.write(b"5"+ b"\r")
elif sys.argv[1] == "6":
	tn.write(b"6"+ b"\r")
elif sys.argv[1] == "7":
	tn.write(b"7"+ b"\r")
elif sys.argv[1] == "8":
	tn.write(b"8"+ b"\r")
else: 
	print ("Invlaid APC port.")
	
time.sleep(0.4)
data = ''
#data = tn.read_very_eager().decode('ascii')
#print(data)
################################## Outlet Control
#print ("debug5")

#tn.read_until(b">")
tn.write(b"1"+ b"\r")

time.sleep(0.4)
data = ''
#data = tn.read_very_eager().decode('ascii')
#print(data)

################################# 1:on, 2:off 
#print ("debug6")

#tn.read_until(b">")
if sys.argv[2] == "on":
	tn.write(b"1"+ b"\r")
#	print("gg1")
elif sys.argv[2] == "off":
	tn.write(b"2"+ b"\r")
#	print("gg2")
else:
	print ("invalid parameter")	

time.sleep(0.4)
data = ''
#data = tn.read_very_eager().decode('ascii')
#print(data)

################################## yes
#print ("debug7")

#tn.read_until(b">")
tn.write(b"YES"+ b"\r")

time.sleep(0.4)
data = ''
data = tn.read_very_eager().decode('ascii')
#print(data)
time.sleep(0.4)
################################## enter
#print ("debug8")

#tn.read_until(b">")
tn.write(b""+ b"\r")
time.sleep(1)
data_target = ''
data_target = tn.read_very_eager().decode('ascii')
#print(data_target)
if "State        : ON" in data_target:
	print("APC Port" + ":" + " " + sys.argv[1] + " " + "is" + " ON ")

if "State        : OFF" in data_target:
	print("APC Port" + ":" + " " + sys.argv[1] + " " + "is" + " OFF ")
#print(data_target)

tn.write(b""+ b"\x1B")
#tn.write(b""+ b"\r")
time.sleep(0.4)
data = ''
#data = tn.read_very_eager().decode('ascii')
#print(data)

tn.write(b""+ b"\x1B")
#tn.write(b""+ b"\r")
time.sleep(0.4)
data = ''
#data = tn.read_very_eager().decode('ascii')
#print(data)

tn.write(b""+ b"\x1B")
#tn.write(b""+ b"\r")
time.sleep(0.4)
data = ''
#data = tn.read_very_eager().decode('ascii')
#print(data)

tn.write(b""+ b"\x1B")
#tn.write(b""+ b"\r")
time.sleep(0.4)
data = ''
#data = tn.read_very_eager().decode('ascii')
#print(data)


tn.write(b""+ b"\x1B")
#tn.write(b""+ b"\r")
time.sleep(0.4)
data = ''
#data = tn.read_very_eager().decode('ascii')
#print(data)

tn.write(b""+ b"\x1B")
#tn.write(b""+ b"\r")
time.sleep(0.4)
data = ''
#data = tn.read_very_eager().decode('ascii')
#print(data)


tn.write(b"4"+ b"\r")

time.sleep(0.4)
data = ''
#data = tn.read_very_eager().decode('ascii')
#print(data)


time.sleep(0.4)
tn.close()
#out = tn.read_all().decode()
#print(out)
print(" ")
#print(time.asctime())



