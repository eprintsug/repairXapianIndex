# repairXapianIndex
Sometimes / somehow eprints' simple search database (Xapian) gets corrupted. Here you'll find tools and a short description howto fix it.

## Necessary if ...
- Repos "simple search" does not provide satisfactory results or system errors (Error 500, Service not available), or certain abstracts (and probably also the other metadata) are no longer indexed, even though they actually exist.
- Newly entered EPrints no longer appear in the search.
- Notes from users tell you, that the search for certain terms no longer works properly.
- A tool called xapian-check is warning about corrupted databases.

## What you need
- xapian-check, which is part of xapian-core (https://xapian.org/download)

## Overview

* First of all you should do a Xapian *backup* AND *check* once, twice, ... a day via cronjob on the DB servers.
* Therefor use the backup script (bin/custom/xapiandump.sh). It does a xapian-check and generates a gziped-tarball, if check is ok. Otherwise xapian-check tells you "corrupted database" and your last tarball is your life vest.
* If database is corrupt or any of the other points in "Necessary if..." is true, go ahead on "Restore the Xapian database"
* You must decide, weather you want to make a full reindex, or do a restore and a partial reindex based on the tarball.

## Examin

````
/_path_to_bin_/xapian-check /_path_to_eprints_home_/archives/_repo_name_/var/xapian/
````

Note: At UZH we're doing this twice a day via cronjob on the DB servers; it is part of the backup cronjob.
````
# cronjob - check and backup Xapian DB twice a day
01 12 * * * /_path_to_eprints_home_/bin/custom/xapiandump.sh
01 21 * * * /_path_to_eprints_home_/bin/custom/xapiandump.sh
````

## Restore the Xapian database

Start working on your DB server:

````
cd /_backup_dir_
gunzip _repo_name_-xapian-_hostname_.tar.gz
tar -xvf _repo_name_-xapian-_hostname_.tar
````

Double check the consistency of the backup for security reasons:

````
/_path_to_bin_/xapian-check /_backup_dir_/xapian/
````

Decide now
- If the backup is ok, it can be restored followed by a partial reindex.
- If the backup is NOT ok, you have to do a full reindex.

## Full Reindex

Previously delete all databases:
````
rm /_path_to_eprints_home_/archives/_repo_name_/var/xapian/*
````

Then start and reindex on the respective DB server:
````
sudo -u _apache_process_user_ /_path_to_eprints_home_/bin/epadmin reindex _reponame_ subject
sudo -u _apache_process_user_ /_path_to_eprints_home_/bin/epadmin reindex _reponame_ eprint
````

Note: Full reindex could need a very very long time! E.g. the runtime at zora.uzh.ch is about 8-10 days, processing approximately 12,000 eprints per day. The current number of EPrints in your system can be viewed at https://_your_repo_/cgi/counter under "Archive".

## Partial Reindex

- stop indexer and httpd processes
- delete all databases and restore files from backup:
````
cd /_backup_dir_/xapian/
rm /_path_to_eprints_home_/archives/_repo_name_/var/xapian/*
cp * /_path_to_eprints_home_/archives/_repo_name_/var/xapian/.
````
- restart indexer and httpd processes
- index the remaining eprints in the live archive from last backup until now (doing on your DB server):
````
sudo -u _apache_process_user_ /_path_to_eprints_home_/bin/custom/restore_xapianindex _reponame_ --verbose
````



