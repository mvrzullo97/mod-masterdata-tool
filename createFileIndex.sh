#!/bin/bash

#echo
#echo "-------------------------------------------------------------------------------------------------------"

#USAGE MENU
echo
echo "---------------------- Usage ----------------------"
echo -e "\n   bash $0 -d <input directory> \n"
echo "---------------------------------------------------"
echo

while getopts d: flag
do
    	case "${flag}" in
		d) DIR=${OPTARG};;
		\?) echo -e "\nArgument error! \n"; exit 0 ;;
	esac
done


#params check
if [ $# != 2 ] ; then
	echo
	echo "Param error: right command is -> bash <filename.sh> -d <input_directory>"
	echo
	exit 0
fi

if [ -d $DIR ] ; then
	cd $DIR
	echo $DIR
	#exit 0
	declare -a filename
	z=0
	for file in $(ls | grep -v -e "index.xml" -e "b_up") ; do
		if [ -e $file ] ; then
			filename[z]=$file
			((z++))
		else
			echo "file '$file' not found"
		fi
	done
	cd ..
else
	echo
	echo "Error file declaration: $DIR doesn't exist"
	echo
	exit 0
fi

#get hashcode
cd $DIR
i=0
declare -a array
for file in $(ls -I ".xml" -I "b_up") ; do
	md5=$(md5sum $file | cut -d ' ' -f 1)
	array[i]=$md5
	((i++))
done

#create map key/value (filename/hashcode)
declare -A map
length=${#filename[@]}

for ((i=0; i<$length; i++)) ; do
	map["${filename[i]}"]="${array[i]}"
done

#replace hashcode in .xml
xml_tmp="indexTMP.xml"
xml_fin='index.xml'

>$xml_tmp
ts=$(date +"%Y-%m-%d %H:%M:%S")

cat << EOF > $xml_tmp
<?xml version="1.0" encoding="UTF-8"?>
<acq:fileSet xmlns:acq="http://transit.pr.auto.aitek.it/acquisizione_anagrafiche">
<acq:dataCreazione>${ts}</acq:dataCreazione>
EOF


for key in "${!map[@]}" ; do
echo "...hashcode for file '$key' : OK"
cat << EOF >> $xml_tmp
<acq:files nome="$key" hash="${map[$key]}"/>
EOF
done

cat << EOF >> $xml_tmp
</acq:fileSet>
EOF
echo
echo "...${#map[@]} elements replaced"
echo
echo "------------------------------------------- sleep 10 seconds ------------------------------------------"
sleep 10
echo
echo "...change filename from '$xml_tmp' to '$xml_fin' : OK"
echo
mv $xml_tmp $xml_fin
cat $xml_fin
echo
echo "-------------------------------------------------------------------------------------------------------"
echo
