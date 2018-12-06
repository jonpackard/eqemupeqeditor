#!/bin/bash
########################
# Gets an env. variable name based on the suffix
# Globals:
#   DB_FLAVOR
# Arguments:
#   $1 - env. variable suffix
# Returns:
#   env. variable name
#########################
mkdir -p /var/www/html/logs && chmod 777 /var/www/html/logs && [ -e /var/www/html/logs/* ] && chmod 666 /var/www/html/logs/*
get_env_var() {
    local id="${1:?id is required}"
    echo "${DB_FLAVOR^^}_${id}"
}

########################
# Gets an env. variable value based on the suffix
# Arguments:
#   $1 - env. variable suffix
# Returns:
#   env. variable value
#########################
get_env_var_value() {
    local envVar
    envVar="$(get_env_var "$1")"
    echo "${!envVar:-}"
}

create_config() {
    cat > "/var/www/html/config.php" <<EOF
<?php
\$dbhost = '$DB_HOST';
\$dbuser = '$DB_USERNAME';
\$dbpass = '$DB_PASSWORD';
\$db = '$DB_NAME';
\$mysql_class = 'mysqli'; // Use mysql or mysqli

/*  Limit zone lists to a specified expansion
 *  (i.e. setting $expansion_limit to 2 would cause only Classic and Kunark zones
 *  to appear in zone drop-down lists)
 *    1 = EQ Classic
 *    2 = The Ruins of Kunark
 *    3 = The Scars of Velious
 *    4 = The Shadows of Luclin
 *    5 = The Planes of Power
 *    6 = The Legacy of Ykesha
 *    7 = Lost Dungeons of Norrath
 *    8 = Gates of Discord
 *    9 = Omens of War
 *    10 = Dragons of Norrath
 *    11 = Depths of Darkhollow
 *    12 = Prophecy of Ro
 *    13 = The Serpent's Spine
 *    14 = The Buried Sea
 *    15 = Secrets of Faydwer
 *    16 = Seeds of Destruction
 *    17 = Underfoot
 *    18 = House of Thule 
 *    19 = Veil of Alaris
 *    20 = Rain of Fear
 *    21 = Call of the Forsaken
 *    22 = The Darkened Sea
 *    99 = Other
 */
\$expansion_limit = 22;

// How NPCs are listed. 1 = by NPCID (zoneidnumber*1000), 2 = By spawn2 entry
\$npc_list = 1;

// Spawngroup list limit. Limits how many spawngroups are displayed as result of a Coord/NPC search. Specific NPC lists are not effected.
\$spawngroup_limit = 150;

// Dont want to have to type the username and password every time you start the editor?
// Set the two variables below to the values you want to be in the form when you start it up.
// (default login: admin  pw: password)
\$login = '$LOGIN';
\$password = '$PASSWORD';

// Logs directory location
\$logs_dir = "logs";

// Log SQL queries:  1 = on, 0 = off
\$logging = 1;

// Automatically create new logs monthly.
\$filetime = date("m-Y");
\$log_file = \$logs_dir . "/sql_log_\$filetime.sql";

// Log all MySQL queries (If disabled only write entries are logged - recommended.)
\$log_all = 0;

// Log all MySQL queries that result in an error.
\$log_error = 0;

// Enable or disable user logins.
\$enable_user_login = 1;

// Enable or disable read only guest mode log in.
\$enable_guest_mode = 1;

// Path for quests without trailing slash.
\$quest_path = "/path/to/quests";

// Perl scripts
\$perl_path = "perl";
\$perl_log_file = \$logs_dir . "/perl_log_\$filetime.log";

?>
EOF
}

create_config


#!/bin/bash
set -e

# Note: we don't just use "apache2ctl" here because it itself is just a shell-script wrapper around apache2 which provides extra functionality like "apache2ctl start" for launching apache2 in the background.
# (also, when run as "apache2ctl <apache args>", it does not use "exec", which leaves an undesirable resident shell process)

: "${APACHE_CONFDIR:=/etc/apache2}"
: "${APACHE_ENVVARS:=$APACHE_CONFDIR/envvars}"
if test -f "$APACHE_ENVVARS"; then
	. "$APACHE_ENVVARS"
fi

# Apache gets grumpy about PID files pre-existing
: "${APACHE_RUN_DIR:=/var/run/apache2}"
: "${APACHE_PID_FILE:=$APACHE_RUN_DIR/apache2.pid}"
rm -f "$APACHE_PID_FILE"

# create missing directories
# (especially APACHE_RUN_DIR, APACHE_LOCK_DIR, and APACHE_LOG_DIR)
for e in "${!APACHE_@}"; do
	if [[ "$e" == *_DIR ]] && [[ "${!e}" == /* ]]; then
		# handle "/var/lock" being a symlink to "/run/lock", but "/run/lock" not existing beforehand, so "/var/lock/something" fails to mkdir
		#   mkdir: cannot create directory '/var/lock': File exists
		dir="${!e}"
		while [ "$dir" != "$(dirname "$dir")" ]; do
			dir="$(dirname "$dir")"
			if [ -d "$dir" ]; then
				break
			fi
			absDir="$(readlink -f "$dir" 2>/dev/null || :)"
			if [ -n "$absDir" ]; then
				mkdir -p "$absDir"
			fi
		done

		mkdir -p "${!e}"
	fi
done

exec apache2 -DFOREGROUND "$@"
