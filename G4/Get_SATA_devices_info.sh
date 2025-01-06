#!/bin/bash
#ScriptPath
#ScriptPath="/$(grep Exec /root/.config/autostart/UUT_loop_main.sh.desktop | cut -d "/" -f 2-4)"
if [ -f SATA_all.log ]; then
	cat SATA_all.log	
	else
	echo "There is no SATA device in System."
fi
