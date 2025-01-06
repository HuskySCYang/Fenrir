#ScriptPath
ScriptPath="/$(grep Exec /root/.config/autostart/UUT_loop_main.sh.desktop | cut -d "/" -f 2-4)"

#Testmethod=`cat $ScriptPath/TESTMETHOD`	## AC/DC/Reboot
Testmethod=`grep Test_method $ScriptPath/Loop.conf | sed 's/Test_method=//'g`

#start_time=$(cat script_start.log)
Logfoldername="${Testmethod}_test_logs"
pwd="$HOME/Desktop/$Logfoldername/"

#cat Golden_Sample_target.log | sed 's/\..\///g' > robot_title.log
#cat Fail_target.log  > robot_title.log
cp $ScriptPath/golden.robot  "$pwd"Golden_Sample.robot
cp $ScriptPath/qtc.robot  "$pwd"qtc.robot

find $pwd -name *Golden_Sample.log > "$pwd"Golden_Sample_target.log
#find ../AC_test_logs/ -name *Golden_Sample.log > Golden_Sample_target.log
#cat Golden_Sample_target.log | sed 's/\..\///g' > robot_title.log
#cat Golden_Sample_target.log  > robot_title.log

tag=Golden_File

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
echo "	"Check_Result
echo
echo
echo


done < "$pwd"Golden_Sample_target.log

} >> "$pwd"Golden_Sample.robot 

source $ScriptPath/configuration
robot -o "$pwd"Xml_$PJN"_Golden_Sample".xml -l "$pwd"Log_$PJN"_Golden_Sample".html -r "$pwd"Report_$PJN"_Golden_Sample".html "$pwd"Golden_Sample.robot 


sleep 1

gnome-terminal --maximize -- bash -c "firefox "$pwd"Log_$PJN"_Golden_Sample".html"
