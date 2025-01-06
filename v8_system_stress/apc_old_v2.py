import telnetlib
import time
import sys



tn = telnetlib.Telnet("192.168.2.12")
time.sleep(1)

tn.read_until(b"User Name")
tn.write(b"apc" + b"\r")

tn.read_until(b"Password")
tn.write(b"apc" + b"\r")

tn.read_until(b"Device Manager")
tn.write(b"1" + b"\r")

tn.read_until(b"Outlet Management")
tn.write(b"2" + b"\r")


tn.read_until(b"Outlet Control")
tn.write(b"1" + b"\r")



################################# outlet control
tn.read_until(b"Outlet 1")

sta = sys.argv[1]

if  sta == "1" :

	
	tn.write(b"1" + b"\r")

elif sta == "2" :
	tn.write(b"2" + b"\r")

elif sta == "3" :
	tn.write(b"3" + b"\r")

elif sta == "4" :
	tn.write(b"4" + b"\r")

elif sta == "5" :
	tn.write(b"5" + b"\r")


elif sta == "6" :
	tn.write(b"6" + b"\r")

elif sta == "7" :
	tn.write(b"7" + b"\r")


elif sta == "8" :
	tn.write(b"8" + b"\r")
	




tn.read_until(b"Name")
tn.write(b"1" + b"\r")


################################## 1>ON, 2>OFF


tn.read_until(b"Immediate On")
stb = sys.argv[2]

if  stb == "on" :

	
	tn.write(b"1" + b"\r")

elif stb == "off" :

	tn.write(b"2" + b"\r")



tn.read_until(b"turn")
tn.write(b"YES" + b"\r")


#print (tn.read_all())

tn.close()





