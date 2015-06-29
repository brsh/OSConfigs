bash.bashrc - default bash configuration (incl. prompt - execute as prompt_small from command line)

	Arch/Ubuntu
		For single users: Place in ~ as .bashrc
		For all users: Place in /etc as bash.bashrc (note - rm ~/.bashrc)

	Fed/Cent/RH
		For all users: Place in /etc/profile.d as bash.sh (chmod +x)
	
	Mac
		For all users: Place in /etc/ as bashrc (so /etc/bashrc)
	
	Alias for editing: nanobash
	
	Global Functions
		list_colors - print 16 color palette with esc codes
		list_colors_256 - print 256 color palette with esc codes
		flag - prints a flag (with date or specified text)
		boxit - simple text with box around it
		rtrim - remove spaces at the right
		ltrim - remove spaces at the left
		trim - remove spaces at the right and left (both rtrim and ltrim)
		length - print the length of a string
		remove - replaces text in a string with different text
		removeALL - replaces all instances of text in a string with different text
		instr - returns the index of the first occurance of text in string
		toupper - upper cases the string
		tolower - lower cases the string
		to_roman - converts number to roman numeral
		ls_groups - ls with group "owner"
		ls_users - ls with user "owner"
		ls_perms - ls with octal perms
		reload_bash - resource bash.bashrc (and, hence, mobprompt.sh if present)
		cdls - change to and list the contents of a directory
		errno - print the err text for a specified number
		
		
modprompt.sh - big prompt - lots of info (default, but execute as prompt_big from command line)
	Designed to be placeable in several locations:
		~ - sourced first - overrides any "global" mobprompt.sh
		/etc - sourced last, useful to be available to all users
		/shared/etc - sourced second to last, useful for multiple distros/single system
		
	Alias for editing: nanoprompt
		automactically edits the "live" version (with sudo prompt if necessary)
