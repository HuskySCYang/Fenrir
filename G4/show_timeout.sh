timeout_counter=0
echo 
echo "Wait $1 seconds for OS ready."
echo
while [ "$timeout_counter" != "$1" ]
do

echo -n -e "."
sleep 1
let "timeout_counter=$timeout_counter+1"
done

echo 
echo "OS is ready !!"
echo
echo 
echo "Loading the Scripts..................."
echo

#ScriptPath
ScriptPath="/$(grep Exec /root/.config/autostart/UUT_loop_main.sh.desktop | cut -d "/" -f 2-4)"
echo 
echo "Scripts are running..................."
echo

while true
do
	
final=$(cat $ScriptPath/script.status | grep -i "Script test completed" -c)
if [ "$final" == 1 ]; then
	break
else
        cat $ScriptPath/script.status | grep "going" > /dev/null
	if [ "$?" == 0 ]; then
		echo -n -e "."
	else
		echo
		cat $ScriptPath/script.status
		echo
	fi
fi
sleep 1
done


backup(){
while true
do
	
final=$(cat $ScriptPath/script.status | grep -i "Script test completed" -c)
if [ "$final" == 1 ]; then
	break
else
        cat $ScriptPath/script.status2 | grep "going" > /dev/null
	if [ "$?" == 0 ]; then
		echo -n -e "."
	else
		echo
		cat $ScriptPath/script.status1
		echo
	fi
fi
sleep 1
done
}
