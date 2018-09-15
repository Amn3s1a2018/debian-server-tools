#!/bin/bash
#
# Generate instant.dnsbl.zone file and purge old entries.
#
# CRON.D        :*/03 *	* * *	root	/usr/local/sbin/dnsbl-generate.sh

#echo "CREATE TABLE instant ( 'ip' INTEGER PRIMARY KEY ON CONFLICT IGNORE, 'type' INTEGER, 'date' INTEGER );" \
#    | sqlite3 dnsbl.sqlite

SQLITE_DB="/home/instant/website/dnsbl.sqlite"
ZONE_FILE="/var/lib/rbldns/spammer/instant.dnsbl.zone"

if [ ! -r "$SQLITE_DB" ] || [ ! -r "$ZONE_FILE" ]; then
    exit 1
fi

{
    cat <<"EOF"
#### Automatically generated by dnsbl-generate.sh ####

$NS 3600 worker.szepe.net
$TTL 60
:127.0.0.2:Instant blocked IP
EOF

    echo 'SELECT ("ip" >> 24) || "." || (("ip" >> 16) & 255) || "." || (("ip" >> 8) & 255) || "." || ("ip" & 255)
        || " " || "type" || " " || strftime("%Y-%m-%d %H:%M:%S", "date", "unixepoch") || " +0000 # @" || "date" FROM instant;' \
        | sqlite3 -batch -init <(echo ".timeout 1000") "$SQLITE_DB"
} >"$ZONE_FILE"

# Purge old IP-s
echo "DELETE FROM instant WHERE 'date' < $(date -d "1 month ago" "+%s");" \
    | sqlite3 -batch -init <(echo ".timeout 1000") "$SQLITE_DB"

exit 0

# Tests #

Write_lock_test() {
    echo "INSERT INTO instant VALUES
        ( $(( (RANDOM % 256)*256*256*256 + (RANDOM % 256)*256*256 + (RANDOM % 256)*256 + (RANDOM % 256) )),
        $$,
        $(date "+%s") );" \
        | sqlite3 -batch -init <(echo ".timeout 1000") dnsbl.sqlite
}

Run_write_lock_test() {
    echo "DELETE FROM instant;" | sqlite3 dnsbl.sqlite
    echo "INSERT INTO instant VALUES ( $(php -r 'echo ip2long("1.2.3.4");'), 0, $(date "+%s") );" \
        | sqlite3 dnsbl.sqlite
    seq 1 100 | parallel -j 100 ./write-lock.sh
    echo "SELECT * FROM instant;" | sqlite3 dnsbl.sqlite
}
