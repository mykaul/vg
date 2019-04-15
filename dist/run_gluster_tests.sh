#!/usr/bin/env bash

TEST_DIR=~/glusto-tests/tests/functional/glusterd
LOG_FILE=~/glusto_tests_summary.log
LOGS_DIR=~/glusto_tests_logs
GLUSTO_CFG=~/gluster_tests_config.yml
RETRIES=3 # Retry test again if failed
cd $TEST_DIR
touch $LOG_FILE
mkdir -p $LOGS_DIR
echo -e "\e[1mRUNNING TESTS\n-----------------\e[0m" >> $LOG_FILE
for test in $(find [A-Z][a-z]*.py);
do
	RUNS=1
	TEST_NAME="${test%.*}"
	TEST_LOG="$LOGS_DIR/$TEST_NAME.log"
	TEST_CMD="glusto -c $GLUSTO_CFG -l $TEST_LOG --log-level INFO  --pytest='-v -s -k $TEST_NAME'"
	eval $TEST_CMD
	TEST_SUCCESS=$(( $?==0 ? 1 : 0 )) # true if test succeeded, false if failed
        while [[ TEST_SUCCESS -ne 1 && $RUNS -lt $RETRIES ]]
	do
		echo -e "$TEST_NAME - \e[31mFAILURE\e[0m" >> $LOG_FILE
		sleep 60
		echo -e "\e[33m--- RETRYING TEST \e[39m$TEST_NAME\e[33m... ---\e[0m" >> $LOG_FILE
		eval $TEST_CMD
		TEST_SUCCESS=$(( $?==0 ? 1 : 0 ))
		((RUNS++))
	done
	if [ $TEST_SUCCESS -eq 1 ]; then
		echo -e "$TEST_NAME - \e[32mSUCCESS\e[0m" >> $LOG_FILE
        	rm -f $TEST_LOG
	else
          	echo -e "$TEST_NAME - \e[31mFAILURE\e[0m" >> $LOG_FILE
        fi
	sleep 30
done;
echo -e "\e[1m-----------------\nDONE TESTING!\e[0m" >> $LOG_FILE


