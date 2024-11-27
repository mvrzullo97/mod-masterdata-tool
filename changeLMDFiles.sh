#!/bin/bash

#V.2.0
is_rete_1=false
PRG_file="PRG_persistence.txt"
OUT_DIR="out-dir-LMD"
direzioni=('00997' '00998')
cls_vcl=('10' '20' '30' '40' '50')

function str_padd_pnt
{
        pad="0"
        str=$1
        while [ ${#str} != 5 ]
        do
                str=$pad$str
        done
        echo ${str}
}

function str_padd_soc
{
	pad="0"
	str=$1
	while [ ${#str} != 3 ]
	do
		str=$pad$str
	done
	echo ${str}
}

#CREATE OUT_DIR
if ! [ -d $OUT_DIR ] ; then
	mkdir $OUT_DIR
	path_dir=$(realpath $OUT_DIR)
else
	path_dir=$(realpath $OUT_DIR)
fi

#USAGE MENU
echo
echo "---------------------- Usage ----------------------"
echo -e "\n   bash $0\n\n    -d <input directory> \n    -v <validity date (YYYY-MM-DD)> \n    -r <rete (ex. 1)> \n    -u <punto uscita (ex. 410)> \n    -e <punto entrata (solo per rete 1)>\n    -c <classe veicolo (10,20,30,40,50)> \n    -s <società (ex. 6)> \n    -n <nuovo importo non arrotondato (ex. 00241769)> \n    -i <nuovo importo arrotondato (ex. 00242)>"
echo

while getopts d:v:r:u:e:c:s:n:i: flag
do
    case "${flag}" in
		d) DIR=${OPTARG};;
		v) val_date=${OPTARG};;
		r) rete=${OPTARG};;
		u) pnt_usc=${OPTARG};;
		e) pnt_ent=${OPTARG};; # opzionale
		c) cls=${OPTARG};;
		s) soc=${OPTARG};;
		n) i_no_arr=${OPTARG};;
		i) i_arr=${OPTARG};;
		\?) echo -e "\nArgument error! \n"; exit 0 ;;
	esac
done

