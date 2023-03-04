#!/bin/bash
outputString="" #String that will display the output
clock=0         #Time count
queue=()        #This array acts like a queue that will keep track of all the running/waiting prrocesses
isPresent=0     #Bool variable used to check if the Process is present in the queue
needToAdd=0     #Bool VAriable used to support the logic for TQ > 1
putAtTheBack=0  #Bool variable used to check if the Process needs to be put at the back of the queue
#///*********************************** DEFINING FUNCTIONS HERE *******************************************///#
#This functions checks if the passed parameter exists in the Process queue or not
function isPresentInQueue() {
    size=${#queue[@]}
    if [ $size -eq 0 ]; then
        isPresent=0
        needtoAdd=0
    else
        for ((j = 0; j < "$size"; j++)); do
            isPresent=0
            needToAdd=0
            if [ "${queue[$j]}" == $1 ]; then
                isPresent=1
                needToAdd=1
                break
                19
            fi
        done
    fi
}
#This function checks if some process need to be added to the queue. Only call it when TQ > 1
function addInQueue() {
    for ((y = 0; y < "${#processName[*]}"; y++)); do
        needToAdd=0
        #check if the process is already in queue. If not in queue, put it in the queue
        isPresentInQueue "${processName[$y]}"
        if [ "$needToAdd" -eq 0 ] && [ "${burstTime[$y]}" -ne 0 ]; then
            if [ "${arrivalTime[$y]}" -lt "$1" ] || [ "${arrivalTime[$y]}" -eq "$1" ]; then
                queue+=("${processName[$y]}")
            fi
        fi
    done
}
#///******************************************************************************************************///#
# Check for valid number of Positional parameters
if [ $# -gt 3 ] || [ $# -lt 2 ]; then
    echo "Please provide two or three parameter."
    exit 1
fi
# If the file (in which we need to display the output) exists, delete it
if [ -f "$2" ]; then
    $(rm $2)
fi
#If there is a third Positional Parameter, it is a value of Time Quantum (TQ)
if [ $# -eq 3 ]; then
    TQ=$3
else
    TQ=1
fi
#Check if the Positional Parameter is a valid/regular file
if
    [ -f $1 ]
    20
then
    #Read from the file and populate the arrays
    while read -r line; do
        tempArr=($line)
        processName+=("${tempArr[0]}")
        arrivalTime+=("${tempArr[1]}")
        burstTime+=("${tempArr[2]}")
    done <"$1"
    #Count the No. of Processes
    jobs=${#processName[@]}
    #Create a string that will be compared to the output string to break the loop
    breakLoop=""
    for ((a = 0; a < $jobs; a++)); do
        breakLoop="$breakLoop F"
    done
    #Displaying the header on the standard output and send it to the output file
    echo " T ${processName[*]}"
    echo " T ${processName[*]}" >>$2
    #This loop should run continuously until all jobs are terminated
    while [ true ]; do
        outputString="" #Output string should be empty at the start of every iteration
        putAtTheBack=0  #This is a Bool variable to check if we need to put the Running process at the back or not
        tempTime=1      #This variable stores the amount of time units that needs to be added to the clock in case of TQ > 1
        #Shift the first element of the queue and update the Running process
        queue=("${queue[@]:1}")
        running="${queue[0]}"
        #If the size of queue is greater than 0
        if [ "${#queue[@]}" -gt 0 ]; then
            outputString="$outputString $clock"
            for ((i = 0; i < $jobs; i++)); do
                #Calling a function to check if the Process is already present in the queue
                isPresentInQueue "${processName[$i]}"
                #If the process was not found in the queue
                if [ "$isPresent" -eq 0 ]; then
                    if
                        [ "${arrivalTime[$i]}" -eq "$clock" ] || [ "${arrivalTime[$i]}" -lt "$clock" ]
                        21
                    then
                        if [ "${processName[$i]}" != "$running" ] && [ "${burstTime[$i]}" -gt 0 ]; then
                            outputString="$outputString W"
                            temp="${processName[$i]}"
                            queue+=($temp)
                        elif [ "${processName[$i]}" != "$running" ] && [ "${burstTime[$i]}" -eq 0 ]; then
                            outputString="$outputString F"
                        fi
                    elif [ "${arrivalTime[$i]}" -gt "$clock" ] && [ "${burstTime[$i]}" -gt 0 ]; then
                        outputString="$outputString -"
                    fi
                #If the process was found in the queue
                elif [ "$isPresent" -eq 1 ]; then
                    if [ "${processName[$i]}" == "$running" ] && [ "${burstTime[$i]}" -gt 0 ]; then
                        outputString="$outputString R"
                        bt1="${burstTime[$i]}"
                        #Decrimenting Burst time by the TQ value or BT value (it depends on the BT value)
                        if [ $bt1 -gt $TQ ]; then
                            tempTime=$TQ
                        elif [ $bt1 -lt $TQ ] || [ $bt1 -eq $TQ ]; then
                            tempTime=$bt1
                        fi
                        burstTime[$i]=$(($bt1 - $tempTime))
                        #If the burst time of this process is greater then 0, push it to the queue after iterating all the processes
                        if [ "${burstTime[$i]}" -gt 0 ]; then
                            putAtTheBack=1
                            backOfQueue1="${processName[$i]}"
                        fi
                    elif [ "${processName[$i]}" != "$running" ] && [ "${burstTime[$i]}" -gt 0 ]; then
                        outputString="$outputString W"
                    elif [ "${processName[$i]}" == "$running" ] && [ "${burstTime[$i]}" -eq 0 ]; then
                        outputString="$outputString F"
                    fi
                fi
            done
            22
            #If TQ > 0, Look for other processes that needs to be added at the back of the queue (This is an importent step)
            if [ $TQ -gt 1 ]; then
                timeNow1=$(($clock + $tempTime))
                addInQueue $timeNow1
            fi
            #Put the running process at the end of the queue if its Burst time is not zero
            if [ "$putAtTheBack" -eq 1 ]; then
                queue+=($backOfQueue1)
            fi
        #If the queue is empty - Check the arrival time of the processes
        else
            outputString="$outputString $clock"
            for ((k = 0; k < $jobs; k++)); do
                if [ "${arrivalTime[$k]}" -eq "$clock" ] && [ -z "$running" ] && [ "${burstTime[$k]}" -gt 0 ]; then
                    queue+=("${processName[$k]}")
                    running="${processName[$k]}"
                    bt="${burstTime[$k]}"
                    #Decrimenting the TQ value by TQ or BT (depends on the value of BT)
                    if [ $bt -gt $TQ ]; then
                        tempTime=$TQ
                    elif [ $bt -lt $TQ ] || [ $bt -eq $TQ ]; then
                        tempTime=$bt
                    fi
                    burstTime[$k]=$(($bt - $tempTime))
                    #If burst time is greater than 0, push it to the quque after iterating all the processes
                    if [ "${burstTime[$k]}" -gt 0 ]; then
                        backOfQueue2="${processName[$k]}"
                    fi
                    outputString="$outputString R"
                elif [ "${arrivalTime[$k]}" -eq "$clock" ] || [ "${arrivalTime[$k]}" -lt "$clock" ]; then
                    if [ ! -z "$running" ] && [ "${burstTime[$k]}" -gt 0 ]; then
                        queue+=("${processName[$k]}")
                        outputString="$outputString W"
                    elif
                        [ "${burstTime[$k]}" -eq 0 ]
                        23
                    then
                        outputString="$outputString F"
                    fi
                elif [ "${arrivalTime[$k]}" -gt "$clock" ]; then
                    outputString="$outputString -"
                fi
            done
            #If TQ > 1, Look for other processes that needs to be added at the back of the queue
            if [ $TQ -gt 1 ]; then
                timeNow2=$(($clock + $tempTime))
                addInQueue $timeNow2
            fi
            #Put the running process at the back of the queue
            queue+=($backOfQueue2)
        fi
        #update Clock
        clock=$(("$clock" + "$tempTime"))
        #Display the Process Status on Screen and a seperate file provided
        echo "$outputString"
        echo "$outputString" >>$2
        #Prepare a string that will be compared to break out of the loop
        if [ "$clock" -gt 10 ]; then
            tempString=$(echo "$outputString" | cut -c 4-)
        else
            tempString=$(echo "$outputString" | cut -c 3-)
        fi
        if [ "$tempString" == "$breakLoop" ]; then
            break
        fi
    done
else
    echo "Positional parameter must be a valid file. Please provide a valid file."
    exit 1
fi
exit
