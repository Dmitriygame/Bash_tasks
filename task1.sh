#!/bin/bash

number=1
path="bash"
nameFile="task1.out"
zeros=""

#step 1		handling of arguments

if [ -n "$1" ] || [ -n "$2" ] || [ -n "$3" ]; then

	if [ $1 = "-h" ] || [ $1 = "--help" ]; then
		clear
		echo "This script collects information about hardware, OS and network interface configuration."
		echo "
  -h,  --help    Print this message
  -n num    	 The number of files that will be written to the data
  file           Path where to write the file
	"
	exit 0
	fi

	if [ $# -ge 1 ] && [ $# -le 3 ] ; then
		if [ $1 = "-n" ]; then
			if [ $[ $2 ] -ge 1 ]; then
				number=$[ $2 ]

			elif [ $LANG = "ua_UA.UTF-8" ]; then
				echo "Неприпустиме значення аргументу -n"
				exit 0

			else
				echo "Invalid argument value -n"
				exit 0
			fi
		fi 

		if [ $# -eq 3 ]; then
			pathANDname=$3
			
		elif [ $# -eq 1 ] && [ $1 != "-n" ]; then
			pathANDname=$1
		fi


	elif [ $LANG = "ua_UA.UTF-8" ]; then
		echo "Багато аргументів!"
		exit 0

	else
		echo "Many arguments!"
		exit 0

	fi
fi

if [ -n "$pathANDname" ]; then
		IFS='/' read -ra array <<< "$pathANDname"
		i=${#array[@]}
		i=$i-1
		nameFile="${array[i]}"
		path=${pathANDname//$nameFile/}
		if [ $path = "" ]; then
			path="./"
		fi
fi

#step 2		preparing file path

if [ -n "$1" ] && [ $1="-n" ]; then
	rm -rf $path
	mkdir -p $path
fi

if [ -d "$path" ]; then
	a=0
else
	mkdir -p $path
fi

cd $path
dateName=$(date +"-%Y%m%d")
FILE="$nameFile${dateName}-0000"
touch "$FILE"

#step 3		information collection

touch 1.tmp
> 1.tmp
echo "Date: $(date)" >> $FILE
echo "---- Hardware ----" >> $FILE

grep 'model name' /proc/cpuinfo >> 1.tmp
read tmpLine < 1.tmp
IFS=':' read -ra array <<< "$tmpLine"
cpu=${array[1]}; > 1.tmp
echo $cpu >> 1.tmp | sed 's/^[ \t]*//'
read cpu < 1.tmp 
if [ "$cpu" = "To be filled by O.E.M." ] || [ "$cpu" = "" ]; then
	cpu="Unknown"
fi
echo "CPU: \"$cpu\"" >> $FILE
> 1.tmp
grep 'MemTotal' /proc/meminfo >> 1.tmp
read tmpLine < 1.tmp
IFS=':' read -ra array <<< "$tmpLine"
RAM_kB=${array[1]}
IFS=' ' read -ra array <<< "$RAM_kB"
RAM_MB=$[ ${array[0]} / 1024 ]
echo "RAM: $RAM_MB MB" >> $FILE
> 1.tmp
sudo dmidecode -s baseboard-product-name >> 1.tmp
read tmpLine < 1.tmp ; > 1.tmp
sudo dmidecode -s baseboard-serial-number >> 1.tmp
read tmpLine2 < 1.tmp
if [ "$tmpLine" = "To be filled by O.E.M." ] || [ "$tmpLine" = "" ]; then
	tmpLine="Unknown"
fi
if [ "$tmpLine2" = "To be filled by O.E.M." ] || [ "$tmpLine2" = "" ]; then
	tmpLine2="Unknown"
fi
echo "Motherboard: \"$tmpLine\",  \"$tmpLine2\"" >> $FILE
> 1.tmp
sudo dmidecode -s system-serial-number >> 1.tmp
read tmpLine < 1.tmp
if [ "$tmpLine" = "To be filled by O.E.M." ] || [ "$tmpLine" = "" ]; then
	tmpLine="Unknown"
fi
echo "System Serial Number: $tmpLine" >> $FILE
> 1.tmp
echo "---- System ----" >> $FILE

lsb_release -d | grep "Description" >> 1.tmp
read tmpLine < 1.tmp 
IFS=':' read -ra array <<< "$tmpLine"
tmpLine=${array[1]}; > 1.tmp
echo $tmpLine >> 1.tmp | sed 's/^[ \t]*//'
read tmpLine < 1.tmp 
if [ "$tmpLine" = "To be filled by O.E.M." ] || [ "$tmpLine" = "" ]; then
	tmpLine="Unknown"
fi
echo "OS Distribution: \"$tmpLine\"" >> $FILE
> 1.tmp
echo "Kernel version: $(uname -r)" >> $FILE

sudo tune2fs -l $(df / | tail -1 | cut -f1 -d' ') | grep created >> 1.tmp
read tmpLine < 1.tmp 
IFS=':' read -ra array <<< "$tmpLine"
tmpLine=${array[1]}:${array[2]}:${array[3]}; > 1.tmp
echo $tmpLine >> 1.tmp | sed 's/^[ \t]*//'
read tmpLine < 1.tmp 
if [ "$tmpLine" = "To be filled by O.E.M." ] || [ "$tmpLine" = "" ]; then
	tmpLine="Unknown"
fi
echo "Installation date: $tmpLine" >> $FILE
> 1.tmp
echo "Hostname: $(hostname)" >> $FILE
echo "Uptime: $(uptime -p)" >> $FILE
echo "Processes running: $(ps -e | wc -l)" >> $FILE
echo "User logged in: $(users | wc -l)" >> $FILE
echo "---- Network ----" >> $FILE

ip address show | grep "inet " >> 1.tmp
read tmpLine < 1.tmp
IFS=' ' read -ra array <<< "$tmpLine"
tmpLine=${array[1]}
if [ "$tmpLine" = "" ]; then
	tmpLine="Unknown"
fi
echo "lo: $tmpLine" >> $FILE

tmpLine=$(sed -n 2p 1.tmp)
IFS=' ' read -ra array <<< "$tmpLine"
tmpLine=${array[1]}; > 1.tmp
if [ "$tmpLine" = "" ]; then
	tmpLine="-/-"
fi
ls -1 /sys/class/net/ >> 1.tmp
read tmpLine2 < 1.tmp
echo "$tmpLine2: $tmpLine" >> $FILE
> 1.tmp
echo "----\"EOF\"----" >> $FILE
rm 1.tmp

#step 4		create copies

for (( i=1; i < $number; i++ ))
do
	var=$[ $i/10 ]
	if [ $var -lt 1 ]; then
		zeros="000"
	elif [ $var -lt 10 ]; then
		zeros="00"
	elif [ $var -lt 100 ]; then
		zeros="0"
	fi
	var="$i"
	
	cp "$FILE" "$nameFile${dateName}-$zeros$var"
done

exit 0

