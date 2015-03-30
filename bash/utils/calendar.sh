#!/bin/bash
ScriptLoc="$(dirname $0)/lib"
source ${ScriptLoc}/lib_colors.sh
source ${ScriptLoc}/lib_os.sh

cBackground=${On_Black}
cForeground=${White}
cDimmest=${Black}
cDimmer=${Yellow}
cCurrent=${Green}
cHighlight=${BYellow}${cBackground}
cHeader=${BYellow}

function trim() {
	local var=$@
	var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
	var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
	echo -n "$var"
}

function CheckDistro() {
	local retval="cal"
	local Distro="$(whichOS)"
	case "${Distro}" in
		*buntu* | *Mint* | *ingu* | *etrunne* | *lementar* )
			retval="cal -h"
		;;
                *edora* | *Cent* | *Hat* | *oror* | *udunt* | *cientifi* )
			retval="cal --color=never"
                ;;
		*Arch* | *anjar* | *ntergo* )
			retval="cal --color=never"
		;;
	esac
	printf "${retval}"
}

#Checks our distro cuz Ubuntu and Arch use different vers of cal
#   with different options to disable highlight of current date
calcmd="$(CheckDistro)"

#Set our Variables
WEEK="${BWhite}${cBackground}Su Mo Tu We Th Fr Sa${Color_Off}\n"
PAST=$(trim "$(cal $(date --date='2 months ago' '+%m %Y') | tail -2 | head -1 )")
PREV=$(trim "$(cal $(date --date='1 month ago' '+%m %Y') | tail -n +3 | head -n -2 )")
CURR=$(trim "$(${calcmd} $(date '+%m %Y') | tail -n6 | head -n -1)")
NEXT=$(trim "$(cal $(date --date='next month' '+%m %Y') | tail -n +3 | head -n -1 )")
FUTR=$(trim "$(cal $(date --date='+2 months' '+%m %Y') | grep -v "[A-Za-z]" | head -n 1)")

#Adjust each depending on how long the "last" week is
#("last" is relative since PAST and FUTR are partials)
#Otherwise, when a month that ends on Sat, the next would start on the same line
#A week should be 20 chars (2 chars per day [14], plus the spaces between [6])
#Except for the FUTR partial, which has a single digit in column 1
#Either adds space(s) and/or NewLine around each month
blah=${PAST##*$'\n'}
if (( ${#blah} >= 19 )); then
	PAST=""
else
	PAST="${PAST} "
fi

blah=${PREV##*$'\n'}
if (( ${#blah} == 20 )); then
	PREV=" ${PREV}\n"
else
	PREV=" ${PREV} "
fi

blah=${CURR##*$'\n'}
if (( ${#blah} == 20 )); then
	CURR=" ${CURR}\n"
else
	CURR=" ${CURR} "
fi

blah=${NEXT##*$'\n'}
if (( ${#blah} == 20 )); then
	NEXT=" ${NEXT}\n"
else
	NEXT=" ${NEXT} "
fi

blah=${FUTR##*$'\n'}
if (( ${#blah} >= 19 )); then
	FUTR=""
else
	FUTR=" ${FUTR}\n"
fi

#Hightlight the current date
#Seems to work for everything...
#...except if the 1st is on Saturday. Giving up.
FText=$(date +%e)
RText=$(printf "${cHighlight}")${FText}$(printf "${Color_Off}${cForeground}")
CURR=$(echo "${CURR}" | sed -e "s/ ${FText} / ${RText} /" -e "s/ ${FText}$/ ${RText}/" -e "s/^${FText}/${RText} /")

unset blah FText RText

#Display the Current Date
printf "${cHeader}"
TodayIs=$(date +"%a, %b. %e" | sed -re 's/([^1]1)$/\1st/' -e 's/([^1]2)$/\1nd/' -e 's/([^1]3)$/\1rd/' -e 's/([0-9])$/\1th/' -e 's/  / /g')
printf "%"$((( 20 - ${#TodayIs} ) / 2 ))"s${TodayIs}\n"

#Display the "week day" header
printf "${WEEK}"

#Display the calendars
printf "${cDimmest}${PAST}${Color_Off}"
printf "${cDimmer}${PREV}${Color_Off}"
printf "${cCurrent}${CURR}${Color_Off}" 
printf "${cDimmer}${NEXT}${Color_Off}"
printf "${cDimmest}${FUTR}${Color_Off}"

#Display the "week day" footer
printf "${WEEK}"
