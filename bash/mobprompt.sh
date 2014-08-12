#!/bin/bash
########################
##      COMMENTS      ##
########################
##
## My Obligatory Bash Prompt
##
## Sets up a overly informational bash prompt
## complete with time, user, ip, performance,
## and other things that I find interesting.
##
## It's designed to be sourced from either
## ~/.bashrc or /etc/bash.bashrc or gen'd
## through /etc/profile.d
##
########################

# If not running interactively, don't do anything
test -z "${TERM}" -o "x${TERM}" = dumb && return

##########################
##      CONSTANTS       ##
## and initial settings ##
##########################

#the open and close brackets - with color
OPENB="${IWhite}["
CLOSEB="${IWhite}]"

#the linedraw character default
FillChar="─"

#the battery charge/discharge symbols
battdn="▼"
battup="▲"


########################
##     FUNCTIONS      ##
########################

function GetSSHConnection {
# Test connection type:
if [ -n "${SSH_CONNECTION}" ]; then
	## We're connected via SSH
	local retval="${OPENB}${Green}SSH'd from "  # Connected on remote machine, via ssh (good)
	#try to get the ip and name (and trim the name so there's no domain)
	local SSH_IP=`echo ${SSH_CONNECTION} | awk '{print $1}'`
	local SSH_NAME=`echo ${SSH_IP} | nslookup | grep name | awk '{print $4}'`
	local hostip=""
	if [ -n "${SSH_NAME}" ]; then
		hostip=$(echo ${SSH_NAME} | cut -d . -f1)
	else
		hostip=${SSH_IP}
	fi
	retval=${retval}${Purple}${hostip}${CLOSEB}
	#LIBGL_ALWAYS_INDIRECT=1 allows "local" opengl rendering
	export LIBGL_ALWAYS_INDIRECT=1
	#For setting the terminal title
	IsSoSSH="ssh'd to ${hostip} as ${USER}"
	echo -n ${retval}
else
	IsSoSSH=""
fi
}

function GetUserColor {
# Test user type (root-ish or normal). As root:
# 	USER will be "root" with Sudo
# 	UID will be 0 with su
# 	C:\Windows will be writable with Windows (via cygwin)
	local retval=${Yellow}	# Default to caution... we just don't know who you are
	if [[ ${USER} == "root" ]] || [[ ${UID} -eq 0 ]] || [[ -w /cygdrive/c/Windows ]]; then
		retval="${White}(${Green}$(logname)" # User is root
		if [[ ${SUDO_USER} && ${SUDO_USER-x} ]]; then
			retval=${retval}"${White} sudo'd as"
		else
			retval=${retval}"${White} su'd as"
		fi
			retval=${retval}"${White}) ${Red}"

	elif [[ ${USER} != $(logname) ]]; then
		retval=${BRed}          # Alert: User is not login user.
	else
		retval=${Green}         # User is normal (yay!).
	fi
	retval=${retval}${USER}
	echo -n ${retval}
}

