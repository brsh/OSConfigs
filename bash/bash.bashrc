# System-wide .bashrc file for interactive bash(1) shells.

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# From where am I being sourced
currBashrc="$(dirname "$BASH_SOURCE")/$(basename "$BASH_SOURCE")"

##################
##   Which OS   ##
##################
# because not everything works the same everywhere
BaseOS=$(uname -s)

case "${BaseOS}" in
	Darwin )
		Distro="MacOS"
	;;
	Linux )
		Distro=$(cat /etc/*-release 2> /dev/null | grep ^NAME= | cut -d = -f2)
		if [[ -e /mnt/c/Windows/System32/bash.exe ]]; then
			# Oh my stars and garters! Bash on Windows?!? Crazy!
			BaseOS="WSL"
		fi
	;;
	CYGWIN* )
		Distro="CygWin"
		BaseOS="Windows"
	;;
	* )
		Distro="${BaseOS}"
esac

##################
## Bash Options ##
##################
## good source: http://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html
# check and update the window size after each command
shopt -s checkwinsize

# Enable history appending instead of overwriting.
shopt -s histappend

# Enable spell-check on directory names
shopt -s cdspell
if [ ! "$BaseOS" == "Darwin" ]; then
	shopt -s dirspell
fi

# Enable change dir with dir name only (no cd)
if [ ! "$BaseOS" == "Darwin" ]; then
	shopt -s autocd
fi

# ignore case when performing filename expansion
shopt -s nocasematch

# Don't search path for completions when TAB on a blank line
shopt -s no_empty_cmd_completion

# Multiline history
shopt -s cmdhist

# Load history substitution for edition BEFORE submission
shopt -s histverify

# ignore duplicate lines & commands starting with space in history
export HISTCONTROL=erasedups:ignoreboth

# don't remember the following:
export HISTIGNORE="&:bg:fg:h:pwd:passwd:history *"

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
export HISTSIZE=300
export HISTFILESIZE=300

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

####################
## Basic Niceties ##
####################

if [ $(which nano 2> /dev/null) ]; then
	export EDITOR=nano
fi

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Try to enable the auto-completion (type: "install bash-completion" to install it).
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

# Inverse
InvBlack='\e[7;30m'       # Black
InvRed='\e[7;31m'         # Red
InvGreen='\e[7;32m'       # Green
InvYellow='\e[7;33m'      # Yellow
InvBlue='\e[7;34m'        # Blue
InvPurple='\e[7;35m'      # Purple
InvCyan='\e[7;36m'        # Cyan
InvWhite='\e[7;37m'       # White

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
	local T=' gYw '     # the test text
	local SPACER=""
	local HEADER="40m  100m 41m  101m 42m  102m 43m  103m\
 44m  104m 45m  105m 46m  106m 47m  107m";
	printf "\n           ${HEADER}\n"
for effect in 0 1 2 4 5 7
do #echo -en "${effect} "
	for FGs in 'm' '1m' \
           '30m' '90m' \
           '31m' '91m' \
           '32m' '92m' \
           '33m' '93m' \
           '34m' '94m' \
           '35m' '95m' \
           '36m' '96m' \
           '37m' '97m' ;
        do FG="${effect};${FGs}"
		SPACER=$FG
		if [ ${#SPACER} -lt 4 ]; then
			SPACER="${FG}  "
		fi
		if [ ${#SPACER} -lt 5 ]; then
			SPACER="${FG} "
		fi
        	printf "${SPACER}\e[$FG${T}"
        for BG in 40m 100m 41m 101m 42m 102m 43m 103m 44m 104m 45m 105m 46m 106m 47m 107m;
                do printf "\e[$FG\e[${BG}${T}\e[0m";
        done
        printf "\n";
	done
done
printf "           ${HEADER}"
}

function list_colors_256 {
## FG Format: <Esc>[38;5;COLORm
## BF Format: <Esc>[48;5;COLORm
for fgbg in 38 48 ; do
	for color in {0..256} ; do
		printf "\e[${fgbg};5;${color}m ${color}\t\e[0m"
		if [ $((($color + 1) % 10)) == 0 ] ; then
			printf "\n"
		fi
	done
	printf "\n"
done
}

##### Inserts a flag with the specified content
# Usage: flag "comment"
# If no comment, inserts the date.
function flag(){
	local message=""
	local -i width_head
	local -i width_tail

	if [ "$1" == "" ]; then
		message="[======  $(date +'%A -- %B %e, %Y -- %I:%M%P')  ======]"
	else
		message="[======  $@  ======]"
	fi

	width_head=$(( (${COLUMNS} - ${#message}) / 2 ))
	width_tail=$(( ${width_head} ))

	if [[ $(((${width_tail} + ${width_head}) + ${#message})) -gt $((${COLUMNS} -1)) ]]; then
		width_tail=$((${width_tail} - 1))
	fi

	printf "%b\n" "\n\n ${InvWhite}$(seq -s ' ' $((${COLUMNS} - 1)) | sed 's/[0-9]//g')${Color_Off}"

	printf "%b" " ${InvYellow}$(seq -s ' ' ${width_head} | sed 's/[0-9]//g')"
	printf "%b" "${InvWhite}${message}"
	printf "%b\n" "${InvYellow}$(seq -s ' ' ${width_tail} | sed 's/[0-9]//g')${Color_Off}"

	printf "%b\n" " ${InvWhite}$(seq -s ' ' $((${COLUMNS} - 1 )) | sed 's/[0-9]//g')${Color_Off}"
}

function center_line {
	local retval=""
	retval=$(printf "$*" | awk -v M="$COLUMNS" '{ printf "%*s%*s", (M+length)/2, $0, (M-length+1)/2+1, "" }')
	printf "%s" "${retval}"
}

function boxit() {
#t="$1xxxx";c=${2:-#};
t="$1xxxx";c=${2:-▓};
	echo "${t//?/$c}
$c $1 $c
${t//?/$c}"
}

function rtrim() {
	local var=$@
	var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
	echo -n "$var"
}

function ltrim() {
	local var=$@
	var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
	echo -n "$var"
}

function trim() {
	local var=$@
	var=$(ltrim "${var}")
	var=$(rtrim "${var}")
	echo -n "$var"
}

function length() {
    if [ $# -ne 1 ]; then
        echo "Usage: length word"
        return 1
    fi
    echo ${#1}
}

function replace(){
	# replace part of string with another
    if [ $# -ne 3 ]; then
        echo "Usage: replace string substring replacement"
        return 1
    fi
    echo ${1/$2/$3}
}

function replaceAll(){
# replace all parts of a string with another
    if [ $# -ne 3 ]; then
        echo "Usage: replace string substring replacement"
        return 1
    fi
    echo ${1//$2/$3}
}

function instr() {
	# find index of specified string
    if [ $# -ne 2 ]; then
        echo "Usage: index string substring"
        return 1
    fi
    expr index $1 $2
}

function toupper() {
	# Upper-case
    if [ $# -lt 1 ]; then
        echo "Usage: upper word"
        return 1
    fi
    echo ${@} | tr '[:lower:]' '[:upper:]'
}

function tolower() {
	# Lower-case
    if [ $# -lt 1 ]; then
        echo "Usage: lower word"
        return 1
    fi
    echo ${@} | tr '[:upper:]' '[:lower:]'
}

function to_roman() {
	echo ${1} | sed -e 's/1...$/M&/;s/2...$/MM&/;s/3...$/MMM&/;s/4...$/MMMM&/
		s/6..$/DC&/;s/7..$/DCC&/;s/8..$/DCCC&/;s/9..$/CM&/
		s/1..$/C&/;s/2..$/CC&/;s/3..$/CCC&/;s/4..$/CD&/;s/5..$/D&/
		s/6.$/LX&/;s/7.$/LXX&/;s/8.$/LXXX&/;s/9.$/XC&/
		s/1.$/X&/;s/2.$/XX&/;s/3.$/XXX&/;s/4.$/XL&/;s/5.$/L&/
		s/1$/I/;s/2$/II/;s/3$/III/;s/4$/IV/;s/5$/V/
		s/6$/VI/;s/7$/VII/;s/8$/VIII/;s/9$/IX/
		s/[0-9]//g'
}

function ls_groups() {
	#ls the groups of files/dirs
	ls -l --group-directories-first ${@} | grep -v ^total | gawk '{print $9, "Group ->", $4}' | column -t
}

function ls_users() {
	#ls the owners of files/dirs
	ls -l --group-directories-first "$@" | grep -v ^total | gawk '{print $9, "User ->", $3}' | sed -e '1d' | column -t
}

function ls_perms() {
	#ls the perms of files/dirs
	if [[ ! "$@" == "" ]]; then
		for file in "$@"; do
			stat -c "%A %a %n" "$file" | gawk '{print $3, "->", $1, "("$2")"}'
		done | column -t
	fi
}

function reload_bash() {
	builtin unalias -a
	builtin unset -f $(builtin declare -F | sed 's/^.*declare[[:blank:]]\+-f[[:blank:]]\+//')
	source "${currBashrc}"
}

function mkcd() {
# Make a directory and change to it
  if [ $# -ne 1 ]; then
         echo "Usage: mkcd <dir>"
         return 1
  else
         mkdir -p "$@" && cd "$_"
  fi
}

function cdls() {
# cd to a directory and ls
    cd "$@" && ls -ltr
}


function errno() {
	# Display ENAME corresponding to number
	# or all ENAMEs if no number specified.

	# License: LGPLv2

	[ $# -eq 1 ] && re="$1([^0-9]|$)"
	echo "#include <errno.h>" |
	cpp -dD -CC | #-CC available since GCC 3.3 (2003)
	grep -E "^#define E[^ ]+ $re" |
	sed ':s;s#/\*\([^ ]*\) #/*\1_#;t s;' | column -t | tr _ ' ' | #align
	cut -c1-$(tput cols) #truncate to screen width
}

function tip() {
	local blah=1
	local retval=""
	while [ $blah -gt 0 ]
	do
		whatis $(ls /bin/ -p1 2> /dev/null | grep -v ^l | grep -v / | shuf -n 1) 2> /dev/null
		blah=$?
	done
}

function ls_reg() {
	\ls $1 -l 2> /dev/null | grep -v '^[ld]\|^total' | gawk '{print $9}'
}
function ls_hid() {
	\ls $1 -ld .[^.]* 2> /dev/null | grep -v '^[ld]\|^total' | gawk '{print $9}'
}
function ls_dirs() {
	\ls $1 -l 2> /dev/null | grep -v '^[l-]\|^total' | gawk '{print $9}'
}
function ls_dirshid() {
	\ls $1 -l 2> /dev/null | grep -v ^[ld] | grep -v ^total | gawk '{print $9}'
}
function ls_exe() {
	\ls $1 -l 2> /dev/null | grep -v ^[ld] | grep -v ^total | gawk '{print $9}'
}

function confirm( )
{
local response
#alert the user what they are about to do.
echo "About to $@....";
#confirm with the user
read -r -p "Are you sure? [y/N]" response
case "$response" in
    [yY][eE][sS]|[yY]) 
              #if yes, then execute the passed parameters
               "$@"
               ;;
    *)
              #Otherwise exit...
              echo "Cancelled."
              ;;
esac
}

#################
## Basic Stuff ##
#################

# Test for Fortune and run it (games is ubuntu, bin is arch)
if [[ "$PS1" ]] ; then
        if [[ -x /usr/games/fortune ]]; then
                echo -e "\n${Yellow}$(/usr/games/fortune -sa)${Color_Off}"
        elif [[ -x /usr/bin/fortune ]]; then
                echo -e "\n${Yellow}$(/usr/bin/fortune -sa)${Color_Off}"
        fi
fi

# set an ugly prompt (non-color, overwrite the one in /etc/profile)
PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '

#coloring LESS
export LESS=-IR
export LESS_TERMCAP_me=$(printf '\e[0m')
export LESS_TERMCAP_se=$(printf '\e[0m')
export LESS_TERMCAP_ue=$(printf '\e[0m')
export LESS_TERMCAP_mb=$(printf '\e[1;32m')
export LESS_TERMCAP_md=$(printf '\e[1;34m')
export LESS_TERMCAP_us=$(printf '\e[1;32m')
export LESS_TERMCAP_so=$(printf '\e[1;44;1m')

# Set a MySQL prompt (if MySQL or MariaDB is installed)
if [ $(length "$(which mysql 2> /dev/null)") -gt 0 ]; then
	export MYSQL_PS1="\nTime : \w  \r:\m\P \nHost : \h:\p\nUser : \U \nDB   : \d\n     > "
fi

#################
## Color Stuff ##
#################

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
#PROMPT_COMMAND="history -a"
PROMPT_COMMAND=prompt_small

function prompt_small {
   if [ $(id -u) -eq 0 ]; then
      PS1="${debian_chroot:+($debian_chroot)}\n\[$BWhite\][\[$Yellow\]\@\[$BWhite\]] [\[$Red\]\u\[$Purple\]@\h\[$BWhite\]] [\[$IBlue\]\w\[$BWhite\]]\[$Color_Off\]\n\$ "
   else
      PS1="${debian_chroot:+($debian_chroot)}\n\[$BWhite\][\[$Yellow\]\@\[$BWhite\]] [\[$Green\]\u\[$Purple\]@\h\[$BWhite\]] [\[$IBlue\]\w\[$BWhite\]]\[$Color_Off\]\n\$ "
   fi
   unset PROMPT_COMMAND
}

# Try to keep environment pollution down, EPA loves us.
unset safe_term match_lhs

#############
## Aliases ##
#############

if [ $(length "$(which grc 2> /dev/null)") -gt 0 ]; then
	alias ping='grc ping -c 4'
	alias netstat='grc netstat'
	alias traceroute='grc traceroute'
	alias mount='grc mount'
	alias ps='grc ps'
	alias lsof='grc lsof'
else
	alias ping='ping -c 4'
fi

if [ $(length "$(which vdir 2> /dev/null)") -gt 0 ]; then
	alias vdir='vdir --color=auto'
fi

if [ $(length "$(which colordiff 2> /dev/null)") -gt 0 ]; then
	alias diff='colordiff'
fi

alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias grep='grep --color=auto'

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias dir='ls -la'
alias df='df -h'
alias cls=clear
alias ?='echo'
alias functions='declare -F | cut -d " " -f3 | grep -v ^_ | sort | less'
alias ducks='find . -maxdepth 1 -mindepth 1 -print0 | xargs -0 -n1 du -ks 2> /dev/null | sort -rn | head -$((LINES - 10)) | cut -f2 | xargs du -hs 2> /dev/null'
alias dirsize="sudo du -h / | grep -P '^[0-9\.]+G'"

alias ls='\ls --color=auto --human-readable --group-directories-first --classify'

case "${BaseOS}" in
	Darwin )
		alias perm='stat -f "%7Op %Sp%t%Su %SHp%t%Sg %SMp%tother %SLp%t%SN%ST"'
		alias ls='\ls -FhGA'
		alias diff='diff -y'
		export CLICOLOR=1
		export LSCOLORS=GxFxCxDxBxegedabagaced
		alias start='open -a Finder ./'
		alias flushDNS='dnscacheutil -flushcache'
	;;
	Linux )
		alias perm='stat --printf "%a %A %G %U %n\n"'
		if [ $(length "$(which gedit 2> /dev/null)") -gt 0 ]; then
			alias gedit='gedit &'
		fi
	;;
esac

if [ $UID -ne 0 ]; then
	case "${BaseOS}" in
		Darwin | Linux )
			alias reboot='sudo reboot'
			alias shutdown='confirm sudo shutdown -t 2 now -h'
			alias nanobash='sudo nano ${currBashrc} -Y sh'
		;;
		WSL )
			export DISPLAY="localhost:0.0"
			export NO_AT_BRIDGE=1
			export LIBGL_ALWAYS_INDIRECT=1
			alias nanobash='sudo nano ${currBashrc} -Y sh'
	esac

	case "${Distro}" in

		MacOS )
			alias updatedb='sudo /usr/libexec/locate.updatedb'
		;;
		CygWin* )
			alias sudo='echo -e "\nSudo is not available in CygWin. Use sudo-s instead."'
			alias sudo-s='/usr/bin/cygstart --action=runas /usr/bin/mintty -e /usr/bin/bash --login'
		;;
		*buntu* | *Mint* | *ingu* | *etrunne* | *lementar* | *Debia*)
			alias update='sudo apt-get update && sudo apt-get upgrade'
			alias dist-upgrade='sudo apt-get update && sudo apt-get dist-upgrade'
			alias install='sudo apt-get install'
			alias autoremove='sudo apt-get autoremove'
		;;
		*edora* )
			alias update='sudo dnf update'
			alias install='sudo dnf install'
			alias nanobash='sudo nano /etc/profile.d/bash.sh --syntax=sh -w'
		;;
		*Cent* | *Hat* | *oror* | *udunt* | *cientifi* )
			alias update='sudo yum upgrade'
       			alias install='sudo yum install'
			alias nanobash='sudo nano /etc/profile.d/bash.sh --syntax=sh -w'
		;;
		*Arch* | *anjar* | *ntergo* )
			alias shutdown='confirm sudo shutdown now -h'
			alias update='sudo pacman -Syu'
			alias install='sudo pacman -S'
			alias yogurt=yaourt
			alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'
			alias nanogrub='sudo nano /etc/default/grub'
		function reflect_mirrors() {
sudo bash -c 'wget -O /etc/pacman.d/mirrorlist.backup https://www.archlinux.org/mirrorlist/all/ && cp /etc/pacman.d/mirrorlist.backup /etc/pacman.d/mirrorlist && reflector --verbose --country "United States" -l 200 -p http --sort rate --save /etc/pacman.d/mirrorlist'
		}
		;;
	esac
fi

################
## My Prompt  ##
################
if [[ -f ~/mobprompt.sh ]]; then
	source ~/mobprompt.sh ]]
	alias nanoprompt='nano ~/mobprompt.sh --syntax=sh -w'
elif [[ -f /shared/etc/mobprompt.sh ]]; then
	source /shared/etc/mobprompt.sh
	alias nanoprompt='sudo nano /shared/etc/mobprompt.sh --syntax=sh -w'
elif [[ -f /etc/mobprompt.sh ]]; then
	source /etc/mobprompt.sh
	alias nanoprompt='sudo nano /etc/mobprompt.sh --syntax=sh -w'
fi

