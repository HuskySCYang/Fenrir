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

tn.write(b"i_user" + b"\r")

#print ("2")


tn.read_until(b"Password  :")
tn.write(b"i_passwd"+ b"\r")

#print ("3")
tn.read_until(b"apc>")

################################## >ON, >OFF


#print ("4")

stb = sys.argv[3]


################################# parameter 1-8


sta = sys.argv[2]


stc = "ol"+stb+" " +sta

#print (stc)

tn.write( stc.encode('ascii') + b"\r")
#tn.read_all()  
#time.sleep(1)
line = tn.read_until(b"apc>",timeout=5)  
#print (line)
print (line.splitlines()[:-1])






tn.close()

#print(time.asctime())