function GetNetwork {
	#Try to pull ip info (ip address and wireless ssid)
	local retval=""

	#Check IP (on linux) or route print (on Windows) for the IP
	#IP includes the netmask, which we'll cut out
	local IP=$(which ip 2> /dev/null)
	if [[ ${IP} && ${IP-x} ]]; then
		IP=$(ip addr show | grep global | awk '{print $2}' | cut -d / -f1)
	else
		IP=$(route print | egrep "^ +0.0.0.0 +0.0.0.0 +" | gawk 'BEGIN { metric=255; ip="0.0.0.0"; } { if ( $5 < metric ) { ip=$4; metric=$5; } } END { printf("%s\n",ip); }')
	fi
	#Verify the IP is valid
	if [[ ! ${IP} =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		IP=""
	fi

	#try to pull wireless ssid
	# iwgetid reads the ssid
	local IPSSID=$(which iwgetid 2> /dev/null)
	if [[ $IPSSID && ${IPSSID-x} ]]; then
		IPSSID=$(iwgetid -r)
	fi

	#put it all together
	if [[ $IP && ${IP-x} ]]; then
		retval=${OPENB}
	        if [[ $IPSSID && ${IPSSID-x} ]]; then
        	        retval="${retval}${Green}${IPSSID} "
	        fi
		retval=${retval}${Yellow}${IP}${CLOSEB}
	fi
	echo -n ${retval}
}

function cpu_load()
{
	#parses top to get idle percentage (and subtracts from 100 to get use)
	local retval
	local SYSLOAD
	local comparo
	SYSLOAD=$(top -b -n2 -d 0.1 | fgrep "Cpu(s)" | tail -1 | cut -d , -f4)
	SYSLOAD=$(trim "${SYSLOAD}")
	SYSLOAD=$(echo -n ${SYSLOAD} | cut -d " " -f1 | awk '{ print 100-$1}' )

	if [[ ${SYSLOAD} && ${SYSLOAD-x} ]]; then
		retval="${White}cpu "
		#color the % output
		comparo=$(printf %.0f ${SYSLOAD})
		if [ ${comparo} -gt 85 ]; then
			retval=${retval}${BRed}
		elif [ ${comparo} -gt 50 ]; then
        		retval=${retval}${Yellow}
		else
        		retval=${retval}${Green}
		fi
		retval="${retval}${SYSLOAD}${White}%"
	fi
	echo -n ${retval}
}

function load_diff() {
	local one=$(uptime | sed -e "s/.*load average: \(.*\...\), \(.*\...\), \(.*\...\)/\1/" -e "s/ //g")
	local five=$(uptime | sed -e "s/.*load average: \(.*\...\), \(.*\...\), \(.*\...\).*/\2/" -e "s/ //g")
	local diff1_5=$(echo -e "scale = scale ($one) \nx=$one - $five\n if (x>0) {print \"${battup}\"} else {print \"${battdn}\"}\n print x \nquit \n" | bc)
	local retval=$(echo -n ${diff1_5} | sed -e 's/\-//g')
	echo -n "ld ${Green}${retval}${Color_Off}"
}

# Formating for memory
function memory_load()
{
	#pulls memory load 
	local retval=""
	local freeExists=$(which free 2> /dev/null)
	if [[ ${freeExists} && ${freeExists-x} ]]; then
		local memfree=$(free -m | head -n 2 | tail -n 1 | awk {'print $4'})
		local memtotal=$(free -m | head -n 2 | tail -n 1 | awk {'print $2'})
		local memcent=$(echo "scale=0; (100-(100*$memfree/$memtotal))" | bc -l)

		retval="${White}mem "
		#and color as necessary
	        if [ ${memcent} -gt 85 ]; then
        	    retval=${retval}${Red}		# Memory almost full (>85%).
	        elif [ ${memcent} -gt 65 ]; then
        	    retval=${retval}${Yellow}		# Memory space almost gone (>65%).
	        else
        	    retval=${retval}${Green}		# Memory space is ok.
	        fi
        	echo -n "${retval}${memcent}${White}%"
	fi
}

function get_uptime() {
	# pulls uptime from source other than... uptime (which doesn't seem to work on cygwin)
	local uptime=$(</proc/uptime)
	local timeused=${uptime%%.*}
	local daysused=0
	local hoursused=0
	local minutesused=0
	local secondsused=0
	local retval="up "

	#break it up into human readable time
	if [[ ${timeused} && ${timeused-x} ]]; then
		if (( timeused > 86400 )); then
			((
				daysused=timeused/86400,
				hoursused=timeused/3600-daysused*24,
				minutesused=timeused/60-hoursused*60-daysused*60*24,
				secondsused=timeused-minutesused*60-hoursused*3600-daysused*3600*24
			))
		elif (( timeused < 3600 )); then
			((
			minutesused=timeused/60,
			secondsused=timeused-minutesused*60
		))
		elif (( timeused < 86400 )); then
			((
			hoursused=timeused/3600,
			minutesused=timeused/60-hoursused*60,
			secondsused=timeused-minutesused*60-hoursused*3600
			))
		fi

		#color and display
		retval=${retval}"${Green}${daysused}${White}d "
		retval=${retval}"${Green}${hoursused}${White}h:"
		retval=${retval}"${Green}$(echo ${minutesused} | sed -e :a -e 's/^.\{1,1\}$/0&/;ta' )${White}m:"
		retval=${retval}"${Green}$(echo ${secondsused} | sed -e :a -e 's/^.\{1,1\}$/0&/;ta' )${White}s"

		echo -n ${retval}
	fi
}

function load_util()
{
	#put all the loads (incl. battery) together
	local retval=""
	local batstat=$(battery_status)
	local upt=$(get_uptime)
	retval="$(load_diff) $(cpu_load) $(memory_load)"
	if [[ ${batstat} && ${batstat-x} ]]; then
		retval="${retval} ${batstat}"
	fi
	echo -n "${OPENB}${retval}${CLOSEB}"
}

function path_info()
{
	# Returns a color according to free disk space in $PWD.
	# Also pulls the count of various files in the dir
	#    (but only if there's enough room on screen)
	local retval=""
	local lengthlimit=${1}
	local diskloc="${PWD/$HOME/\~}"

	#get the free space and color it
	if [ -d "${PWD}" ] ; then
        	local used=$(command df -P "$PWD" | awk 'END {print $5} {sub(/%/,"")}')
		if [ ! "${used}" == "-" ]; then
			retval=${retval}" ${White}free"
			if [ ${used} -gt 95 ]; then
				retval=${retval}${BRed}           # Disk almost full (>95%).
			elif [ ${used} -gt 80 ]; then
				retval=${retval}${Yellow}            # Free disk space almost gone.
			else
				retval=${retval}${Green}           # Free disk space is ok.
			fi
			let used=100-${used}
		else
			# Current directory is size '-' (like /proc, /sys etc).
			used="${Green}-"
		fi
		retval=${retval}" ${used}${White}%"
		retval=${retval}" ${White}#:$(pwd_counts) ${White}=$(pwd_size)"
	fi

	#Now trim the path down if the screen is too narrow
	local curclean=$(cleanesc ${retval})
	local curlength=${#curclean}
	local maxlength=0
	let maxlength=(${curlength}+${lengthlimit})
	local pwdshrunk=$(trim_pwd ${maxlength} ${diskloc})
	diskloc=${pwdshrunk}

	#Check if the pwd is read-only (not read-write)
	#and color the text (but not the slashes)
	if [ ! -w "${PWD}" ] ; then
        	retval="${Red}RO ${diskloc//\//$White\/$Red}"${retval}
	        # No 'write' privilege in the current directory.
	else
		retval="${Green}${diskloc//\//$White\/$Green}"${retval}
	fi

	#We've trimmed the path, now trim out the number of files/dirs (if necessary)
	#Based around the position of the %
	curclean=$(cleanesc ${retval})
	curlength=${#curclean}
	let maxlength=(${curlength}+${lengthlimit} + 4)
	if [[ ${maxlength} -gt ${COLUMNS} ]]; then
		local percloc=$(expr index "${retval}" "%")
		retval=${retval:0:${percloc}}
	fi

	echo -n ${retval}
}

function pwd_counts()
{
	#Count the number of various files in the dir
	#reg=just plain; hid=hidden; exe=+x
	local filesreg=$(ls -p1 2> /dev/null | grep -v ^l | grep -v / | wc -l)
	local fileshid=$(ls -ld .[^.]* 2> /dev/null | grep -v ^l | grep -v / | wc -l)
	local filesexe=$(ls -FA1 2> /dev/null | grep \* | wc -l)
	local dirreg=$(ls -l 2> /dev/null | grep ^d | wc -l)
	local dirhid=$(ls -ld .[^.]* 2> /dev/null | grep -v ^l | grep / | wc -l)

	local retval=""
	retval=${retval}"${White}/${Green}${dirreg} "
	retval=${retval}"${White}./${Green}${dirhid} "
	retval=${retval}"${White}-${Green}${filesreg} "
	retval=${retval}"${White}.-${Green}${fileshid} "
	retval=${retval}"${White}-*${Green}${filesexe} "
	echo -n ${retval}
}

function trim_pwd() {
	#shrink the pwd to initials if it's too long (leave the actual working dir)
	local p=${2/#$HOME/\~} b s
	local slashcount="${PWD//[^\/]/}"
	slashcount=${#slashcount}
	if [ ${slashcount} -gt 1 ]; then
		s=${#p}
		while [[ $p != "${p//\/}" ]]&&(($s>((${COLUMNS}-$1))))
		do
			p=${p#/}
			[[ $p =~ \.?. ]]
			b=$b/${BASH_REMATCH[0]}
			p=${p#*/}
			((s=${#b}+${#p}))
		done
		echo ${b/\/~/\~}${b+/}$p
	else
		echo ${p}
	fi
}

function _git_prompt() {
	#test current dir for git status (if any)
	local git_status=$(which git 2> /dev/null)
	local retval=""
	local branch=""
	if [[ ${git_status} && ${git_status-x} ]]; then
		git_status="$(git status -unormal 2>&1)"
		if ! [[ "${git_status}" =~ Not\ a\ git\ repo ]]; then
			if [[ "${git_status}" =~ nothing\ to\ commit ]]; then
				retval=$GREEN
			elif [[ "${git_status}" =~ nothing\ added\ to\ commit\ but\ untracked\ files\ present ]]; then
				retval=$RED
			else
				retval=$YELLOW
			fi
			if [[ "$git_status" =~ On\ branch\ ([^[:space:]]+) ]]; then
				branch=${BASH_REMATCH[1]}
				#test "$branch" != master || branch=' '
			else
				# Detached HEAD.  (branch=HEAD is a faster alternative.)
				branch="(`git describe --all --contains --abbrev=4 HEAD 2> /dev/null ||
				echo HEAD`)"
			fi
		echo -n "${OPENB}${retval}${branch}${CLOSEB}"
		fi
	fi
}

function pwd_size() {
	#totals all files in the pwd and shows the human readable total
	local TotalBytes
	let TotalBytes=0

	for Bytes in $(\ls -lA -1 | grep "^-" | awk '{ print $5 }'); do
		let TotalBytes=$TotalBytes+$Bytes
	done

	if [ $TotalBytes -lt 1024 ]; then
		TotalSize=$(echo -e "scale=1 \n$TotalBytes \nquit" | bc)
		suffix="B"
	elif [ $TotalBytes -lt 1048576 ]; then
		TotalSize=$(echo -e "scale=1 \n$TotalBytes/1024 \nquit" | bc)
		suffix="KB"
	elif [ $TotalBytes -lt 1073741824 ]; then
		TotalSize=$(echo -e "scale=1 \n$TotalBytes/1048576 \nquit" | bc)
		suffix="MB"
	elif [ $TotalBytes -lt 1099511627776 ]; then
		TotalSize=$(echo -e "scale=1 \n$TotalBytes/1073741824 \nquit" | bc)
		suffix="GB"
	else
		TotalSize=$(echo -e "scale=1 \n$TotalBytes/1099511627776 \nquit" | bc)
		suffix="TB"
	fi

	echo -n "${Green}${TotalSize}${White}${suffix}"
}

#Returns error stuff
function error_result()
{
	local Last_Command=$?
	local retval
	if [[ ! $Last_Command == 0 ]]; then
		retval="${OPENB}e${Red}${Last_Command}${CLOSEB}"
	fi
    echo -n ${retval}
}

function battery_status()
{
	local retval=""
	for BATS in 'BAT0' 'BAT1' ; do
		if [ -d /sys/class/power_supply/${BATS} ]; then
			local BATTERY=/sys/class/power_supply/${BATS}
			local CHARGE=""
			local BATSTATE=""
			if [ -a ${BATTERY}/capacity ]; then
				CHARGE=$(cat $BATTERY/capacity)
			fi
			if [ -a ${BATTERY}/status ]; then
				BATSTATE=$(cat $BATTERY/status)
			fi

			local COLOUR="$Red"

			case "${BATSTATE}" in
				'Charged')
					BATSTT=""
				;;
				'Charging')
					BATSTT="${Green}${battup}${Color_Off} "
				;;
				'Discharging')
					BATSTT="${Red}${battdn}${Color_Off}"
				;;
			esac

			# prevent a charge of more than 100% displaying
			if [ "$CHARGE" -gt "99" ]; then
				CHARGE=100
			fi

			if [[ "${CHARGE}" -le 100 ]] && [[ "${CHARGE}" -gt 49 ]]; then
				COLOUR="${Green}"
			elif [[ "${CHARGE}" -le 49 ]] && [[ "${CHARGE}" -gt 19 ]]; then
				COLOUR="${Yellow}"
			elif [[ "${CHARGE}" -le 19 ]] && [[ "${CHARGE}" -gt 9 ]]; then
				COLOUR="${Red}"
			elif [[ "${CHARGE}" -le 9 ]] && [[ "${CHARGE}" -gt 0 ]]; then
				COLOUR="${On_IRed}"
			else
				COLOUR="${Purple}"
			fi

			retval=${retval}"${COLOUR}${CHARGE}${White}%"
		fi
	done
	if [[ ${retval} && ${retval-x} ]] ; then
		echo -n "${White}${BATSTT}${retval}${Color_Off}"
	fi
}

function get_history()
{
	local retval
	retval=$(history | tail -1)
	retval=$(trim ${retval})
	retval=$(echo -n ${retval} | cut -d " " -f1)
	let retval=${retval}+1
	echo -n ${retval}
}

function get_tty()
{
	local splay=$(tty | sed -e 's:/dev/::')
	local retval=""
	case "${splay}" in
		tty* )
			retval=${White}tty${Green}$(echo -en ${splay} | sed -e 's:tty::' )
		;;
		pts* )
			retval=${White}pts${Green}$(echo -en ${splay}| sed -e 's:pts/::' )
		;;
		* )
			retval=${White}${splay}
		;;
	esac
	echo -n ${retval}
}

function fill_line() {
	local fillsize
	local cleanedup=$(cleanesc ${*})
	let fillsize=${COLUMNS}-${#cleanedup} 
	local fill=""
	while [ "${fillsize}" -gt 0 ]
	do
		fill="${fill}${FillChar}"
		let fillsize=${fillsize}-1
	done
	echo -n "${fill}"
}

function cleanesc() {
	local retval=$(echo -n $* | sed "s,\e\[[0-9;]*[a-zA-Z],,g" | sed "s,\\\,,g" | sed "s,e(0qe(B, ,g")
	echo "$retval"
}

function color_of_time() {
	local retval
	case "${2}" in
		a*)
			case "${1}" in
				12 | 1 | 2 | 3 | 4 )
					retval=${IBlack}
			;;
				5 | 6 | 7 )
					retval=${White}
			;;
				8 | 9 | 10 )
					retval=${Yellow}
			;;
				11 )
					retval=${IYellow}
			;;
				* )
					retval=${Purple}
			;;
			esac
		;;
		p*)
			case "${1}" in
				8 | 9 | 10 | 11 )
					retval=${IBlack}
			;;
				5 | 6 | 7 )
					retval=${White}
			;;
				2 | 3 | 4 )
					retval=${Yellow}
			;;
				12 | 1 )
					retval=${IYellow}
			;;
				* )
					retval=${Purple}
			;;
			esac
		;;
		* )
			retval=${Purple}
		;;
		esac
	echo -n ${retval}
}

# Now ... the prompt.
PROMPT_COMMAND=prompt_big
#trap "export H1=$(history 1 | sed -e 's/^[\ 0-9]*//; s/[\d0\d31\d34\d39\d96\d127]*//g; s/\(.\{1,50\}\).*$/\1/g'); echo " DEBUG

function prompt_big {
	ErrLevel=$(error_result)

	local leftstuff=""
	local rightstuff=""
	local outstuff=""
	local LineColor=${IWhite}
	#Create holder variable to be able to get console size
	#The error from the last command - sets the line color to red 
	if [[ ${ErrLevel} && ${ErrLevel-x} ]]; then
		LineColor=${Red}
		#leftstuff=${leftstuff}"\${ErrLevel}${LineColor}${FillChar}"
	fi

	local FillCharTemp=${FillChar}
	outstuff=${LineColor}$(fill_line)"\n"
	FillChar=" "

	#Shell depth
	leftstuff=${leftstuff}"${OPENB}${White}sh${Green}${SHLVL} "
	#leftstuff=${leftstuff}${LineColor}${FillChar}
	# History
	leftstuff=${leftstuff}"${White}h${Green}$(get_history) " #${CLOSEB}"
	# Terminal type and number
	leftstuff=${leftstuff}$(get_tty)
	leftstuff=${leftstuff}${CLOSEB}
	leftstuff=${leftstuff}${LineColor}${FillChar}
	#Uptime - but only if the term is wide enough
	local up_time=${OPENB}$(get_uptime)${CLOSEB}
	local lefttemp=$(cleanesc ${up_time}${leftstuff})
	local lefttemplen=${#lefttemp}
	if [[ ${lefttemplen} -lt $((${COLUMNS} / 2)) ]]; then
		leftstuff=${leftstuff}${up_time}
	fi

	# CPU, memory, and battery stats
	rightstuff=${rightstuff}"$(load_util)"
	rightstuff=${rightstuff}${LineColor}${FillChar}

	# Day and Time
	local holdday=$(date +'%a')
	local holdhour=$(date +'%_I')
	holdhour=$(trim ${holdhour})
	local holdmin=$(date +'%M')
	local holdmeri=$(date +'%P')
	local colortime=$(color_of_time ${holdhour} ${holdmeri})
	rightstuff=${rightstuff}"${OPENB}${Green}${holdday} ${colortime}${holdhour}${White}:${colortime}${holdmin}${holdmeri}${CLOSEB}"

	#if the screen is too narrow, we'll remove the uptime
	local line_width
	local line_clean=$(cleanesc ${rightstuff}${leftstuff})
	let line_width=${#line_clean}

	#Line to right justify
	local filled=$(fill_line ${leftstuff}${rightstuff})
	outstuff=${outstuff}${leftstuff}${LineColor}${filled}${rightstuff}"\n"

	leftstuff=""
	rightstuff=""

	#Line 2
 	# IP
	rightstuff=${rightstuff}"$(GetNetwork)"
	rightstuff=${rightstuff}${LineColor}${FillChar}
        # User@Host (with connection type info):
	rightstuff=${rightstuff}"${OPENB}$(GetUserColor)${White}@${Purple}${HOSTNAME}${CLOSEB}"
#	rightstuff=${leftstuff}${LineColor}${FillChar}
	local rightclean=$(cleanesc ${rightstuff})
	local rightlength=${#rightclean}
        # PWD (with 'disk space' info):
        leftstuff=${leftstuff}"${OPENB}${IBlue}$(path_info ${rightlength})${CLOSEB}"
	leftstuff=${leftstuff}${LineColor} #${FillChar}

	#Line to right justify
#	local FillCharTemp=${FillChar}
#	FillChar=" "
	filled=$(fill_line ${leftstuff}${rightstuff})
	outstuff=${outstuff}${leftstuff}${LineColor}${filled}${rightstuff}"\n"

	rightstuff=""
	leftstuff=""

	#Line 3 (maybe)
	IsItSSH=$(GetSSHConnection)
	local cleanIsIt=$(cleanesc ${IsItSSH})
	if [[ ${IsItSSH} && ${IsItSSH-x} ]]; then
		rightstuff=${rightstuff}${IsItSSH}
		filled=$(fill_line ${leftstuff}${rightstuff})
		outstuff=${outstuff}${leftstuff}${LineColor}${filled}${rightstuff}
		#Set the terminal title (skip linux terms)
		if [[ ! $TERM == "linux" ]]; then
			echo -ne "\033]0;${cleanIsIt} ${USER}@${HOSTNAME}: ${PWD/$HOME/\~} - ${H1}\007"
		fi
	else
		#Set the terminal title (skip linux terms)
		if [[ ! $TERM == "linux" ]]; then
			echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD/$HOME/\~}\007"
		fi
	fi

	#Reset the fill character
	FillChar=${FillCharTemp}

	outstuff=${outstuff}${LineColor}$(fill_line)

	#The Actual Prompt!
	PS1="\[\n\n${outstuff}\]"
	# new line and $ or #
	PS1=${PS1}"\n\[${IYellow}\]\$\[${Color_Off}$IsSoSSH\] "

}

PS2="> "
PS3="> "
PS4="+ "

# Try to keep environment pollution down, EPA loves us.
unset safe_term match_lhs

