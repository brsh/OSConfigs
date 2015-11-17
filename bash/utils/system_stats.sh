#!/bin/bash
ScriptLoc="$(dirname "${0}")"
source "${ScriptLoc}/lib/lib_colors.sh"
source "${ScriptLoc}/lib/lib_time.sh"

#function out-Heading {
#	#Makes a pretty (and consistent) heading
#	printf "${Heading}"
#	printf "${*}"
#	printf "%0.s " {1..100}
#	printf "${Color_Off}\n"
#}

function get-net {
#CLI 1
#very convoluted (but fact-filled) network info
local retval
local ipaddr
local masktemp
local netcalc
local defgateway
local SSID
local DHCPServer
local DHCPLeaseExpire=""
local DNSServer
local ConType
local MACAddr
local WiFiDeets=""
local ifconfig=""
local ipconfig=""
local AllInfo=""

for INTs in $(ip link | awk ' BEGIN { FS=":" } /^[0-9]/ {printf "%s ", $2}'); do
	if [ "${INTs:0:3}" = "eth" ]; then
		retval=""
		ipaddr=""
		masktemp=""
		netcalc=""
		defgateway=""
		SSID=""
		DHCPServer=""
		DHCPLeaseExpires=""
		DNSServer=""
		ConType=""
		MACAddr=""
		WifiDeets=""
		ifconfig=""
		ipconfig=""

		ifconfig="$(ip addr show dev "${INTs}")"
		ipaddr=$(echo "${ifconfig}" | awk '/inet / {print $2 }')

#		masktemp=$(echo "${ifconfig}" | awk '/inet[[:space:]]/ {print $4 }')
#		if [ ${#masktemp} -eq 10 ]; then
#			netcalc="$((0x${masktemp:2:2} / 0x1)).$((0x${masktemp:4:2} / 0x1)).$((0x${masktemp:6:2} / 0x1)).$((0x${masktemp:8:2} / 0x1))"
#		else
#			netcalc="n/a"
#		fi

		MACAddr=$(echo "${ifconfig}" | awk '/ether / {print $2 }')

		defgateway=$(ip route show | awk ' /^default/ {print $3}')

#		ConType=$(networksetup -listallhardwareports | grep -B1 ${INTs} | awk -F:  ' /Port/ { sub("Hardware Port: ",""); print }')
#		if [ "${ConType}" = "Wi-Fi" ]; then
#			SSID=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport -I | awk ' / SSID:/ { print $2 }')
#			if ! [[ "${SSID}" && "${SSID-x}" ]]; then
#				SSID="n/a"
#			else
#				#System_Profiler is ... slow (it's an inventory)
#				#Disabling this 'else' call will speed things up a little
#				#(and it won't break the display of info below)
#				WiFiDeets=" - $(system_profiler SPAirPortDataType | grep -A10 "Current Network Information" | awk ' /PHY Mode:/ { print $3 }')"
#			fi
#		fi

		ipconfig=$(dhcpcd -U "${INTs}" 2> /dev/null )
		DHCPServer=$(echo "${ipconfig}" | awk ' BEGIN { FS="[=:]" }; /server_identifier/ {$1=""; gsub(" ","",$0); print $0 }')
		if ! [[ "${DHCPServer}" && "${DHCPServer-x}" ]]; then
			DHCPServer="Static IP, no DHCPServer, or other error"
# 		else
# 			#Have to review DHCP lease time
# 			#ipconfig doesn't actually show when the lease was granted (so this calc is wrong)
# 			#btw - /private/var/db/dhcpclient/leases/ holds 
# 			#plus t1 = when it will try to renew with existing dhcpserver
# 			#and  t2 = when it will try to renew with any dhcpserver
# 			DHCPLeaseExpires=$(date -r $(echo $(date +%s) + $(( $(echo "${ipconfig}" | awk '/rebinding_t2_time_value[[:space:]]/ { $1=$2=""; print }') / 0x1 )) | bc) +'%a %m/%d/%Y %_I:%M%p')
# 			DHCPLeaseExpires="(${Item}Lease Expires:${Text} ${DHCPLeaseExpires})${ColorOff}"
		fi

		DNSServer="$(awk ' /^nameserver/ { printf "%s  ", $2 }' /etc/resolv.conf)"

		if [[ "${ipaddr}" && "${ipaddr-x}" ]]; then
			AllInfo="${AllInfo} ${SubHead}Interface ${INTs}${Color_Off}\n"
			AllInfo="${AllInfo}   ${Item}IP Address:${Color_Off}\t${Text}${ipaddr} ${netcalc}${Color_Off}\n"
			AllInfo="${AllInfo}   ${Item}MAC Address:${Color_Off}\t${Text}${MACAddr}${Color_Off}\n"
			AllInfo="${AllInfo}   ${Item}DHCP Server:${Color_Off}\t${Text}${DHCPServer}${ColorOff} ${DHCPLeaseExpires}${ColorOff}\n"
			AllInfo="${AllInfo}   ${Item}Def Gateway:${Color_Off}\t${Text}${defgateway}${Color_Off}\n"
			AllInfo="${AllInfo}   ${Item}DNS Servers:${Color_Off}\t${Text}${DNSServer}${Color_Off}\n"
#			if [ "${ConType}" = "Wi-Fi" ]; then
#				AllInfo="${AllInfo}   ${Item}WiFi SSID:${Color_Off}\t${Text}${SSID}${WiFiDeets}${Color_Off}\n"
#			fi
			AllInfo="${AllInfo}\n"
		fi
	retval=""
	fi
done

if [[ "${AllInfo}" && "${AllInfo-x}" ]]; then
	out-Heading "Network Information"
	printf "${AllInfo}"
fi

}

