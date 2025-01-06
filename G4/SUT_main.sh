
go_SUTPATH(){
	cd $SUTPATH
}
	go_SUTPATH


. $SUTPATH/SUT_local.sh 2>&1 | tee $SUTPATH/local_main/tmp.log

i_count=$(cat $SUTPATH/loop_count.txt | grep "1" -c)
echo $i_count >> $SUTPATH/local_main/count.log
mv $SUTPATH/local_main/tmp.log $SUTPATH/local_main/local_AC_$i_count.log



shutdown_set=$(cat $SUTPATH/AC.method)
if [ "$shutdown_set" == 1 ]; then	
	#ipmitool sel clear	
	sleep 10
	shutdown -h now
else
	cat APC | grep -i "done" > /dev/null
	if [ "$?" == 0 ]; then
	echo "AC stress done."
	else
	echo "Wait for APC off and Force Shutdown.."
	#ipmitool sel clear
	sleep 1
	fi
fi
