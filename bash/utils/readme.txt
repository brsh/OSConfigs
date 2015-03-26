"Handy" scripts I use around the various distros. For simplicity, I keep these in

		/usr/local/bin

but you can keep them wherever you feel most comfortable.
	(Note: the Data folder goes in ~)


Main Folder:

	GetTime.sh - Cheesy clock script
		Just displays the time in a couple locations


	calendar.sh - Display last, current, and next months
		Takes the output of the cal command, adds color


	system_stats.sh - System information and stats
		Designed for quick get of key system info
		Can be used in cron job to write to /etc/motd
			(for display on SSH'ing into system)
		Looks for ~\data\dates.txt with "extra" countdown dates
			X days until the next...

		Add to root's crontab as:

			*/5 * * * * /usr/local/bin/system_stats.sh auto
			@reboot /usr/local/bin/system_stats.sh auto


lib folder

	lib_colors.sh - color and display definitions
		Called by the scripts for ansi colors

	lib_time - Time math
		Um... time math


Data
	dates.txt - collection of dates for system_stats
		Any date here will be listed in the days until section

		Format is: 
			event,MM/DD/YEAR-HH-mm

		(capped MM is month; lower mm is minutes)
