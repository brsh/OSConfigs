#!/bin/bash 
memfree=`free -m | head -n 2 | tail -n 1 | awk {'print $4'}`
memtotal=`free -m | head -n 2 | tail -n 1 | awk {'print $2'}`
load=`cat /proc/loadavg | awk {'print $3 * 100'}`
cpus=`cat /proc/cpuinfo | grep processor | wc -l | awk '{print $1}'`
cpu_type=`cat /proc/cpuinfo | grep model | tail -n 1  | sed -e 's/(R)//' -e 's/(TM)//' -e 's/model name	: //'`
loggedin=`echo 'UserName              Terminal       Time Logged In' && who | awk '{ printf "  %-18s   %-9s    %s %s\n", $1, $2, $3, $4 ; }' `
distro='Distro  = '
dist=`uname -s`
if [[ -r '/etc/lsb-release' ]]; then
  dist=`lsb_release -dcs | sed -e 's/\"//g' -e '{:q;N;s/\n/ /g;t q}'`
fi
echo " 
System Summary for `hostname -f`
** Collected `date '+%a, %D, %r'` **

Load    =  $load%
Uptime  =  `uptime -p | sed 's/up //g'`
Memory  =  `printf "%'d" $memfree`Mb free / `printf "%'d" $memtotal`Mb total
$distro $dist
Kernel  =  `uname -sr` 
IP      =  `ip addr show | grep global | awk '{print $2}'`
CPU     =  $cpus - $cpu_type

`df -hl --exclude-type=tmpfs --exclude-type=devtmpfs`

$loggedin

Recent Boot History
`last reboot | head -n 4 | sed s/reboot\ //`
" > /etc/motd
unset memfree load dist distro memtotal cpus cpu_type loggedin
