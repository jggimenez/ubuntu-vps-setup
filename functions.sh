#!/bin/bash
#======================================================================
# Author:	Jorge Giménez
# Date:		2010-12-13
#======================================================================

#COLORS
GRAY='\e[1;30m'
RED='\e[1;31m'		;
GREEN='\e[1;32m'	;DARK_GREEN='\e[0;32m'
YELLOW='\e[1;33m'	;
BLUE='\e[1;34m'		;
MAGENTA='\e[1;35m'	;
CYAN='\e[1;36m'		;DARK_CYAN='\e[0;36m' 
WHITE='\e[1;37m'	;
RESET='\033[00m'
COLOR=$CYAN		;ERROR=$RED

_write()	{ echo -en $COLOR"$@"$RESET; }
_writeline()	{ echo -e $COLOR"$@"$RESET; }
__error()	{ echo -e $ERROR"$@"$RESET; }
_title() {
	echo -e $GREEN"$1"$RESET
	echo -e $GREEN"======================================================================"$RESET
	[ "$2" != "" ] && echo -e $DARK_GREEN"$2"$RESET
	echo
}
_failcheck() {
	CODE=$?
	if [ $CODE -ne 0 ]; then
		__error $1
		exit $CODE
	fi
}

pause() {
	echo
	echo -en $WHITE
	if [ "$1" != "" ]
		then echo -en $1
		else echo -en "Press ENTER to continue..."
	fi
	echo -en $RESET
	read -t 5 junk
	echo
}

mysql_create_user() {
	# $1 - the mysql root password
	# $2 - the user to create
	# $3 - their password

	if [ ! -n "$1" ]; then
		echo "mysql_create_user() requires the root pass as its first argument"
		return 1;
	fi
	if [ ! -n "$2" ]; then
		echo "mysql_create_user() requires username as the second argument"
		return 1;
	fi
	if [ ! -n "$3" ]; then
		echo "mysql_create_user() requires a password as the third argument"
		return 1;
	fi

	_write "Checking if user \"$2\" exists... "

	exists="`eval "mysql -u root --password='$1' --silent --skip-column-names --execute='SELECT COUNT(*) FROM mysql.user WHERE User='\''$2'\'' AND Host='\''localhost'\'''"`"

	if [ $exists -eq 0 ]; then
		_writeline "no.\n\tCreating..."
		echo "CREATE USER '$2'@'localhost' IDENTIFIED BY '$3';" | eval "mysql -u root --password='$1'"
		_failcheck "user creation failed "
		_writeline "done."
	else
		_writeline "yes."
	fi
}

mysql_grant_user() {
	# $1 - the mysql root password
	# $2 - the user to bestow privileges
	# $3 - the database

	if [ ! -n "$1" ]; then
		echo "mysql_create_user() requires the root pass as its first argument"
		return 1;
	fi
	if [ ! -n "$2" ]; then
		echo "mysql_create_user() requires username as the second argument"
		return 1;
	fi
	if [ ! -n "$3" ]; then
		echo "mysql_create_user() requires a database as the third argument"
		return 1;
	fi

	echo "GRANT ALL PRIVILEGES ON $3.* TO '$2'@'localhost';" | eval "mysql -u root --password='$1'"
	_failcheck "Granting privileges to user '$2' on database '$3' failed."
	echo "FLUSH PRIVILEGES;" | eval "mysql -u root --password='$1'"
	_failcheck "Privilege flush failed."
}
