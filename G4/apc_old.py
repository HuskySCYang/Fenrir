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
tn = telnetlib.Telnet(sys.argv[1])
tn.read_until(b"User Name :")
tn.write(b"apc" + b"\r\n")
#print ("2")


tn.read_until(b"Password  :")

tn.write(b"apc"+ b"\r\n")

data = ''
while data.find('#') == -1:
	dtat = tn.read_very_eager()
print (data)


#print ("3")
tn.read_until(b"Main Menu")

time.sleep (1)
################################## Device Manager
print ("debug1")

out = tn.read_sb_data().decode()
print(out)

tn.write(b"1"+ b"\r")
time.sleep (1)

################################## Outlet Management
print ("debug2")
tn.read_until(b"Outlet Management")
out = tn.read_sb_data().decode()
print(out)

tn.write(b"2"+ b"\r")
time.sleep (1)

################################## Outlet Control/Configuration
print ("debug3")
out = tn.read_sb_data().decode()
print(out)
tn.read_until(b"Outlet Control")
tn.write(b"1"+ b"\r")
time.sleep (1)

################################## outlet port 
print ("debug4")
out = tn.read_sb_data().decode()
print(out)
tn.read_until(b"Master")
if sys.argv[2] == 1:
	tn.tn.write(b"1"+ b"\r")
elif sys.argv[2] == 7:
	tn.tn.write(b"7"+ b"\r")
	
time.sleep (1)

################################## Outlet Control
print ("debug5")
out = tn.read_sb_data().decode()
print(out)
tn.read_until(b">")
tn.write(b"1"+ b"\r")
time.sleep (1)

################################# 1:on, 2:off 
print ("debug6")
out = tn.read_sb_data().decode()
print(out)
tn.read_until(b">")
if sys.argv[3] == "on":
	tn.write(b"1"+ b"\r")
	print("gg1")
elif sys.argv[3] == "off":
	tn.write(b"2"+ b"\r")
	print("gg2")
else:
	print ("invalid parameter")	
time.sleep (1)

################################## yes
print ("debug7")
out = tn.read_sb_data().decode()
print(out)
tn.read_until(b">")
tn.write(b"YES"+ b"\r")
time.sleep (1)

################################## enter
print ("debug8")
out = tn.read_sb_data().decode()
print(out)
tn.read_until(b">")
tn.write(b""+ b"\r")
time.sleep (1)


tn.close()
out = tn.read_all().decode()
print(out)

#print(time.asctime())



