Updates /etc/motd with "current stats"

Recommend placing in root's crontab as follows:
	*/5 * * * * /usr/local/bin/system_stats.sh
	@reboot /usr/local/bin/system_stats.sh
