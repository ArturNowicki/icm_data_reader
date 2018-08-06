#!/bin/bash
# Created by Artur Nowicki on 02.08.2018.

HOME_PATH="/Users/arturnowicki/IOPAN/code/icm_data_reader"
CONFIG_PATH=${HOME_PATH}"/config"
APPDATA_PATH=${HOME_PATH}"/app_data"
TMP_PATH=${HOME_PATH}"/runtime_data"

ICM_DATA_PATH="/Users/arturnowicki/IOPAN/code/icm_data_reader/test_data/icm_data"
TMP_DATA_PATH="/Users/arturnowicki/IOPAN/code/icm_data_reader/test_data/tmp_data"

LOG_FILE=${APPDATA_PATH}"/logs.txt"
USED_ICM_ARCHIVES=${APPDATA_PATH}"/used_icm_files.txt"
PROGRESS_FILE=${APPDATA_PATH}"/download_progress.info"
ICM_FILES_QUEUE=${APPDATA_PATH}"/icm_files.queue"
ARCHIVES_LIST=${TMP_PATH}"/archives.tmp"

rm ${LOG_FILE} # to be removed

LOGGING_LEVEL="DEBUG"

USED_PARAMS=("03225" "03226" "03236" "03237" "03250" "03460" "03461" "09203" "09204" \
"09205" "09217" "16222" "04201" "04202" "05201" "05202" "01201" "01235" "02201" "02207")

ICM_HOST='ftpmeteo.icm.edu.pl'
ICM_USER='iopan'
ICM_PASSWD='austrul'

source logging.sh

function get_current_time {
	current_date=`date "+%y%m%d"`
	current_day=`date "+%d"`
	current_month=`date "+%m"`
	current_year=`date "+%y"`
	current_hour=`date "+%k"`
	current_minute=`date "+%M"`
}

function get_update_time {
	ctr=0
	while read lup
	do
		let ctr=$ctr+1
		if [ $ctr -lt 5 ]; then
			let "up$ctr=10#$lup"
		fi
	done <${APPDATA_PATH}"/last_update.info"
	if [ $? -ne 0 ]; then
		log_error ${FUNCNAME[0]} "Error reading last update time from ${APPDATA_PATH}/last_update.info"
		exit
	fi
	if [ $up2 -lt 10 ]; then
		up2="0$up2"
	fi
	if [ $up3 -lt 10 ]; then
		up3="0$up3"
	fi
	if [ $up4 -lt 10 ]; then
		up4="0$up4"
	fi
}

function set_download_hour {
	if [ $current_hour -ge 0 ]; then
		download_hour=00
	fi
	if [ $current_hour -ge 6 ]; then
		download_hour=06
	fi
	if [ $current_hour -ge 12 ]; then
		download_hour=12
	fi
	if [ $current_hour -ge 18 ]; then
		download_hour=18
	fi
}

function log_init_message {
	log_info ${FUNCNAME[0]} "Current time: 20${current_year} ${current_month} ${current_day} ${current_hour}:${current_minute}"
	log_info ${FUNCNAME[0]} "Latest expected update: 20${current_year} ${current_month} ${current_day} ${download_hour}:00"
	log_info ${FUNCNAME[0]} "Last update: ${up1} ${up2} ${up3} ${up4}:00"
	log_info ${FUNCNAME[0]} "Progress status: ${progress_status}"
}

function get_icm_data_list {
	log_info ${FUNCNAME[0]} "Reading in list of files from ICM server..."
	err=$(cp ${HOME_PATH}"/icm1_tmp1.txt" ${TMP_PATH}"/remote_list.tmp" 2>&1 >/dev/null)
	if [ $? -ne 0 ]; then
		log_error ${FUNCNAME[0]} "$err"
		exit
	fi
}

function format_icm_list {
	if [ -e ${TMP_PATH}"/remote_list2.tmp" ]; then
		rm ${TMP_PATH}"/remote_list2.tmp"
	fi
	while read new_line; do
		IFS=' ' read -r -a array <<< "$new_line"
		echo ${array[8]} >> ${TMP_PATH}"/remote_list2.tmp"
	done <${TMP_PATH}"/remote_list.tmp"
	if [ $? -ne 0 ]; then
		log_error ${FUNCNAME[0]} "Error reading files list from ${TMP_PATH}/remote_list2.tmp"
		exit
	fi	
	err=$(mv ${TMP_PATH}"/remote_list2.tmp" ${TMP_PATH}"/remote_list.tmp" 2>&1 >/dev/null)
	if [ $? -ne 0 ]; then
		log_error ${FUNCNAME[0]} "$err"
		exit
	fi
}
function get_download_list {
	err=$(diff ${USED_ICM_ARCHIVES} ${TMP_PATH}"/remote_list.tmp" > ${TMP_PATH}"/list_diff1.tmp" 2>/dev/null)
	if [ $? -gt 1 ]; then
		log_error ${FUNCNAME[0]} "$err"
		exit
	fi
	awk '/>/ {print}' ${TMP_PATH}"/list_diff1.tmp" > ${TMP_PATH}"/list_diff2.tmp"
	cut -d " " -f 2- ${TMP_PATH}"/list_diff2.tmp" > ${TMP_PATH}"/list_diff1.tmp"
	rm ${TMP_PATH}"/list_diff2.tmp"
	if [[ ! -s ${TMP_PATH}"/list_diff1.tmp" ]]; then
		rm ${TMP_PATH}"/list_diff1.tmp"
		log_info ${FUNCNAME[0]} "No new data to download"
		log_info ${FUNCNAME[0]} "DONE"
		exit
	fi
}

