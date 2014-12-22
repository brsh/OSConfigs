Updates /etc/motd with "current stats"

Recommend placing in root's crontab as follows:<br>
```
	*/5 * * * * /usr/local/bin/system_stats.sh<br>
	@reboot /usr/local/bin/system_stats.sh
```
