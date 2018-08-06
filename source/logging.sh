#!/bin/bash
# Created by Artur Nowicki on 02.08.2018.

case ${LOGGING_LEVEL} in
   INFO|DEBUG|'')
     echo "" ;;
   *)
     echo "LOGGING_LEVEL = ${LOGGING_LEVEL} is not a valid value!"; exit ;;
esac

if [ -z ${LOGGING_LEVEL+x} ]; then
	echo 'LOGGING TOOL: WARNING, LOGGING LEVEL NOT SET. SETTING TO INFO!'
	LOGGING_LEVEL="INFO"
fi
if [ -z ${LOG_FILE+x} ]; then
	echo "LOGGING TOOL: WARNING, LOG FILE IS NOT SET!"
fi
if [ ! -e ${LOG_FILE} ]; then
	touch ${LOG_FILE}
	if [ $? -ne 0 ]; then
		echo "LOGGING TOOL: ERROR, CANNOT CREATE/READ LOG FILE!"
		exit
	else
		echo "LOGGING TOOL: WARNING, CREATED NEW LOG FILE!"
	fi

fi

function log_error {
	echo `date`";" "level = ERROR;" "calling_program = $0;" "calling_function = $1;" "message = $2;" >> $LOG_FILE
	if [ "$LOGGING_LEVEL" = "DEBUG" ]; then
		echo `date`";" "level = ERROR;" "calling_program = $0;" "calling_function = $1;" "message = $2;"
	fi
}
function log_warning {
	echo `date`";" "level = WARNING;" "calling_program = $0;" "calling_function = $1;" "message = $2;" >> $LOG_FILE
	if [ "$LOGGING_LEVEL" = "DEBUG" ]; then
		echo `date`";" "level = WARNING;" "calling_program = $0;" "calling_function = $1;" "message = $2;"
	fi
}
function log_info {
	echo `date`";" "level = INFO;" "calling_program = $0;" "calling_function = $1;" "message = $2;" >> $LOG_FILE
	if [ "$LOGGING_LEVEL" = "DEBUG" ]; then
		echo `date`";" "level = INFO;" "calling_program = $0;" "calling_function = $1;" "message = $2;"
	fi
}
function log_debug {
	echo `date`";" "level = DEBUG;" "calling_program = $0;" "calling_function = $1;" "message = $2;" >> $LOG_FILE
	if [ "$LOGGING_LEVEL" = "DEBUG" ]; then
		echo `date`";" "level = DEBUG;" "calling_program = $0;" "calling_function = $1;" "message = $2;"
	fi
}
