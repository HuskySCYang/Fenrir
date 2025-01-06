pureversion1(){
pureversion -a 2> /dev/null 1> tmp.log
cat tmp.log | grep -i version 
if [ "$?" == 0 ]; then
purestorage=0
else
purestorage=1
fi
}
pureversion1
echo gg
echo $purestorage
echo aa