function download_archives {
	if [ -e ${ARCHIVES_LIST} ]; then
		rm ${ARCHIVES_LIST}
	fi
	ctr=1
	while read new_line; do
		log_info ${FUNCNAME[0]} "Downloading ${new_line}"
		err=$(echo "HERE GOES ACTUAL DOWNLOAD ROUTINE")
		if [ $? -ne 0 ]; then
			log_error ${FUNCNAME[0]} "$err"
			exit
		fi
		((ctr++))
	# sed -i "/pattern to match/d" .../infile
		echo ${TMP_DATA_PATH}/${new_line} >> ${ARCHIVES_LIST}
		if [ $? -ne 0 ]; then
			log_error ${FUNCNAME[0]} "Cannot add new line to ${ARCHIVES_LIST}"
			exit
		fi
		err=$(sed -i "" "/${new_line}/d" ${TMP_PATH}/list_diff1.tmp 2>&1 >/dev/null)
		if [ $? -ne 0 ]; then
			log_error ${FUNCNAME[0]} "$err"
			exit
		fi
	done <${TMP_PATH}"/list_diff1.tmp"
	if [ $? -ne 0 ]; then
		log_error ${FUNCNAME[0]} "Error reading from ${TMP_PATH}/list_diff1.tmp."
		exit
	fi
# 					while read myline
# 					do
# 						echo $myline
# 						ICM_HOST='ftpmeteo.icm.edu.pl'
# 						USER='iopan'
# 						PASSWD='austrul'
# 						ftp -n $ICM_HOST <<END_SCRIPT
# 						quote USER $USER
# 						quote PASS $PASSWD
# 						binary
# 						cd um/
# 						get $myline ../storage/tmp/$myline
# END_SCRIPT
# 					done < tdb3_tmp.txt
}

# function download_archives {
# 	while read new_line; do
# 		if [[ ${new_line} = *"IOPAN1"* ]]; then
			
# 			cat ${TMP_PATH}"/list_diff1.tmp" | grep ${new_line/"IOPAN1"/"IOPAN4"}
# 		fi
# 	done <${TMP_PATH}"/list_diff1.tmp"
# }

function check_datasets {
	data_error=0
	while read new_line; do
		if [[ $new_line = *"IOPAN1"* ]]; then
			pattern=${new_line:(-14):8}
			err=$(ls ${TMP_DATA_PATH}/*"IOPAN1"*${pattern}* 2>/dev/null)
			if [ $? -ne 0 ]; then
				log_warning ${FUNCNAME[0]} "IOPAN1 archive missing for ${new_line}"
				data_error=1
			fi
			err=$(ls ${TMP_DATA_PATH}/*"IOPAN2"*${pattern}* 2>/dev/null)
			if [ $? -ne 0 ]; then
				log_warning ${FUNCNAME[0]} "IOPAN2 archive missing for ${new_line}"
				data_error=1
			fi
			err=$(ls ${TMP_DATA_PATH}/*"IOPAN3"*${pattern}* 2>/dev/null)
			if [ $? -ne 0 ]; then
				log_warning ${FUNCNAME[0]} "IOPAN3 archive missing for ${new_line}"
				data_error=1
			fi
		fi
	done <${ARCHIVES_LIST}
	if [ ${data_error} -ne 0 ]; then
		log_error ${FUNCNAME[0]} "Archives incomplete"
		exit
	fi
}

function extract_data {
	while read new_line; do
		log_info ${FUNCNAME[0]} "Extracting ${new_line}"
		tar -xjf ${new_line} -C ${TMP_DATA_PATH}/
		if [ $? -ne 0 ]; then
			log_error ${FUNCNAME[0]} "Error extracting data from ${new_line}"
			exit
		fi
		echo ${new_line:(-21)} >> ${USED_ICM_ARCHIVES}
		rm ${new_line}
	done <${ARCHIVES_LIST}
	for parameter in "${USED_PARAMS[@]}"; do
		for file_name in ${TMP_DATA_PATH}/*${parameter}*; do
			ls ${file_name} >> ${ICM_FILES_QUEUE}
			mv ${file_name} ${ICM_DATA_PATH}"/"
		done
	done
	sort -u ${USED_ICM_ARCHIVES} > ${TMP_PATH}"/sorted.tmp"
	mv ${TMP_PATH}"/sorted.tmp" ${USED_ICM_ARCHIVES}
	sort -u ${ICM_FILES_QUEUE} > ${TMP_PATH}"/sorted.tmp"
	mv ${TMP_PATH}"/sorted.tmp" ${ICM_FILES_QUEUE}
	rm ${TMP_DATA_PATH}/*"0000000"
}

function update_status {
	progress_status=$1
	echo ${progress_status} > ${PROGRESS_FILE}
}

# ----------------------------------------------------------------
# ------------------------------MAIN------------------------------
# ----------------------------------------------------------------
function main {
	read progress_status <${PROGRESS_FILE}
	get_current_time
	get_update_time
	set_download_hour
	log_init_message

	if [ "${progress_status}" = "START" ]; then
		get_icm_data_list
		format_icm_list
		get_download_list
		download_archives
		check_datasets
		update_status "DOWNLOADED"
	fi
	if [ "${progress_status}" = "DOWNLOADED" ]; then
		extract_data
		update_status "START"
	fi
	log_info ${FUNCNAME[0]} "DONE"
exit
}

main