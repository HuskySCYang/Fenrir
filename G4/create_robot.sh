find ../AC_test_logs/ -name *Golden_Sample.log > Golden_Sample_target.log
#cat Golden_Sample_target.log | sed 's/\..\///g' > robot_title.log
cat Golden_Sample_target.log  > robot_title.log

tag=Golden_File



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


done < robot_title.log

