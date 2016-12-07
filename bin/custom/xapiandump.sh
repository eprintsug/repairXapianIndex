#!/bin/bash
#
# create dump-file for xapian-database
# Runs as cronjob on zora@idzora(tp)db01.uzh.ch
#
# Date  : 2016-08-03 jv - check DB, build tarball
#         2016-12-06 jv - build tarball with short path 'xapian/*DB'

###############################################################################
#
# Checks Xapian Database and creates Dump File
# Runs as cronjob by zora@_database_server_.uzh.ch
#
###############################################################################
#
#  Copyright 2016 University of Zurich. All Rights Reserved.
#  
#  The plug-ins are free software; you can redistribute them and/or modify
#  them under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#  
#  The plug-ins are distributed in the hope that they will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with EPrints 3; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
######################################################################

umask 022
dumpdir="/service-backup"
eprints_home="/usr/local/eprints"
current_host=`hostname -s`
repos="jdb zora"

# timestamp
echo "$0 starts (`/bin/date`)"

# stop indexer
sudo -u apache $eprints_home/bin/indexer stop
if [ $? -eq 0 ]
then
	echo "- indexer stopped (`/bin/date`)"
else
	echo "- could not stop indexer - exit"
	exit
fi

for i in $repos
do
	echo "- Ckecking $i"
	/usr/bin/xapian-check $eprints_home/archives/$i/var/xapian/ >/dev/null
	if [ $? -eq 0 ]
	then
		echo "-- xapian-check for $i ok, let's make a dump"
		echo "-- close xapian-db (`/bin/date`)"
		sudo -u apache $eprints_home/bin/custom/xapianopenclose $i close
		cd $eprints_home/archives/$i/var
		echo "-- tar starts (`/bin/date`)"
                /bin/tar -cf $dumpdir/$i-xapian-$current_host.tar xapian 
		echo "-- reopen xapian-db (`/bin/date`)"
		sudo -u apache $eprints_home/bin/custom/xapianopenclose $i open
		echo "-- gzip starts (`/bin/date`)"
                /usr/bin/gzip -f $dumpdir/$i-xapian-$current_host.tar
	else
		echo "-- xapian-check for $i went wrong"
	fi
done

# start indexer
echo "- indexer start (`/bin/date`)"
sudo -u apache $eprints_home/bin/indexer start

# timestamp
echo "$0 ends (`/bin/date`)"

exit
