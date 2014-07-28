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

########################
##      CONSTANTS     ##
########################

OPENB="${IWhite}["
CLOSEB="${IWhite}] "

#Set up for load monitoring
#NCPU=$(grep -c 'processor' /proc/cpuinfo)    # Number of CPUs
#SLOAD=$(( 100*${NCPU} ))        # Small load
#MLOAD=$(( 200*${NCPU} ))        # Medium load
#XLOAD=$(( 400*${NCPU} ))        # Xlarge load

########################
##     FUNCTIONS      ##
########################

function GetSSHConnection {
# Test connection type:
if [ -n "${SSH_CONNECTION}" ]; then
	## We're connected via SSH
	local retval="\n${OPENB}${Green}SSH'd from "  # Connected on remote machine, via ssh (good)
	local SSH_IP=`echo ${SSH_CONNECTION} | awk '{print $1}'`
	local SSH_NAME=`echo ${SSH_IP} | nslookup | grep name | awk '{print $4}'`
	if [ -n "${SSH_NAME}" ]; then
		retval=${retval}${Purple}${SSH_NAME/%./}
	else
		retval=${retval}${Purple}${SSH_IP}
	fi
	retval=${retval}${CLOSEB}
	#LIBGL_ALWAYS_INDIRECT=1 allows "local" opengl rendering
	export LIBGL_ALWAYS_INDIRECT=1
	echo -e ${retval}
fi
}

function GetUserColor {
# Test user type (root-ish or normal):
# 	USER will be "root" with Sudo
# 	UID will be 0 with su
# 	C:\Windows will be writable with Windows (via cygwin)
	local retval=${Yellow}	# Default to caution... we just don't know who you are
	if [[ ${USER} == "root" ]] || [[ ${UID} -eq 0 ]] || [[ -w /cygdrive/c/Windows ]]; then
		retval=${Red}           # User is root.
		if [[ ${SUDO_USER} && ${SUDO_USER-x} ]]; then
			retval="${White}(${Green}${SUDO_USER}${White})${Red}"
		else
			retval=${Red}
		fi
	elif [[ ${USER} != $(logname) ]]; then
		retval=${BRed}          # Alert: User is not login user.
	else
		retval=${Green}         # User is normal (yay!).
	fi
	echo -e ${retval}
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

#try to pull ssid
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
	echo -e ${retval}
}

function cpu_load()
{
	local retval
	local SYSLOAD
	local comparo
	#SYSLOAD=$(top -b -n2 -d 0.1 | fgrep "Cpu(s)" | tail -1 | awk -F'id,' -v prefix="$prefix" '{ split($1, vs, ","); v=vs[length(vs)]; sub("%", "", v); printf "%s%.1f\n", prefix, 100 - v }')
	SYSLOAD=$(top -b -n2 -d 0.1 | fgrep "Cpu(s)" | tail -1 | cut -d , -f4 | cut -d " " -f2 | awk '{ print 100-$1}' )
	if [[ ${SYSLOAD} && ${SYSLOAD-x} ]]; then
		## another option: echo $var | awk '{print int($1+0.5)}'
		retval="${White}cpu "
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
	echo -en ${retval}
}

# Formating for memory
function memory_load()
{
	local retval=""
	local freeExists=$(which free 2> /dev/null)
	if [[ ${freeExists} && ${freeExists-x} ]]; then
		local memfree=$(free -m | head -n 2 | tail -n 1 | awk {'print $4'})
		local memtotal=$(free -m | head -n 2 | tail -n 1 | awk {'print $2'})
		local memcent=$(echo "scale=0; (100-(100*$memfree/$memtotal))" | bc -l)

		retval="${White}mem "

	        if [ ${memcent} -gt 85 ]; then
        	    retval=${retval}${Red}		# Memory almost full (>85%).
	        elif [ ${memcent} -gt 65 ]; then
        	    retval=${retval}${Yellow}		# Memory space almost gone (>65%).
	        else
        	    retval=${retval}${Green}		# Memory space is ok.
	        fi
        	echo -en "${retval}${memcent}${White}%"
	fi
}

function load_util()
{
	local retval=""
	retval="$(cpu_load) $(memory_load)"
	echo -en "${OPENB}${retval}${CLOSEB}"
}

# Returns a color according to free disk space in $PWD.
function path_info()
{
	local retval=""
	local diskloc="${PWD/$HOME/\~}"
	if [ ! -w "${PWD}" ] ; then
        	retval="${Red}RO ${diskloc//\//$White\/$Red}"
	        # No 'write' privilege in the current directory.
	else
		retval="${Green}${diskloc//\//$White\/$Green}"
	fi

	if [ -d "${PWD}" ] ; then
        	local used=$(command df -P "$PWD" | awk 'END {print $5} {sub(/%/,"")}')
		if [ ${used} -gt 95 ]; then
			retval=${retval}${BRed}           # Disk almost full (>95%).
		elif [ ${used} -gt 80 ]; then
			retval=${retval}${Yellow}            # Free disk space almost gone.
		else
			retval=${retval}${Green}           # Free disk space is ok.
		fi
		let used=100-${used}
		retval=${retval}" $used$White% free"
	#else
        	# Current directory is size '0' (like /proc, /sys etc).
	fi
	echo -en ${retval}
}

