#!/bin/bash

# Note: see /usr/share/zoneinfo/ for TZ info

function india-time {
	# Roughly India...
	TZ=Asia/Calcutta date "+%a %_I:%M%P (India)"
}

function dayton-time {
	#Eastern Time Zone
	TZ=America/New_York date "+%a %_I:%M%P (Dayton)"
}

function loc-time {
	date "+%a %_I:%M%P"
}

case "${1}" in
	I* | i* )
		india-time
	;;
	D* | d* )
		dayton-time
	;;
	A* | a* )
		loc-time
		dayton-time
		india-time
	;;
	* )
		loc-time
	;;
esac

