# repairXapianIndex
Sometimes the EPrints Xapian database for quick search gets corrupted. Tools and a short description for fixing the corruption are offered here.

## Necessary if ...
- the repo's "simple search" does not provide satisfactory results or system errors (Error 500, Service not available), or certain abstracts (and probably also the other metadata) are no longer indexed, even though they actually exist.
- newly entered eprints no longer appear in the search.
- messages from users tell you that the search for certain terms no longer works properly.
- a tool called xapian-check warns you about corrupted databases.

## What you need
- xapian-check, which is part of xapian-core (https://xapian.org/download)

## Overview

* First of all you should regularly do a *backup* of the Xapian database and also *check* once, twice, ... a day its integrity via cronjob on the DB servers.
* For this we offer a backup script (bin/custom/xapiandump.sh) and a perl script to disable the Xapian database during backup (bin/custom/xapianopenclose). The backup script does a xapian-check and creates a gziped tarball, if the check is ok. Otherwise xapian-check tells you "corrupted database" and your last tarball is your life vest.
* If the database is corrupt or any of the other points in "Necessary if..." is true, go ahead on "Restore the Xapian database"
* You must decide, whether you want to make a full reindex, or do a restore of the tarball and then a partial reindex that indexes the missing eprints that were added to the repo in the time between when the corruption happened and now. The partial indexing can be carried out with a separate perl script (bin/custom/restore_xapianindex).

## Examine the Xapian database
 
````
/{path_to_bin}/xapian-check /{eprints_root}/archives/{repo}/var/xapian/
````

Note: At UZH we are doing this twice a day via cronjob on the DB servers; it is part of the backup cronjob.
````
# cronjob - check and backup Xapian DB twice a day
01 12 * * * /{eprints_root}/bin/custom/xapiandump.sh
01 21 * * * /{eprints_root}/bin/custom/xapiandump.sh
````

## Restore the Xapian database

Start working on your DB server:

````
cd /{backup_dir}
gunzip {repo}-xapian-{hostname}.tar.gz
tar -xvf {repo}-xapian-{hostname}.tar
````

Check the consistency of the backup for safety reasons:

````
/{path_to_bin}/xapian-check /{backup_dir}/xapian/
````

Decide now
- If the backup is ok, it can be restored followed by a partial reindex run.
- If the backup is NOT ok, you must carry out a full reindex run.

## Partial Reindex Run

- stop indexer and httpd processes
- restore files from backup:
````
cd /{backup_dir}/xapian/
cp * /{eprints_root}/archives/{repo}/var/xapian/.
````
- restart indexer and httpd processes
- index the remaining eprints in the live archive from last backup until now (doing on your DB server):
````
sudo -u {apache_process_user} /{eprints_root}/bin/custom/restore_xapianindex {repo} --verbose
````

## Full Reindex Run

First, delete all databases:
````
rm /{eprints_root}/archives/{repo}/var/xapian/*
````

Then carry out the reindex on the respective DB server (we recommend to do this in a ````screen```` session):
````
sudo -u {apache_process_user} /{eprints_root}/bin/epadmin reindex {repo} subject
sudo -u {apache_process_user} /{eprints_root}/bin/epadmin reindex {repo} eprint
````

Note: A full reindex run can take a very very long time! E.g., the runtime at zora.uzh.ch is about 8-10 days, processing approximately 12,000 eprints per day. The current number of eprints in your system can be viewed at https://_your_repo_/cgi/counter under "Archive".

