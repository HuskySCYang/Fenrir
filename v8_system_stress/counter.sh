echo
	date
dc_counter=0
while [ $dc_counter != $1 ]
do
	echo -n -e "."
	sleep 1
	let "dc_counter=$dc_counter+1"
done
echo
	date
echo
