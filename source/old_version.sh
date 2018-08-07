#!/bin/bash
# Created by Artur Nowicki on 23.05.2011.

HOME_PATH="/Users/arturnowicki/IOPAN/code/icm_data_reader"
APPDATA_PATH=${HOME_PATH}"/app_data"
TMP_PATH=${HOME_PATH}"/runtime_data"

ICM_DATA_PATH="/Users/arturnowicki/IOPAN/code/icm_data_reader/test_data/icm_data"
TMP_DATA_PATH="/Users/arturnowicki/IOPAN/code/icm_data_reader/test_data/tmp_data"

#read in system date and time
cd "$HOME_PATH"/list_files

daysim=(31 28 31 30 31 30 31 31 30 31 30 31)
err2=0
data=`date "+%y%m%d"`
day=`date "+%d"`
month=`date "+%m"`
year=`date "+%y"`
hour=`date "+%k"`
minute=`date "+%M"`
S=`date "+%s"`
 ((sec=S%60))
echo

rm "$HOME_PATH"/storage/current/*
rm "$HOME_PATH"/storage/2km/*
rm "$HOME_PATH"/storage/tmp/*
rm "$HOME_PATH"/storage/6hpacks/2km/*

data_dld_err=1
read data_err < data.stat
mod_out_stat=-1
all_err=1
err3=0
err4=0
err5=0

#check last update
ctr=0
while read lup
do
	let ctr=$ctr+1
	if [ $ctr -lt 5 ]; then
		let "up$ctr=10#$lup"
	fi
done <lastup.txt
if [ $up2 -lt 10 ]; then
	up2="0$up2"
fi
if [ $up3 -lt 10 ]; then
	up3="0$up3"
fi
if [ $up4 -lt 10 ]; then
	up4="0$up4"
fi

#set hour of latest data to download
if [ $hour -ge 0 ]; then
	shr=00
fi
if [ $hour -ge 6 ]; then
	shr=06
fi
if [ $hour -ge 12 ]; then
	shr=12
fi
if [ $hour -ge 18 ]; then
	shr=18
fi
echo "--------------"
echo "Current time:"
echo "20"$year $month $day $hour":"$minute
echo "Latest expected update:"
echo "20"$year $month $day $shr":00"
echo "Last update:"
echo $up1 $up2 $up3 $up4":00"
echo
#read in list of files on  ICM server
echo 'Reading in list of files from ICM server...'
echo
HOST='ftpmeteo.icm.edu.pl'
USER='iopan'
PASSWD='austrul'
ftp -n $HOST <<END_SCRIPT
quote USER $USER
quote PASS $PASSWD
cd um/
ls *.tbz icm1_tmp1.txt
EOF>>
END_SCRIPT

echo
#adjust list from icm1_tmp1.txt
cd "$HOME_PATH"/execs
./ls_adj
if [ $? != 0 ]; then
	echo "list of files exceeds max lenght at ls_adj"
	break
fi
echo

cd "$HOME_PATH"/list_files/

echo
#------------------------------------
		echo "---PREVIOUS UPDATE---"
#------------------------------------
		#check if last update is older then currently expected
		if [[ 20$year$month$day$shr -gt $up1$up2$up3$up4 && data_err -eq 1 ]]; then
			datect=`date "+%y%m%d%H"`
			current_time="20"$datect
			wwf=1
			let ffstat=0
			#calculate time difference in hours
			d1=`date -j -f "%Y%m%d %H%M" "20$year$month$day ${shr}00" +%s`
			d2=`date -j -f "%Y%m%d %H%M" "$up1$up2$up3 ${up4}00" +%s`
			let diff_in_hours=(d1-d2)/3600
			let lastuptime=$up1$up2$up3$up4+1

			let diff_t=$diff_in_hours-1
			while [[ $diff_t -gt 0 && $ffstat -eq 0 ]]
			do
				let diff_t=$diff_t-1
				let	ww=$diff_t*1
				ww=$ww"H"
				datect=`date -v-$ww "+%y%m%d%H"`
				if [ -f icm1_tmp1.txt ]; then
				li=`grep -c 20$datect icm1_tmp1.txt`
				if [ $li -eq 3 ]; then
					echo "IOPAN1_20$datect"".tbz"nn"IOPAN2_20$datect"".tbz"nn"IOPAN3_20$datect"".tbz" >clb1_tmp.txt
					awk 'gsub("nn","\n") {print}' clb1_tmp.txt > tdb3_tmp.txt
					echo "Downloading data from 20$datect""..."
					while read myline
					do
						echo $myline
						HOST='ftpmeteo.icm.edu.pl'
						USER='iopan'
						PASSWD='austrul'
						ftp -n $HOST <<END_SCRIPT
						quote USER $USER
						quote PASS $PASSWD
						binary
						cd um/
						get $myline ../storage/tmp/$myline
END_SCRIPT
					done < tdb3_tmp.txt
					#extract all files
					echo
					echo	"Extracting files..."
					echo
					cd ../storage/tmp/
					for i in *.tbz
					do
						echo $i
						tar -xjf "$i"
						if [ $? != 0 ]; then
							echo $i extraction failure!
							err2=1
						fi
					done
					if [ $err2 == 0 ]; then
						#remove previous files
						cd ../current/
						find . -name '*' | xargs rm
						cd ../tmp/
						rm *tbz
						mv * ../current/
						echo "Remaping all files to 600x640 2km grid..."
						cd ../current/
						ls > ../../list_files/in.txt
						cd ../../execs/
						dataConverterError=0
						for idx0 in {1..3}
						do
							./data_converter_2km
							dataConverterError=$?
							if [ $dataConverterError == 0 ]; then
								break;
							fi
							echo "Attempt $idx0, errorStatus $dataConverterError"
						done
						if [ $dataConverterError == 0 ]; then
							shr1=`echo $datect | cut -b 7-8`
							day1=`echo $datect | cut -b 5-6`
							month1=`echo $datect | cut -b 3-4`
							year1=`echo $datect | cut -b 1-2`
							echo "Preparing binary files..."
							./6hpacks_prc "20"$year1 $month1 $day1 $shr1
							echo "Preparing 24h NetCDF files..."
							./op_prc $day1 $month1 $shr1 $year1 "01" > ../list_files/f1.txt 2>../list_files/op_err1.txt
							if [ $? != 0 ]; then
								err3=1
							fi
							./op_prc $day1 $month1 $shr1 $year1 "02" >> ../list_files/f1.txt 2>../list_files/op_err2.txt
							if [ $? != 0 ]; then
								err4=1
							fi
							./op_prc $day1 $month1 $shr1 $year1 "03" >> ../list_files/f1.txt 2>../list_files/op_err3.txt
							if [ $? != 0 ]; then
								err5=1
							fi
							let ctrl_sum=$err3+$err4+$err5
							if [ $ctrl_sum != 0 ]; then
								echo "Error occurred: "
								echo "run 1: " $err3
								cat ../list_files/op_err1.txt
								echo "run 2: " $err4
								cat ../list_files/op_err2.txt
								echo "run 3: " $err5
								cat ../list_files/op_err3.txt
								cd ../list_files/
							else
								cd ../list_files/
								echo "Files ready."
								let ffstat=1
							fi
							cd ../storage/2km/
							find . -name '*' | xargs rm
							cd ../6hpacks/2km/
							find . -name '*' | xargs rm
							cd ../../current/
							find . -name '*' | xargs rm
							cd ../../list_files/
						else #330
							echo "Interpolation error:" $?
							cd ../list_files/
						fi #330
					else #316
						rm *
						echo "Files not complete."
						cd ../../list_files/
					fi #316
				fi #284
				fi
			done #278
		else #272
			echo "Already done."
			echo
		fi #272
rm *tmp.txt
rm icm1_tmp1.txt


echo "Done."
echo
