#!/bin/bash

requiredOSVer="Ventura 13.3.1"
ithelplink="https://itanswers.tesla.com"
infolink="https://support.apple.com/en-au/HT201222"
# set this to 1 and the popup will persist until the update is performed
persistant=0

OSVer=$(sw_vers | grep "ProductVersion" | awk '{print $NF}')
dialog="/usr/local/bin/dialog"


title="Important Software Update Available"
titlefont="colour=yellow"
message="### You are currently running macOS version ${OSVer} 

It is important that you update to **macOS ${requiredOSVer}** at your earliest convenience

macOS ${requiredOSVer} contains important security updates and bug fixes that have had large impact

****"
infotext="More Information"

icon=SF=applelogo,colour=orange,colour2=blue

overlay="caution"
button1text="Open Software Update"
button1action="open -b com.apple.systempreferences /System/Library/PreferencePanes/SoftwareUpdate.prefPane"
button2text="Contact IT Answers"
button2action=$ithelplink

# check the current version against the required version and exit if we're already at or exceded
autoload is-at-least
is-at-least $requiredOSVer $OSVer
if [[ $? -eq 0 ]]; then
	echo "You have v${OSVer}"
	exit 0
fi

runDialog () {
    ${dialog} -p -d \
    		--title "${title}" \
            --titlefont ${titlefont} \
            --overlayicon "${overlay}" \
            --icon "${icon}" \
            --message "${message}" \
            --blurscreen \
            --infobuttontext "${infotext}" \
            --infobuttonaction "${infolink}" \
            --button1text "${button1text}" \
            --button2text "${button2text}"
    
    processExitCode $?
}

updateselected=0

processExitCode () {
    exitcode=$1
    if [[ $exitcode == 0 ]]; then
        updateselected=1
        open -b com.apple.systempreferences /System/Library/PreferencePanes/SoftwareUpdate.prefPane
    elif [[ $exitcode == 2 ]]; then
        currentUser=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
        uid=$(id -u "$currentUser")
        launchctl asuser $uid open "${button2action}"
  	elif [[ $exitcode == 3 ]]; then
  		updateselected=1
    fi
}


# the main loop
while [[ ${persistant} -eq 1 ]] || [[ ${updateselected} -eq 0 ]]
do
    if [[ -e "${dialog}" ]]; then
        runDialog
    else
        # well something is up if dialog is missing - force an exit
        updateselected=1
    fi
done

exit 0