#PARAMS CHECK
if [ $# != 16 ] && [ $# != 18 ] ; then
        echo "Argument error: please digit right command."
	echo
	exit 0
fi

#CHECK DIRECTORY
if ! [ -e $DIR ] ; then
        echo "Error: directory '$DIR' not found"
	echo
        exit 0
fi

#CHECK DATE FORMAT
if ! [[ $val_date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo "Param error: invalid date format, it must be YYYY-MM-DD"
        echo
	exit 0
fi

#CHECK CLASSE_VEICOLO
if ! [[ ${cls_vcl[@]} =~ $cls ]] ; then
        echo "Param error: classe veicolo '$cls' doesn't exist."
        echo
        exit 0
fi

#CHECK RETE
pd="0"
pd2="00"
if [ $rete = 1 ] ; then
        rete_pk="$pd2$rete"
        is_rete_1=true
else
        rete_pk="$pd$rete"
fi

cd $DIR
rete_check=$(ls | grep 'Pedaggi' | grep "$rete_pk")

if [ -z "$rete_check" ] ; then
	echo "Param error: rete '$rete' doesn't exist."
	echo
	exit 0
fi

#CHECK MATCH RETE/STAZIONE
srt_l="D"
if $is_rete_1 ; then
	pnt_ent=$(str_padd_pnt $pnt_ent)
	pnt_usc=$(str_padd_pnt $pnt_usc)
	line_ent_usc="$(grep -E "$srt_l.{9}$pnt_ent$pnt_usc" $rete_check)"
	if [ -z "$line_ent_usc" ] ; then
		echo "Param error: the combination of entrata '$pnt_ent' and uscita '$pnt_usc' for rete '$rete' doesn't exist in '$rete_check'."
		echo
		exit 0
	fi
else
	dumb_dir="00997"
	pnt_usc=$(str_padd_pnt $pnt_usc)
	line_dir_usc="$(grep -E "$srt_l.{9}$dumb_dir$pnt_usc" $rete_check)"
	if [ -z "$line_dir_usc" ] ; then
		echo "Param error: the combination of uscita '$pnt_usc' for rete '$rete' doesn't exist in '$rete_check'."
                echo
                exit 0
        fi
fi

#CHECK SOCIETA'
soc=$(str_padd_soc $soc)
line_dir_usc="$(grep -E "$srt_l.{31}$soc" $rete_check)"
if [ -z "$line_dir_usc" ] ; then
	echo "Param error: società '$soc' for rete '$rete' doesn't exist in '$rete_check'."
        echo
        exit 0
fi

#CHECK LENGTH OF IMPORTO NON ARROTONDATO
if [ ${#i_no_arr} != 8 ] ; then
        echo "Param error: string's length 'importo_NON_arrotondato' must be 8"
        echo
	exit 0
fi

#CHECK LENGTH OF IMPORTO ARROTONDATO
if [ ${#i_arr} != 5 ] ; then
        echo "Param error: string's length 'importo_arrotondato' must be 5"
        echo
	exit 0
fi

echo "----------------------------------------------------------------------------------------------"
echo

#------------------------------------------------ FILE PEDAGGI_YYYYMMDD_RRR_PPPPP

FILE_tmp=$(ls | grep 'Pedaggi' | grep "$rete_pk")

if ! [ -f "$FILE_tmp" ] ; then
        echo "file '$FILE_tmp' not found"
        exit 0
else
	sed -i 's/\x0//g' $FILE_tmp #pulizia del file dagli eventuali 'null bytes' 
	cp $FILE_tmp $path_dir
	echo "...file '$FILE_tmp' copied in '$OUT_DIR' : OK"
	echo
fi

#GET NEW PRG FROM FILE prg.persistence.txt
prg_f="$(grep $rete_pk $PRG_file)"
search_prg_file=${prg_f:3:5}

# AUTOINCREMENT PRG VALUE
old_prg="$(expr $search_prg_file + 0)"
new_prg_tmp="$(expr $search_prg_file + 1)"
new_prg=${search_prg_file/"$old_prg"/$new_prg_tmp}
#check length of new_prg (5)
if [ ${#new_prg} != 5 ] ; then
        new_prg="${new_prg:1}"
fi

#CHANGE TIMESTAMP and PRG in HEADER
cd ..
cd $path_dir
s='HRIPARTI'
header="$(grep $s $FILE_tmp)"
search_date=${header:21:10} #offset
search_prg=${header:42:5} #offset
new_header=$(echo "$header" | sed "s/$search_date/$val_date/" | sed "s/$search_prg/$new_prg/")
sed -i "s/$header/$new_header/" $FILE_tmp
echo "[HEADER]...change validity date from '$search_date' to '$val_date': OK"
echo "[HEADER]...change prg value from '$search_prg_file' to '$new_prg' : OK"
echo

#CHANGE PEDAGGI
srt_l="D"
if $is_rete_1 ; then

	# per ENTRATA->USCITA
	line_ped="$(grep -E "$srt_l.{9}$pnt_ent$pnt_usc.{5}$cls.{5}$soc" $FILE_tmp)"
        search_no_arr=${line_ped:35:8}
        search_arr=${line_ped:43:5}
        new_line_ped=$(echo "$line_ped" | sed "s/$search_no_arr/$i_no_arr/" | sed "s/$search_arr/$i_arr/")
        sed -i "s/$line_ped/$new_line_ped/" $FILE_tmp
        echo "[BODY]...change 'importo non arrotondato' from '$search_no_arr' to '$i_no_arr' for entrata '$pnt_ent' e uscita '$pnt_usc' : OK"
        echo "[BODY]...change 'importo arrotondato' from '$search_arr' to '$i_arr' for entrata '$pnt_ent' e uscita '$pnt_usc' : OK"
	echo

	#per USCITA->ENTRATA
	line_ped="$(grep -E "$srt_l.{9}$pnt_usc$pnt_ent.{5}$cls.{5}$soc" $FILE_tmp)"
        search_no_arr=${line_ped:35:8}
        search_arr=${line_ped:43:5}
        new_line_ped=$(echo "$line_ped" | sed "s/$search_no_arr/$i_no_arr/" | sed "s/$search_arr/$i_arr/")
        sed -i "s/$line_ped/$new_line_ped/" $FILE_tmp
        echo "[BODY]...change 'importo non arrotondato' from '$search_no_arr' to '$i_no_arr' for entrata '$pnt_usc' e uscita '$pnt_ent' : OK"
	echo "[BODY]...change 'importo arrotondato' from '$search_arr' to '$i_arr' for entrata '$pnt_usc' e uscita '$pnt_ent' : OK"
	echo
else
	for dir in "${direzioni[@]}" ; do
	# per DIREZIONE 997 E 998
        	line_ped="$(grep -E "$srt_l.{9}$dir$pnt_usc.{5}$cls.{5}$soc" $FILE_tmp)"
        	search_no_arr=${line_ped:35:8}
        	search_arr=${line_ped:43:5}
        	new_line_ped=$(echo "$line_ped" | sed "s/$search_no_arr/$i_no_arr/" | sed "s/$search_arr/$i_arr/")
        	sed -i "s/$line_ped/$new_line_ped/" $FILE_tmp
        	echo "[BODY]...change 'importo non arrotondato' from '$search_no_arr' to '$i_no_arr' for uscita '$pnt_usc' direzione '$dir' : OK"
        	echo "[BODY]...change 'importo arrotondato' from '$search_arr' to '$i_arr' for uscita '$pnt_usc' direzione '$dir' : OK"
		echo
	done
fi

echo "----------------------------------------------------------------------------------------------"
echo

#------------------------------------------------ FILE PUNTI_YYYYMMDD_RRR_PPPPP

cd ..
cd $DIR
FILE2_tmp=$(ls | grep 'Punti' | grep "$rete_pk")

if ! [ -f "$FILE2_tmp" ] ; then
        echo "file '$FILE2_tmp' not found"
        exit 0
else
		sed -i 's/\x0//g' $FILE2_tmp #pulizia del file dagli eventuali 'null bytes' 
        cp $FILE2_tmp $path_dir
        echo "...file '$FILE2_tmp' copied in '$OUT_DIR' : OK"
	echo
fi

cd ..
cd $path_dir
s='HPUNTI'
header="$(grep -a $s $FILE2_tmp)"


search_date=${header:21:10} #offset
search_prg=${header:42:5} #offset
new_header=$(echo "$header" | sed "s/$search_date/$val_date/" | sed "s/$search_prg/$new_prg/")
sed -i "s/$header/$new_header/" $FILE2_tmp
echo "[HEADER]...change validity date from '$search_date' to '$val_date': OK"
echo "[HEADER]...change prg value from '$search_prg_file' to '$new_prg' : OK"
echo
echo "----------------------------------------------------------------------------------------------"
echo
#------------------------------------------------ FILE PERCORSI-PORTALI_YYYYMMDD_RRR_PPPPP

if $is_rete_1 ; then
	cd ..
	cd $DIR
	FILE3_tmp=$(ls | grep 'Percorsi-Portali' | grep "$rete_pk")

	if ! [ -f "$FILE3_tmp" ] ; then
        	echo "file '$FILE3_tmp' not found"
        	exit 0
	else
			sed -i 's/\x0//g' $FILE3_tmp #pulizia del file dagli eventuali 'null bytes' 
        	cp $FILE3_tmp $path_dir
        	echo "...file '$FILE3_tmp' copied in '$OUT_DIR' : OK"
        	echo
	fi
	cd ..
	cd $path_dir
	s='HPERCORSI-PORTALI'
	header="$(grep $s $FILE3_tmp)"
	search_date=${header:21:10} #offset
	search_prg=${header:42:5} #offset
	new_header=$(echo "$header" | sed "s/$search_date/$val_date/" | sed "s/$search_prg/$new_prg/")
	sed -i "s/$header/$new_header/" $FILE3_tmp
	echo "[HEADER]...change validity date from '$search_date' to '$val_date': OK"
	echo "[HEADER]...change prg value from '$search_prg_file' to '$new_prg' : OK"
	echo
	echo "----------------------------------------------------------------------------------------------"
	echo

else #modifica file percorsi e portali in caso di rete != 1

	cd ..
	cd $DIR

	FILE3_tmp=$(ls | grep 'Percorsi-Portali' | grep "001")

	if ! [ -f "$FILE3_tmp" ] ; then
			echo "file '$FILE3_tmp' not found"
			exit 0
	else
			sed -i 's/\x0//g' $FILE3_tmp #pulizia del file dagli eventuali 'null bytes' 
			cp $FILE3_tmp $path_dir
			echo "...file '$FILE3_tmp' copied in '$OUT_DIR' : OK"
			echo		
	fi
		prg_rete_1="$(grep "001" $PRG_file)"
		cd ..
		cd $path_dir
		s='HPERCORSI-PORTALI'
		header="$(grep $s $FILE3_tmp)"	
		
		search_prg_rete_1=${prg_rete_1:3:5}
		search_prg=${header:42:5} #offset
				
		search_date=${header:21:10} #offset
		new_header=$(echo "$header" | sed "s/$search_date/$val_date/" | sed "s/$search_prg/$search_prg_rete_1/")
		sed -i "s/$header/$new_header/" $FILE3_tmp
		echo "[HEADER]...change validity date from '$search_date' to '$val_date': OK"
		echo
		echo "----------------------------------------------------------------------------------------------"
		echo

	new_val_date=$(echo $val_date | sed 's/-//g')
	new_f=$(echo $FILE3_tmp | sed "s/YYYYMMDD/$new_val_date/ "| sed "s/PPPPP/$search_prg_rete_1/")
	echo $new_f
	mv $FILE3_tmp $new_f
	echo "...change filename from '$FILE3_tmp' to '$new_f' : OK"

fi

#RENAME FILES
new_val_date=$(echo $val_date | sed 's/-//g')
for f in $(ls | grep "$rete_pk") ; do
        new_f=$(echo $f | sed "s/YYYYMMDD/$new_val_date/" | sed "s/PPPPP/$new_prg/")
        mv $f $new_f
	echo "...change filename from '$f' to '$new_f' : OK"
done
echo

#PRG PERSISTENCE
cd ..
cd $DIR
prg_f="$(grep -E "$rete_pk.{5}" $PRG_file)"
search_prg=${prg_f:3:5}
new_prg_f=$rete_pk$new_prg
sed -i "s/$prg_f/$new_prg_f/" $PRG_file
echo "...modify '$PRG_file' with a new PRG VALUE from '$search_prg' to '$new_prg' for rete '$rete' : OK"
echo

continua=true
while $continua ; do
	read -rep $'Do you want launch createFileIndex.sh script to create file index.xml? [y/n] \n' response
	if [[ "$response" =~ ^([yY])$ ]] ; then
		cd ..
		continua=false
        bash createFileIndex.sh -d $OUT_DIR
	elif [[ "$response" =~ ^([nN])$ ]] ; then 
		continua=false
		exit 0
	else
		echo
        echo "Please digit a valid answer! [y or Y / n or N]"
		echo
	fi
done
