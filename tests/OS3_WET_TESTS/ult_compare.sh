#!/bin/bash
#
####################################################################################################
# C Shai Yehezkel
#
# Script      :  ult_compare.sh
# Version     :  3
# Arguements  :  prog1,prog2,test_start_num [3]
# Description :  Compares two programs with given test in the directory this script is executed.
#
# NOTE this version is for OS Wet assignment 3
#
####################################################################################################

#Check arguements existence
TEST_START="*"
if [ -z "$1" ]; then
    echo "$1 doesn't exist!"
    exit -1
fi
if [ -z "$2" ]; then
    echo "Running on single file $1"
fi

echo $3
if [ $# -ge 3 ] ; then
    echo "Performing test N $3"
	TEST_START=$3
fi

#Variables defenitions
LOG_NAME="ult_compare.log"
SEARCH_WORD="bytes allocated"
VALGRIND_LOG="valgrind.log"
VALGRIND="valgrind --log-file=$VALGRIND_LOG --error-exitcode=1 --leak-check=yes --track-origins=yes "
SERVER_FILES="./server_test${TEST_START}.in"
DISPATCH_DELTA_T=1.5
ARRIVAL_ERROR=1.0
prog1_mem_favor=0
prog2_mem_favor=0
  base_prog_1=`basename $1`
  base_prog_2=`basename $2`

touch $VALGRIND_LOG	#In order to suppress output of VALGRIND. Will be deleted
rm $LOG_NAME 2>/dev/null #Initialze log

process_num=`ps | grep ${base_prog_1} | awk '{print $1}'`
if [ "$process_num" != "" ]; then
		kill -15 $process_num
		wait $process_num 2>/dev/null
		sleep 1
fi

process_num=`ps | grep ${base_prog_2} | awk '{print $1}'`
if [ "$process_num" != "" ]; then
		kill -15 $process_num
		wait $process_num 2>/dev/null
		sleep 1
fi


readarray -d '' entries < <(printf '%s\0' $SERVER_FILES | sort -zV)
for f in "${entries[@]}" # Loop over all test files
do
  echo "Processing $f file..."
  test_num=`(echo ${f} | cut -d'.' -f 2 | cut -d't' -f 3)`
  client_test="client_test${test_num}.in"
  log_prog_1=`basename $1_test$test_num.out`
  log_prog_2=`basename $2_test$test_num.out`
  cmd_line_args=$(head -n 1 $f)
  alg=`echo "${cmd_line_args}" | awk '{print $4}'`
  port=`echo "${cmd_line_args}" | awk '{print $1}'`
  echo "Running ${1}"
  fuser -k $port/tcp
  $1 $cmd_line_args & &>server_$log_prog_1
		num=1
		echo "" > client_$log_prog_1
		while IFS= read -r line; do
			echo "Line N.${num} executing ${line}" >> client_$log_prog_1
			echo >> client_$log_prog_1		
			cmd=`echo ${line}| tr -d $'&'`	
			if [ "$cmd" != "$line" ]; then
				${cmd} &>> client_$log_prog_1  &
			else
				${cmd} &>> client_$log_prog_1			
			fi	

			num=$((num+1))
		done < $client_test
	process_num=`ps | grep ${base_prog_1} | awk '{print $1}'`
	kill -15 $process_num
	wait $process_num
	fuser -k $port/tcp
	sleep 1
	if [ ! -z "$2" ]; then
		echo "Running ${2}"
		fuser -k $port/tcp
		$2 $cmd_line_args & &>server_$log_prog_2
		# Both servers run here
		num=1		
		echo "" > client_$log_prog_2
		while IFS= read -r line; do
			echo "Line N.${num} executing ${line}" >> client_$log_prog_2
			echo >> client_$log_prog_2		
			cmd=`echo ${line}| tr -d $'&'`	
			if [ "$cmd" != "$line" ]; then
				${cmd} &>> client_$log_prog_2  &
			else
				${cmd} &>> client_$log_prog_2			
			fi			
    		
			num=$((num+1))
		done < $client_test

		process_num=`ps | grep ${base_prog_2} | awk '{print $1}'`
		kill -15 $process_num
		wait $process_num
		fuser -k $port/tcp
		sleep 1
		grep -E "Line N.|Stat-Req-Arrival|Stat-Req-Dispatch|Stat-Thread-Id|Stat-Thread-Count|Stat-Thread-Static|Stat-Thread-Dynamic" client_${log_prog_1} > client_var_${log_prog_1}
		grep -E "Line N.|Stat-Req-Arrival|Stat-Req-Dispatch|Stat-Thread-Id|Stat-Thread-Count|Stat-Thread-Static|Stat-Thread-Dynamic" client_${log_prog_2} > client_var_${log_prog_2}
		grep -v -E "Stat-Req-Arrival|Stat-Req-Dispatch|Stat-Thread-Id|Stat-Thread-Count|Stat-Thread-Static|Stat-Thread-Dynamic|Rio_readlineb error:" client_${log_prog_1} > client_const_${log_prog_1}
		grep -v -E "Stat-Req-Arrival|Stat-Req-Dispatch|Stat-Thread-Id|Stat-Thread-Count|Stat-Thread-Static|Stat-Thread-Dynamic|Rio_readlineb error:" client_${log_prog_2} > client_const_${log_prog_2}
		
		DIFF=""
		DIFF_CLIENT=`diff client_const_${log_prog_1} client_const_${log_prog_2}`
		DIFF_SERVER=`diff server_${log_prog_1} server_${log_prog_2}`
		if [ "$DIFF_CLIENT" != "" ] || [ "$DIFF_SERVER" != "" ]; then		
			echo "Difference in client_const log or in server log"
			DIFF="diff"
		else
			#Compare variable content
			if [ `wc -l < client_var_${log_prog_1}` != `wc -l < client_var_${log_prog_2}` ]; then			
				echo "Line count mismatch!"
				DIFF="diff"
			else
				DELTA_T=0
				
				while read compareFile1 <&3 && read compareFile2 <&4; do     
					Val2=`echo "${compareFile2}" | cut -d" " -f3`
					Val1=`echo "${compareFile1}" | cut -d" " -f3`

					Header2=`echo "${compareFile2}" | cut -d" " -f2`
					Header1=`echo "${compareFile1}" | cut -d" " -f2`
					if  [ "${Header1}" != "${Header2}" ]; then
						echo "Headers mismatch! $Header1 VS $Header2"
						DIFF="diff"
						break
					fi
					if [ "$test_num" == "0" ]; then
						if [ "$Header1" == "Stat-Thread-Count::" ] || [ "$Header1" == "Stat-Thread-Static::" ] || [ "$Header1" == "Stat-Thread-Dynamic::" ] ; then
							if [ "$compareFile1" != "$compareFile2" ]; then
								echo "Counts mismatch!"
								DIFF="diff"
								break;
							fi
						fi			
					fi
					if  [ "$Header1" == "Stat-Req-Arrival::" ] || [ "$Header1" == "Stat-Req-Dispatch::" ] ; then
						if [[ ${#Val1} -ge 19 ]] || [[ ${#Val2} -ge 19 ]]; then
							echo "Timestamp is too long!"
							echo "${Val1} VS ${Val2}"
							DIFF="diff"
							break
						fi
					fi
					if [ "$Header1" == "Stat-Req-Arrival::" ] && [ "$alg" != "random" ] && [ "$alg" != "block" ] ; then
						if (( $(echo "$DELTA_T == 0" |bc -l) )); then					
							DELTA_T=$(echo "$Val2-$Val1" | tr -d $'\r' | bc | awk '{printf "%f", $0}')
						fi
						TIME_DIFF=$(echo "$Val2-$Val1" | tr -d $'\r' | bc | awk '{printf "%f", $0}')
						ERROR=`bc -l <<< "$TIME_DIFF/$DELTA_T"`
						if (( $(echo "$ERROR > 1" |bc -l) )); then
							ERROR=$(echo "$ERROR-1" | tr -d $'\r' | bc | awk '{printf "%f", $0}')
						else
							ERROR=$(echo "1-$ERROR" | tr -d $'\r' | bc | awk '{printf "%f", $0}')
						fi
						if (( $(echo "$ERROR > $ARRIVAL_ERROR" |bc -l) )); then						
							echo "Difference in Stat-Req-Arrival:: error is more than ${ARRIVAL_ERROR} percent"
							echo "$compareFile1 VS $compareFile2"
							DIFF="diff"
							break
						fi
						DELTA_T=$TIME_DIFF
					elif [ "$Header1"  == "Stat-Req-Dispatch::" ] && [ "$alg" != "random" ] && [ "$alg" != "block" ] ; then
						TIME_DIFF=$(echo "$Val2-$Val1" | tr -d $'\r' | bc | awk '{printf "%f", $0}')
						if (( $(echo "$TIME_DIFF < 0" |bc -l) )); then		
							TIME_DIFF=$(echo "$Val1-$Val2" | tr -d $'\r' | bc | awk '{printf "%f", $0}')
						fi
						if (( $(echo "$TIME_DIFF >= $DISPATCH_DELTA_T" |bc -l) )); then												
							echo "Difference in Stat-req-dispath:: more than ${DISPATCH_DELTA_T} seconds"
							echo "$compareFile1 VS $compareFile2"
							DIFF="diff"
							break
						fi

					fi
										
				done 3<client_var_${log_prog_1} 4<client_var_${log_prog_2}
			fi
		fi
		if [ "$DIFF" != "" ]; then
			    echo "Test $test_num : Different outputs! see $LOG_NAME"
			    echo "Test $test_num : Different outputs!" >> $LOG_NAME
				read -p "Press enter to continue"
			    #read varname
		
		else
			
				rm client_$log_prog_1
				rm client_$log_prog_2
				rm client_var_$log_prog_1
				rm client_var_$log_prog_2
				rm client_const_$log_prog_1
				rm client_const_$log_prog_2
				rm server_$log_prog_1
				rm server_$log_prog_2
		fi
	fi
	if [ -z "$2" ]; then
		rm $log_prog_1
	fi
done

if [ -f "$LOG_NAME" ]; then
	echo ""
    echo "Errors starts here!"
    echo ""
    cat $LOG_NAME	
    echo ""
    echo "Errors ends here!"
    exit -2
fi

exit 0