function get-disk {
	#CLI 3
	#the usual disk space info
	out-Heading "Disk Information"
	printf "${SubHead}"
	echo "FileSystem Type Size Used Avail Used Mounted On" | awk '{printf "  %-20s %6s %6s %5s  %-9s %s %s\n", $1,$3,$5,$6,$2,$7,$8 }'
	printf "${Text}"
	df -hT -x tmpfs -x devtmpfs -l | awk 'NR>1 {printf "  %-20s %6s %6s %5s  %-9s %s %s\n", $1,$3,$5,$6,$2,$7,$8 }'
	printf "${Color_Off}"
	printf "\n"
}

function get-users {
	#CLI 6
	#prints who's logged on to the machine, their tty, and when
	out-Heading "Active User Summary"
	printf "${SubHead}"
	echo 'UserName~Terminal~Logged In' | awk ' BEGIN {FS="~"}; { printf "  %-16s %-15s %s\n", $1,$2,$3 }' 
	printf "${Text}"
	who | awk ' ! /^\(unknown\)/ { printf "  %-16s %-15s %-3s %2s %-5s\n", $1, $2, $3, $4, $5 }'
	printf "${Color_Off}"
	printf "\n"
}

#function get-screen {
	#CLI 4
	#lists the displays and their resolution
#	local retval=""
#	retval=$( system_profiler SPDisplaysDataType | awk ' /^        [a-zA-Z]/ { gsub("  ",""); printf "  '${Item}'%-17s'${Color_Off}'", $0 }; /  Resolution:/ { gsub("  ",""); if ($5=="Retina") x="Retina"; else x=""; printf "'${Text}'%6s%s%s %s'${Color_Off}'\n", $2,$3,$4,x}' )

#	out-Heading "Available Screens"
#	printf "${Text}${retval}\n"
#	printf "\n"
#}