#Returns error stuff
function error_result()
{
    local Last_Command=$?

    if [[ ! $Last_Command == 0 ]]; then
        echo -en "${IWhite}[e${Red}${Last_Command}${IWhite}] "
    fi
    echo -en ${Color_Off}
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
					BATSTT="${Green}↑${Color_Off} "
				;;
				'Discharging')
					BATSTT="${Red}↓${Color_Off}"
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
		echo -en " ${OPENB}${BATSTT}${retval}${CLOSEB}"
	fi
}

##Runtime of the last command
#RUNTIME_LAST_SECONDS=$SECONDS

#function RunTime()
#{
#        # display runtime seconds as days, hours, minutes, and seconds
#        [[ "$RUNTIME_SECONDS" -ge 86400 ]] && echo -ne $((RUNTIME_SECONDS / 86400))d
#        [[ "$RUNTIME_SECONDS" -ge 3600 ]] && echo -ne $((RUNTIME_SECONDS % 86400 / 3600))h
#        [[ "$RUNTIME_SECONDS" -ge 60 ]] && echo -ne $((RUNTIME_SECONDS % 3600 / 60))m
#        echo -ne $((RUNTIME_SECONDS % 60))s
#        echo -ne "${NO_COL}"
#    fi
#}
#
#function Reset_RunTime()
#{
#    # Compute number of seconds since program was started
#    RUNTIME_SECONDS=$((SECONDS - RUNTIME_LAST_SECONDS))
#
#    # If no proper command was executed (i.e., someone pressed enter without entering a command),
#    # reset the runtime counter
#    [ "$RUNTIME_COMMAND_EXECUTED" != 1 ] && RUNTIME_LAST_SECONDS=$SECONDS && RUNTIME_SECONDS=0
#
#    # A proper command has been executed if the last command was not related to liquidprompt
#    [ "$BASH_COMMAND" = set_prompt ] && RUNTIME_COMMAND_EXECUTED=0 && return
#    RUNTIME_COMMAND_EXECUTED=1
#}
#
#    # _lp_reset_runtime gets called whenever bash executes a command
#    trap 'Reset_RunTime' DEBUG


# Now ... the prompt.
#PROMPT_COMMAND="history -a"	# remembers history across all sessions
PROMPT_COMMAND=prompt_big

function prompt_small {
   if [ $(id -u) -eq 0 ]; then
      PS1="${debian_chroot:+($debian_chroot)}\n\[$BWhite\][\[$Yellow\]\@\[$BWhite\]] [\[$Red\]\u\[$Purple\]@\h\[$BWhite\]] [\[$IBlue\]\w\[$BWhite\]]\[$Color_Off\]\n\$ "
   else
      PS1="${debian_chroot:+($debian_chroot)}\n\[$BWhite\][\[$Yellow\]\@\[$BWhite\]] [\[$Green\]\u\[$Purple\]@\h\[$BWhite\]] [\[$IBlue\]\w\[$BWhite\]]\[$Color_Off\]\n\$ "
   fi
   unset PROMPT_COMMAND
}

function prompt_big {
	#Error and History info
	PS1="\n\[\$(error_result)\]"
	# Shell Depth
	PS1=${PS1}"\[$OPENB\]\[$White\]sh \[$Yellow\]\[\$SHLVL\]\[$CLOSEB\]"
	# CPU and memory stats
	PS1=${PS1}"\[\$(load_util)\]"
	# History
	PS1=${PS1}"\[$OPENB\]\[$White\]h\[$Green\]\!\[$CLOSEB\]"
	# IP
	PS1=${PS1}"\[$(GetNetwork)\]"
	# Battery
	PS1=${PS1}"\[\$(battery_status)\]"
	PS1=${PS1}"\n"
        # Day and Time
	PS1=${PS1}"\[$OPENB\]\[$Yellow\]\D{%a %I:%M%P}\[$CLOSEB\]"
        # User@Host (with connection type info):
	PS1=${PS1}"\[$OPENB\]\[$(GetUserColor)\]\u\[$Color_Off\]@\[$Purple\]\h\[$CLOSEB\]"
        # PWD (with 'disk space' info):
        PS1=${PS1}"\[$OPENB\]\[$IBlue\]\[\$(path_info)\]\[$CLOSEB\]"
	PS1=${PS1}"\[\$(GetSSHConnection)\]"
	# new line and $ or #
	PS1=${PS1}"\n\[$IYellow\]\$\[$Color_Off\] "
}

PS2="> "
PS3="> "
PS4="+ "

# Try to keep environment pollution down, EPA loves us.
unset safe_term match_lhs

