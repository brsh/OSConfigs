# System-wide .bashrc file for interactive bash(1) shells.

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

##################
## Bash Options ##
##################

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
export HISTCONTROL=ignoreboth

# don't remember the following:
export HISTIGNORE="&:bg:fg:ll:h" 

# Enable history appending instead of overwriting.
shopt -s histappend

# Enable spell-check on directory names with cd command
shopt -s cdspell

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
export HISTSIZE=1000
export HISTFILESIZE=2000

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

#change directory by only entering a directory name
# example: /etc = cd /etc
shopt -s autocd

####################
## Basic Niceties ##
####################

export EDITOR=nano

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Try to enable the auto-completion (type: "pacman -S bash-completion" to install it).
[ -r /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion

# Try to enable the "Command not found" hook ("pacman -S pkgfile" to install it).
# See also: https://wiki.archlinux.org/index.php/Bash#The_.22command_not_found.22_hook
[ -r /usr/share/doc/pkgfile/command-not-found.bash ] && . /usr/share/doc/pkgfile/command-not-found.bash

####################
## Set Color Vars ##
####################

# Reset
Color_Off='\e[0m'       # Text Reset

# Regular Colors
Black='\e[0;30m'        # Black
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow
Blue='\e[0;34m'         # Blue
Purple='\e[0;35m'       # Purple
Cyan='\e[0;36m'         # Cyan
White='\e[0;37m'        # White

# Bold
BBlack='\e[1;30m'       # Black
BRed='\e[1;31m'         # Red
BGreen='\e[1;32m'       # Green
BYellow='\e[1;33m'      # Yellow
BBlue='\e[1;34m'        # Blue
BPurple='\e[1;35m'      # Purple
BCyan='\e[1;36m'        # Cyan
BWhite='\e[1;37m'       # White

# Underline
UBlack='\e[4;30m'       # Black
URed='\e[4;31m'         # Red
UGreen='\e[4;32m'       # Green
UYellow='\e[4;33m'      # Yellow
UBlue='\e[4;34m'        # Blue
UPurple='\e[4;35m'      # Purple
UCyan='\e[4;36m'        # Cyan
UWhite='\e[4;37m'       # White

# Background
On_Black='\e[40m'       # Black
On_Red='\e[41m'         # Red
On_Green='\e[42m'       # Green
On_Yellow='\e[43m'      # Yellow
On_Blue='\e[44m'        # Blue
On_Purple='\e[45m'      # Purple
On_Cyan='\e[46m'        # Cyan
On_White='\e[47m'       # White

# High Intensity
IBlack='\e[0;90m'       # Black
IRed='\e[0;91m'         # Red
IGreen='\e[0;92m'       # Green
IYellow='\e[0;93m'      # Yellow
IBlue='\e[0;94m'        # Blue
IPurple='\e[0;95m'      # Purple
ICyan='\e[0;96m'        # Cyan
IWhite='\e[0;97m'       # White

# Bold High Intensity
BIBlack='\e[1;90m'      # Black
BIRed='\e[1;91m'        # Red
BIGreen='\e[1;92m'      # Green
BIYellow='\e[1;93m'     # Yellow
BIBlue='\e[1;94m'       # Blue
BIPurple='\e[1;95m'     # Purple
BICyan='\e[1;96m'       # Cyan
BIWhite='\e[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\e[0;100m'   # Black
On_IRed='\e[0;101m'     # Red
On_IGreen='\e[0;102m'   # Green
On_IYellow='\e[0;103m'  # Yellow
On_IBlue='\e[0;104m'    # Blue
On_IPurple='\e[10;95m'  # Purple
On_ICyan='\e[0;106m'    # Cyan
On_IWhite='\e[0;107m'   # White

######################
## Useful Functions ##
######################

function list_colors {
local T='gYw'     # the test text
echo -e "\n        40m  100m 41m  101m 42m  102m 43m  103m\
 44m  104m 45m  105m 46m  106m 47m  107m";

for FGs in '    m' '   1m' \
           '  30m' '2;30m' '1;30m' '4;30m' '7;30m' \
           '  90m' '2;90m' '1;90m' '4;90m' '7;90m' \
           '  31m' '2;31m' '1;31m' '4;31m' '7;31m' \
           '  32m' '2;32m' '1;32m' '4;32m' '7;32m' \
           '  33m' '2;33m' '1;33m' '4;33m' '7;33m' \
           '  34m' '2;34m' '1;34m' '4;34m' '7;34m' \
           '  35m' '2;35m' '1;35m' '4;35m' '7;35m' \
           '  36m' '2;36m' '1;36m' '4;36m' '7;36m' \
           '  37m' '2;37m' '1;37m' '4;37m' '7;37m';
	do FG=${FGs// /}
        echo -en " $FGs \033[$FG $T "
	for BG in 40m 41m 101m 42m 102m 43m 103m 44m 104m 45m 105m 46m 106m 47m 107m;
		do echo -en "$EINS\033[$FG\033[$BG $T \033[0m";
	done
	echo;
done
echo
}

function list_colors_256 {
## FG Format: <Esc>[38;5;COLORm
## BF Format: <Esc>[48;5;COLORm
for fgbg in 38 48 ; do 
	for color in {0..256} ; do
		echo -en "\e[${fgbg};5;${color}m ${color}\t\e[0m"
		if [ $((($color + 1) % 10)) == 0 ] ; then
			echo 
		fi
	done
	echo 
done
}


#################
## Basic Stuff ##
#################

#[[ "$PS1" ]] && echo -e "$IYellow";/usr/bin/fortune -sa;echo -e "$Color_Off"
# Test for Fortune and run it (games is ubuntu, bin is arch)
if [[ "$PS1" ]] ; then
        if [[ -x /usr/games/fortune ]]; then 
                echo -e "$IYellow";/usr/games/fortune -sa;echo -e "$Color_Off"
        fi
        if [[ -x /usr/bin/fortune ]]; then 
                echo -e "$IYellow";/usr/bin/fortune -sa;echo -e "$Color_Off"
        fi 
fi

# set an ugly prompt (non-color, overwrite the one in /etc/profile)
PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '

#Set the window title
#case ${TERM} in
#	xterm*|rxvt*|Eterm|aterm|kterm|gnome*)
#		PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033]0;%s@%s:%s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"'
#		;;
#	screen)
#		PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033_%s@%s:%s\033\\" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"'
#		;;
#esac

#coloring LESS
export LESS=-IR
export LESS_TERMCAP_me=$(printf '\e[0m')
export LESS_TERMCAP_se=$(printf '\e[0m')
export LESS_TERMCAP_ue=$(printf '\e[0m')
export LESS_TERMCAP_mb=$(printf '\e[1;32m')
export LESS_TERMCAP_md=$(printf '\e[1;34m')
export LESS_TERMCAP_us=$(printf '\e[1;32m')
export LESS_TERMCAP_so=$(printf '\e[1;44;1m')

#################
## Color Stuff ##
#################

# Set colorful PS1 only on colorful terminals.
# dircolors --print-database uses its own built-in database
# instead of using /etc/DIR_COLORS. Try to use the external file
# first to take advantage of user additions. Use internal bash
# globbing instead of external grep binary.

# sanitize TERM:
safe_term=${TERM//[^[:alnum:]]/?}
match_lhs=""

[[ -f ~/.dir_colors ]] && match_lhs="${match_lhs}$(<~/.dir_colors)"
[[ -f /etc/DIR_COLORS ]] && match_lhs="${match_lhs}$(</etc/DIR_COLORS)"
[[ -z ${match_lhs} ]] \
	&& type -P dircolors >/dev/null \
	&& match_lhs=$(dircolors --print-database)

if [[ $'\n'${match_lhs} == *$'\n'"TERM "${safe_term}* ]] ; then
	
	# we have colors :-)

	# Enable colors for ls, etc. Prefer ~/.dir_colors
	if type -P dircolors >/dev/null ; then
		if [[ -f ~/.dir_colors ]] ; then
			eval $(dircolors -b ~/.dir_colors)
		elif [[ -f /etc/DIR_COLORS ]] ; then
			eval $(dircolors -b /etc/DIR_COLORS)
		fi
	fi

fi

OPENB="${IWhite}["
CLOSEB="${IWhite}] "

# Test connection type:
if [ -n "${SSH_CONNECTION}" ]; then
	## We're connected via SSH
	CNX="\n${OPENB}${Green}SSH'd from "  # Connected on remote machine, via ssh (good)
	SSH_IP=`echo $SSH_CONNECTION | awk '{print $1}'`
	SSH_NAME=`echo $SSH_IP | nslookup | grep name | awk '{print $4}'`
	if [ -n "${SSH_NAME}" ]; then
		CNX=${CNX}${Purple}${SSH_NAME/%./}
	else 
		CNX=${CNX}${Purple}${SSH_IP}
	fi
	CNX=${CNX}${CLOSEB}
fi

# Test user type:
#if [[ ${USER} == "root" ]]; then
if [[ ${USER} == "root" ]] || [[ -w /cygdrive/c/Windows ]]; then
    SU=${Red}           # User is root.
    if [[ $SUDO_USER && ${SUDO_USER-x} ]]; then
	SU="$White($Green$SUDO_USER$White)$Red"
    else
	SU=${Red}
    fi
elif [[ ${USER} != $(logname) ]]; then
    SU=${BRed}          # User is not login user.
else
    SU=${Green}         # User is normal (well ... most of us are).
fi

IP=$(which ip 2> /dev/nul)
if [[ ${IP} && ${IP-x} ]]; then
	IP=`ip addr show | grep global | awk '{print $2}'`
else
	IP=$(route print | egrep "^ +0.0.0.0 +0.0.0.0 +" | gawk 'BEGIN { metric=255; ip="0.0.0.0"; } { if ( $5 < metric ) { ip=$4; metric=$5; } } END { printf("%s\n",ip); }')
fi
if [[ $IP && ${IP-x} ]]; then
	IP="\[$OPENB\]\[$Yellow\]$IP\[$CLOSEB\]"
fi

NCPU=$(grep -c 'processor' /proc/cpuinfo)    # Number of CPUs
SLOAD=$(( 100*${NCPU} ))        # Small load
MLOAD=$(( 200*${NCPU} ))        # Medium load
XLOAD=$(( 400*${NCPU} ))        # Xlarge load

# Returns system load as percentage, i.e., '40' rather than '0.40)'.
function load()
{
local SYSLOAD=""
if [ "${OS}" == "Windows_NT" ]; then
	SYSLOAD=$(typeperf "\Processor(_Total)\% Processor Time" -sc 1 | sed -n '3p' | cut -d , -f2 | tr -d \" | cut -d . -f1) 
else
    SYSLOAD=$(cut -d " " -f1 /proc/loadavg | tr -d '.')
fi
    # System load of the current host.
    echo $((10#$SYSLOAD))       # Convert to decimal.
}

# Returns a color indicating system load.
function load_color()
{
    local SYSLOAD=$(load)
    if [ ${SYSLOAD} -gt ${XLOAD} ]; then
        echo -en ${BRed}
    elif [ ${SYSLOAD} -gt ${MLOAD} ]; then
        echo -en ${Yellow}
    elif [ ${SYSLOAD} -gt ${SLOAD} ]; then
        echo -en ${IRed}
    else
        echo -en ${Green}
    fi
	echo -en $SYSLOAD
}

# Formating for memory
function memory_color()
{
local freeExists=$(which free 2> /dev/nul)
if [[ ${freeExists} && ${freeExists-x} ]]; then
	local memfree=`free -m | head -n 2 | tail -n 1 | awk {'print $4'}`
	local memtotal=`free -m | head -n 2 | tail -n 1 | awk {'print $2'}`
	local memcent=$(echo "scale=0; (100*$memfree/$memtotal)" | bc -l)

	echo -en "${OPENB}${White}mem "

        if [ ${memcent} -gt 85 ]; then
            echo -en ${BRed}           # Memory almost full (>95%).
        elif [ ${memcent} -gt 65 ]; then
            echo -en ${BYellow}            # Memory space almost gone.
        else
            echo -en ${Green}           # Memory space is ok.
        fi
        echo -en "${memcent}${White}% free${CLOSEB}"
fi
}

# Returns a color according to free disk space in $PWD.
function disk_color()
{
    if [ ! -w "${PWD}" ] ; then
        echo -en ${Red}
	echo -en " RO"
        # No 'write' privilege in the current directory.
    else
	echo -en ${Green}
	echo -en " RW"
    fi
    if [ -d "${PWD}" ] ; then
        local used=$(command df -P "$PWD" |
                   awk 'END {print $5} {sub(/%/,"")}')
        if [ ${used} -gt 95 ]; then
            echo -en ${BRed}           # Disk almost full (>95%).
        elif [ ${used} -gt 90 ]; then
            echo -en ${BYellow}            # Free disk space almost gone.
        else
            echo -en ${Green}           # Free disk space is ok.
        fi
	let used=100-$used
	echo -en " $used$White% free"
    else
        echo -en ${Cyan}
        # Current directory is size '0' (like /proc, /sys etc).
    fi
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

# Now we construct the prompt.
PROMPT_COMMAND="history -a"

#   if [ $(id -u) -eq 0 ]; then
#      PS1="${debian_chroot:+($debian_chroot)}\n\[$BWhite\][\[$Yellow\]\@\[$BWhite\]] [\[$BRed\]\u\[$BPurple\]@\h\[$BWhite\]] [\[$BIBlue\]\w\[$BWhite\]]\[$Color_Off\]\n\$ "
#   else
#      PS1="${debian_chroot:+($debian_chroot)}\n\[$BWhite\][\[$Yellow\]\@\[$BWhite\]] [\[$BGreen\]\u\[$BPurple\]@\h\[$BWhite\]] [\[$BIBlue\]\w\[$BWhite\]]\[$Color_Off\]\n\$ "
#   fi
	#Error and History info
	PS1="\n\[\$(error_result)\]"
	# Shell Depth
	PS1=${PS1}"\[$OPENB\]\[$White\]sh \[$Yellow\]\[\$SHLVL\]\[$CLOSEB\]"
	# Load info
	PS1=${PS1}"\[$OPENB\]\[$White\]ld \[\$(load_color)\]\[$CLOSEB\]"
	# Memory Load info
	PS1=${PS1}"\[\$(memory_color)\]"
	# History
	PS1=${PS1}"\[$OPENB\]\[$White\]h\[$Green\]\!\[$CLOSEB\]"
	# IP
	PS1=${PS1}"$IP"
	PS1=${PS1}"\n"
        # Day and Time
	PS1=${PS1}"\[$OPENB\]\[$Yellow\]\D{%a %I:%M%P}\[$CLOSEB\]"
        # User@Host (with connection type info):
	PS1=${PS1}"\[$OPENB\]\[${SU}\]\u\[$Color_Off\]@\[$Purple\]\h\[$CLOSEB\]"
        # PWD (with 'disk space' info):
        PS1=${PS1}"\[$OPENB\]\[$IBlue\]\w\[\$(disk_color)\]\[$CLOSEB\]"
	PS1=${PS1}${CNX}
	# new line and $ or #
	PS1=${PS1}"\n\[$IYellow\]\$\[$Color_Off\] "


PS2="> "
PS3="> "
PS4="+ "

# Try to keep environment pollution down, EPA loves us.
unset safe_term match_lhs CNX SSH_IP SSH_NAME IP

#############
## Aliases ##
#############

alias ls='ls --color=auto --human-readable --group-directories-first --classify'
alias vdir='vdir --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias grep='grep --color=auto'
alias gedit='gedit &'
alias nano='nano -w'

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias dir='ls -la'
alias df='df -h'
alias yogurt=yaourt
alias cls=clear
alias ping='ping -c 4'
alias diff='colordiff'

if [ $UID -ne 0 ]; then
	alias reboot='sudo reboot'
	alias shutdown='sudo shutdown -t 2 now -h'
fi

if [ "${OS}" == "Windows_NT" ]; then
	alias sudo='echo -e "\nSudo is not available in CygWin. Use sudo-s instead."'
	alias sudo-s='/usr/bin/cygstart --action=runas /usr/bin/mintty -e /usr/bin/bash --login'
fi
