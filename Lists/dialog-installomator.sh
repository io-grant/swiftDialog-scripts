#!/bin/bash

# bash script that will take a list of installomator labels and run through each
# displays's a dialog with the list of applications and their progress
#
# Requires Dialog v1.9.1 or later https://github.com/bartreardon/Dialog/releases
#
# ©2022 Bart Reardon

# List of Installomator labels to process
labels=(
    "googlechrome"
    "audacity"
    "firefox"
    "inkscape"
)


# -------------------------------------

# *** script variables

# location of dialog and installomator scripts
dialogApp="/usr/local/bin/dialog"
dialog_command_file="/var/tmp/dialog.log"
installomator="/usr/local/Installomator/Installomator.sh"


# check we are running as root
if [[ $(id -u) -ne 0 ]]; then
	echo "This script should be run as root"
	exit 1
fi

# check Installomator exists and the specified path
if [[ ! -e $installomator ]]; then
	echo "Installomator not found at path $installomator"
	exit 1
fi

# *** functions

# take an installomator label and output the full app name
function label_to_name(){
	#name=$(grep -A2 "${1})" "$installomator" | grep "name=" | head -1 | cut -d '"' -f2) # pre Installomator 9.0
	name=$(${installomator} ${1} RETURN_LABEL_NAME=1 LOGGING=REQ | tail -1)
	if [[ "$name" != "#" ]]; then
		echo $name
	else
		echo $1
	fi
}

# execute a dialog command
function dialog_command(){
	echo $1
	echo $1  >> $dialog_command_file
}

function finalise(){
	dialog_command "progresstext: Install of Applications complete"
	dialog_command "progress: complete"
	dialog_command "button1text: Done"
	dialog_command "button1: enable" 
	exit 0
}

# work out the number of increment steps based on the number of items
# and the average # of steps per item (rounded up to the nearest 10)

output_steps_per_app=30
number_of_apps=${#labels[@]}
progress_total=$(( $output_steps_per_app \* $number_of_apps ))


# initial dialog starting arguments
title="Installing Applications"
message="Please wait while we download and install the following applications:"

# set icon based on whether computer is a desktop or laptop
if system_profiler SPPowerDataType | grep -q "Battery Power"; then
	icon="SF=laptopcomputer.and.arrow.down,weight=thin,colour1=#51a3ef,colour2=#5154ef"
	else
	icon="SF=desktopcomputer.and.arrow.down,weight=thin,colour1=#51a3ef,colour2=#5154ef"
fi

dialogCMD="$dialogApp -p --title \"$title\" \
--message \"$message\" \
--icon \"$icon\"
--progress $progress_total \
--button1text \"Please Wait\" \
--button1disabled"

# create the list of labels
listitems=""
for label in "${labels[@]}"; do
	#echo "apps label is $label"
	appname=$(label_to_name $label)
	listitems="$listitems --listitem ${appname} "
done

# final command to execute
dialogCMD="$dialogCMD $listitems"

echo $dialogCMD
# Launch dialog and run it in the background sleep for a second to let thing initialise
eval $dialogCMD &
sleep 2


# now start executing installomator labels

progress_index=0

for label in "${labels[@]}"; do
	step_progress=$(( $output_steps_per_app * $progress_index ))
	dialog_command "progress: $step_progress"
	appname=$(label_to_name $label | tr -d "\"")
	dialog_command "listitem: $appname: wait"
	dialog_command "progresstext: Installing $label" 
	installomator_error=0
	installomator_error_message=""
	while IFS= read -r line; do
		case $line in
			*"DEBUG"*)
			;;
			*"BLOCKING_PROCESS_ACTION"*)
			;;		
			*"NOTIFY"*)
			;;		
			*"LOGO"*)
				logofile=$(echo $line | awk -F "=" '{print $NF}')
  				dialog_command "icon: $logofile"
			;;
			*"ERROR"*)
			    installomator_error=1
			    installomator_error_message=$(echo $line | awk -F "ERROR: " '{print $NF}')
			;;
			*"##################"*)	
			;;
			*)
				# Installomator v8
				#progress_text=$(echo $line | awk '{for(i=4;i<=NF;i++){printf "%s ", $i}; printf "\n"}')
				
				# Installomator v9
				progress_text=$(echo $line | awk -F " : " '{print $NF}')
				
				if [[ ! -z  $progress_text ]]; then
					dialog_command "progresstext: $progress_text"
					dialog_command "progress: increment"
				fi
			;;
		esac
	
	done < <($installomator $label)
	
	if [[ $installomator_error -eq 1 ]]; then
		dialog_command "progresstext: Install Failed for $appname"
		dialog_command "listitem: $appname: error"
	else
		dialog_command "progresstext: Install of $appname complete"
		dialog_command "listitem: $appname: success"
	fi
	progress_index=$(( $progress_index + 1 ))
	echo "at item number $progress_index"
	
done


# all done. close off processing and enable the "Done" button
finalise
		
		
