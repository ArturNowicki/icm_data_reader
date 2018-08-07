#!/bin/bash
# Created by Artur Nowicki on 05.08.2018.

HOME_PATH="/Users/arturnowicki/IOPAN/code/icm_data_reader"
CONFIG_PATH=${HOME_PATH}"/config"
APPDATA_PATH=${HOME_PATH}"/app_data"
TMP_PATH=${HOME_PATH}"/runtime_data"

ICM_DATA_PATH="/Users/arturnowicki/IOPAN/code/icm_data_reader/test_data/icm_data"
TMP_DATA_PATH="/Users/arturnowicki/IOPAN/code/icm_data_reader/test_data/tmp_data"

LOG_FILE=${APPDATA_PATH}"/logs.txt"
PROGRESS_FILE=${APPDATA_PATH}"/process_progress.info"
ICM_FILES_QUEUE=${APPDATA_PATH}"/icm_files.queue"

rm ${LOG_FILE} # to be removed

LOGGING_LEVEL="DEBUG"
daysim=(31 28 31 30 31 30 31 31 30 31 30 31)

USED_PARAMS=("03225" "03226" "03236" "03237" "03250" "03460" "03461" "09203" "09204" \
"09205" "09217" "16222" "04201" "04202" "05201" "05202" "01201" "01235" "02201" "02207")

source logging.sh

function update_status {
	progress_status=$1
	echo ${progress_status} > ${PROGRESS_FILE}
}

# ----------------------------------------------------------------
# ------------------------------MAIN------------------------------
# ----------------------------------------------------------------
function main {
	read progress_status <${PROGRESS_FILE}
	log_info ${FUNCNAME[0]} "Interpolating data"
}
