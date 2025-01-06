#ScriptPath
ScriptPath="/$(grep Exec /root/.config/autostart/UUT_loop_main.sh.desktop | cut -d "/" -f 2-4)"

#Testmethod=`cat $ScriptPath/TESTMETHOD`	## AC/DC/Reboot
Testmethod=`grep Test_method $ScriptPath/Loop.conf | sed 's/Test_method=//'g`

#start_time=$(cat script_start.log)
Logfoldername="${Testmethod}_test_logs"
pwd="$HOME/Desktop/$Logfoldername/"

#find $pwd -name *fail.log > "$pwd"Result_Summary.log
ls "$pwd"*fail.log 2> /dev/null 1>"$pwd"Result_Summary.log
ls "$pwd"BMC/*fail.log 2> /dev/null 1>>"$pwd"Result_Summary.log
sed -i '/dmesg/d' "$pwd"Result_Summary.log
#cat Golden_Sample_target.log | sed 's/\..\///g' > robot_title.log
#cat Fail_target.log  > robot_title.log
cp $ScriptPath/golden.robot  "$pwd"Result_Summary.robot
#cp $ScriptPath/qtc.robot  "$pwd"qtc.robot


function_fail(){
while read fail_file
do
#echo $fail_file
if [ -s $fail_file ]; then

	echo $fail_file >> robot_fail.log

fi
done < Fail_target.log
}



tag=Fail_File



##
if [ -s "$pwd"Result_Summary.log ]; then
##	
{
while read line
do

echo
echo	$line
echo "	"[Timeout]"    "15 seconds
echo "	"[Tags]"    "$tag 	
echo "	"'${Golden_Sample}    Get File    ' $line
#echo "	"'${Golden_Sample}    RUN'    cat $line
echo "	"'${time}    Get Modified Time    ${CURDIR}'
echo "	"'Log    ${Golden_Sample}'
echo "	"'Should be Empty    ${Golden_Sample}'
echo "	"Check_Result
echo
echo
echo


done < "$pwd"Result_Summary.log
} >> "$pwd"Result_Summary.robot
##
else
##
{
echo
echo	PASS
echo "	"[Timeout]"    "15 seconds
echo "	"[Tags]"    "PASS 	
echo "	"'${Golden_Sample}    Get File    ' $ScriptPath/PASS
#echo "	"'${Golden_Sample}    RUN'    cat $line
echo "	"'${time}    Get Modified Time    ${CURDIR}'
echo "	"'Log    ${Golden_Sample}'
echo "	"'Should Not be Empty    ${Golden_Sample}'
echo "	"Check_Result
echo
echo
echo
} >> "$pwd"Result_Summary.robot


##
fi
##



source  $ScriptPath/configuration
robot -o "$pwd"Xml_$PJN"_Result_Summary".xml -l "$pwd"Log_$PJN"_Result_Summary".html -r "$pwd"Report_$PJN"_Result_Summary".html "$pwd"Result_Summary.robot 

gnome-terminal --maximize -- bash -c "firefox "$pwd"Log_$PJN"_Result_Summary".html"
