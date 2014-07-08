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
HISTCONTROL=ignoredups:ignorespace

# Enable history appending instead of overwriting.
shopt -s histappend

# Enable spell-check on directory names with cd command
shopt -s cdspell

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

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

# sudo hint
if [ ! -e "$HOME/.sudo_as_admin_successful" ] && [ ! -e "$HOME/.hushlogin" ] ; then
    case " $(groups) " in *\ admin\ *)
	    if [ -x /usr/bin/sudo ]; then
			cat <<-EOF
			To run a command as administrator (user "root"), use "sudo <command>".
			See "man sudo_root" for details.
	
			EOF
    	fi
    esac
fi

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

#################
## Basic Stuff ##
#################

# Test for Fortune and run it (games is ubuntu, bin is arch)
if [[ "$PS1" ]] ; then
        if [[ -x /usr/games/fortune ]]; then 
                echo -e "$BIYellow";/usr/games/fortune -sa;echo -e "$Color_Off"
        fi
        if [[ -x /usr/bin/fortune ]]; then 
                echo -e "$BIYellow";/usr/bin/fortune -sa;echo -e "$Color_Off"
        fi 
fi

# set an ugly prompt (non-color, overwrite the one in /etc/profile)
 PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '

#Set the window title
case ${TERM} in
	xterm*|rxvt*|Eterm|aterm|kterm|gnome*)
		PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033]0;%s@%s:%s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"'
		;;
	screen)
		PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033_%s@%s:%s\033\\" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/~}"'
		;;
esac

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

   if [ $(id -u) -eq 0 ]; then
      PS1="${debian_chroot:+($debian_chroot)}\n\[$BWhite\][\[$Yellow\]\@\[$BWhite\]] [\[$BRed\]\u\[$BPurple\]@\h\[$BWhite\]] [\[$BIBlue\]\w\[$BWhite\]]\[$Color_Off\]\n\$ "
   else
      PS1="${debian_chroot:+($debian_chroot)}\n\[$BWhite\][\[$Yellow\]\@\[$BWhite\]] [\[$BGreen\]\u\[$BPurple\]@\h\[$BWhite\]] [\[$BIBlue\]\w\[$BWhite\]]\[$Color_Off\]\n\$ "
   fi
fi

PS2="> "
PS3="> "
PS4="+ "

# Try to keep environment pollution down, EPA loves us.
unset safe_term match_lhs

#############
## Aliases ##
#############

alias ls='ls --color=auto --human-readable --group-directories-first --classify'
alias vdir='vdir --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias grep='grep --color=auto'

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