function get-hardware {
	#CLI 1
	#pulls some info on the hardware and software
	local procval=""
	procval=$(awk ' BEGIN {FS=": "} /model name/ { gsub("Intel\\(R\\) ", ""); gsub("\\(TM\\)",""); gsub("CPU ",""); printf $2; exit }' /proc/cpuinfo )
	local socCorThr=$(lscpu | awk ' BEGIN {FS=":"} /^Thread/ { gsub(" ", ""); threads=$2} /^Core/ { gsub(" ", ""); cores=$2 } /^Socket/ { gsub(" ", ""); sockets=$2 } END { printf sockets " socket(s); " cores " core(s) per socket; " threads " thread(s) per core" }')
	local osver=$(awk ' BEGIN {FS="="} /^DISTRIB_DES/ { gsub("\"", ""); print $2 }' /etc/*-release)

	if [ ${#osver} -lt 1 ]; then
		osver=$(awk ' BEGIN {FS="="} /^PRETTY_NAME/ { gsub("\"", ""); print $2 }' /etc/*-release)
	fi

	local kernver=$(uname -r)
	local kerndate=$(uname -v)
	kerndate="${kerndate:(-28)}"

	local CurrLoad=$(awk '{print $3 * 100 " %"}' /proc/loadavg)
	local memfree=$(free -m | head -n 2 | tail -n 1 | awk '{print $4}')
	local memtotal=$(free -m | head -n 2 | tail -n 1 | awk '{print $2}')

	local nomen=$(hostname -f)

	local uptime=$(uptime -p | sed 's/up //g')
	local lastfewboots=$(last -wax | awk ' BEGIN { times=0 } /^reboot|^shutdown/ { sub("reboot   ",""); sub("shutdown ", ""); sub("system ", ""); print "          " $0; times+=1; if (times==7) exit }')

	out-Heading "System Information"
	printf "   ${Item}Hostname:${Color_Off}\t${Text}${nomen}\n"
	printf "   ${Item}CPU:${Color_Off}\t\t${Text}${procval}\n"
	printf "   ${Item}Cores:${Color_Off}\t${Text}${socCorThr}${Color_Off}\n"
	printf "   ${Item}Distro:${Color_Off}\t${Text}${osver}\n"
	printf "   ${Item}Kernel:${Color_Off}\t${Text}${kernver} ${kerndate}${Color_Off}\n"

	printf "\n"
	echo -en "   ${Item}CPU Load:${Color_Off} \t${Text}${CurrLoad}${Color_Off}\n"
	printf "   ${Item}Memory:${Color_Off}\t${Text}$(printf "%'d" ${memfree})Mb free / $(printf "%'d" ${memtotal})Mb total${Color_Off}\n"
	printf "   ${Item}Up for:${Color_Off} \t${Text}${uptime}${Color_Off}\n"
	printf "\n"

	printf "   ${Item}Recent Boot History:${Color_Off}\n"
	printf "${Color_Off}${Text}${lastfewboots}${Color_Off}\n"
	printf "\n"
}

function date-info {
	#CLI 7
	local retval=""

	#This section expects the calendar files to exist
	#in the user's home directory under .calendar
	#see man calendar for more information...
	if [ -r "${HOME}/.calendar/calendar" ]; then
		retval=$(calendar -W 0 | sed -E "s/$(date -j '+%b %_d')../~ /" | fold -s -w 73 | awk ' $1!="~" { printf "    %s'${Color_Off}'\n", $0 } $1=="~" { $1=""; printf "'${Item}'*'${Text}'%s\n", $0 };')
		if ! [ -z "${retval}" ]; then
			out-Heading "On this day in history..."
			echo "${retval}"
			printf "\n"
		fi
	fi
}

function OutBDay {
	#Syntax: OutBDay Target Title [InclTotals]
	#   where
	#		Target = the date to count to (in MM/DD/YY-Hr-Mn format)
	#		Title = text to print before the count
	#		InclTotals = 0 or nothing incl total year count; 1 don't incl total year count

	#Establish base vars
	local retval=""
	local HowOldAmI=""
	local BeforeBDay=0

	#break out the arguments
	local bdate="${1}"			#The first argument supplied (date)
	local InclTotal=${3:-0}		#The third argument - or 0 if nothing (include age)
	local sTitle="${2}"			#The second argument (the text to display)

	#break out the date components
	local bmonth=${bdate:0:2}	#The month
	local bday=${bdate:3:2}		#The day
	local byear=${bdate:6:4}	#The year

	#Get today in the "correct" format
	local cdate=$(date "+%m/%d/%Y-%H-%M")

	#Break out today components
	local cmonth=${cdate:0:2}
	local cday=${cdate:3:2}
	local cyear=${cdate:6:4}

	#Check if the "when" is before or after today
	if [[ "${cmonth#0}" -lt "${bmonth#0}" ]] || [[ "${cmonth#0}" -eq "${bmonth#0}" && "${cday#0}" -lt "${bday#0}" ]]; then
		let HowOldAmI=cyear-byear-1
		BeforeBDay=0
	else
 		let HowOldAmI=cyear-byear
 		BeforeBDay=1
	fi

	#Prepare the "next occurence" date - including the display thereof
	local NextBDay="${bmonth}/${bday}/$(date --date="+${BeforeBDay} years" +%Y)-00-00"

	local NextBDayExp=$(date --date="${NextBDay:0:10}" "+%A %m/%d/%Y" | awk '{ printf "%-9s %s", $1, $2 }')

	#output
	printf "  ${Item}$(echo "${sTitle}:" | awk ' {printf "%-21s", $0}')${Text}"
	printf "$(LongOutTime $(dateDiff $(date2secs ${cdate}) $(date2secs ${NextBDay})) d)" | awk '{ printf " %6s ", $1; }'

	printf "  ${NextBDayExp}"
	if [ "${InclTotal}" -eq "0" ]; then printf "$(( ${HowOldAmI} + 1 ))" | awk '{ printf "   (%3s)", $1;}'; fi

}

function HowLongUntil {
	#CLI 8
	#A simple function ... that calls other, less simple functions.
	#Print out how many days until something
	#Looks for a dates.txt file in a data subfolder under the script folder
	#	format:		item,date,includeAge
	#	example:	my birthday,01/02/03-00-00
	#				stepped on nail,04/05/06-09-15
	#		(where item and date are mandatory, and includeAge is optional)
	#Otherwise, you can specify items here in the script (see below)
	out-Heading "How Long Until..."

	#here's the heading
	printf "${SubHead}"
	echo " ~Days~Next Date~Years" | awk 'BEGIN{FS="~"}{ printf "%-23s %6s        %-10s        %5s", $1, $2, $3, $4; }'
	printf "\n"

	#here's where we parse the file
	local Where="${ScriptLoc}/data"
	if [ -r "${Where}/dates.txt" ]; then
		while IFS=, read -r f1 f2 f3; do
			OutBDay "${f2}" "${f1}" "${f3}"
			printf "\n"
		done < "${Where}/dates.txt"

	fi

	#and here're the manual items
	#Thanksgiving is special (4 thurs in Nov)
	OutBDay "$(FindNextOccurence 11 TH 4)-00-00" "Thanksgiving" 1
	printf "\n"

	OutBDay "12/25/2014-00-00" "Christmas" 1
	printf "\n"
	OutBDay "01/01/2015-00-00" "New Years" 1
	printf "\n"
#	OutBDay "$(FindNextOccurence 03 SU 2)-00-00" "DST Starts (Lose)" 1
#	printf "\n"
#	OutBDay "$(FindNextOccurence 11 SU 1)-00-00" "DST Ends (Gain!)" 1
#	printf "\n"

}

function FindNextOccurence {
	#Syntax: FindNextOccurence Month Day Which
	#	where Month is 2 digits for month
	#         Day is 2 letters (CAP'd) of the day (MO, TU, WE, etc)
	#		  Which is which one (1 = first, 2 = second, etc)
	#Finds the next occurence of a holiday that occurs on different dates each year
	#Thanksgiving is 4th Thurs in Nov (so "FindNextOccurence 11 TH 4")
	#President's Day is 3rd Mon in Feb (so "FindNextOccurence 2 MO 3")
	local tYear
	local tDay
	local sMonth
	local sDay
	local iNumber
	sMonth="${1}"
	sDay="${2}"
	iNumber="${3}"
	#What's the current year
	tYear=$(date +%Y)
	tDay=$(specday ${tYear} ${sMonth} ${sDay} ${iNumber})
	#Now check if we've passed that month and day this year
	#Note: I force base 10 on all the numbers because bash can get confused with leading 0's
	if (( 10#$(date +%m) == 10#${sMonth} && 10#$(date +%d) > 10#${tDay} )) || (( 10#$(date +%m) > 10#${sMonth} )) ; then
			#Recalc the date for next year
			tYear=$(date --date="+1 year" +%Y)
			tDay=$(specday ${tYear} ${sMonth} ${sDay} ${iNumber})
	fi
	#and return the date we found
	printf "${sMonth}/${tDay}/${tYear}"
}

function Working {
	## just a temporary working function where I can test stuff
	echo "noop"
}

## Sets up for selecting which section at the command line
## The single number gives 1 section
## No number defaults to 99 ... which gives most sections
## Sections can be disabled from the full list by setting
##   it's -gt to more than 99
## A single section will include a blank line to start
## (that's what the 'if -lt 90' bit at the start does)
What=${1:-99}

if [[ "${What}" == "auto" ]]; then
	exec 1>/etc/motd 2>&1
	What=99
fi
if [ ${What} -lt 90 ]; then echo " "; fi

## Print a Run at x day and time header
out-Heading "Script Run"
printf "   $(date '+%a, %D, %r')\n\n"

if [ ${What} -eq 1 ] || [ ${What} -gt 90 ]; then get-hardware; fi
if [ ${What} -eq 2 ] || [ ${What} -gt 90 ]; then get-net; fi
if [ ${What} -eq 3 ] || [ ${What} -gt 90 ]; then get-disk; fi
if [ ${What} -eq 4 ] || [ ${What} -gt 999 ]; then get-screen; fi
if [ ${What} -eq 5 ] || [ ${What} -gt 999 ]; then get-panics; fi
if [ ${What} -eq 6 ] || [ ${What} -gt 90 ]; then get-users; fi
if [ ${What} -eq 7 ] || [ ${What} -gt 90 ]; then date-info; fi
if [ ${What} -eq 8 ] || [ ${What} -gt 90 ]; then HowLongUntil; fi
if [ ${What} -eq 75 ]; then Working; fi

printf "\n"
