#!/usr/bin/env bash


## Config
confDir='/nvchecker'
confFile="${confDir}/nvchecker.toml"
confEmail="${confDir}/email.toml"
User=${USERNAME:-"nvchk"}
Group=${GROUPNAME:-"nvchk"}


## Alias
runUser="runuser --user $User --"


## Functions
_intro () {
	declare -a grtr
	grtr+=( '╔════════════════════════════════════════════════════════════════╗' )
	grtr+=( '║       _  _  _  _  ___  _   _  ____  ___  _  _  ____  ____      ║' )
	grtr+=( '║      ( \( )( \/ )/ __)( )_( )( ___)/ __)( )/ )( ___)(  _ \     ║' )
	grtr+=( '║       )  (  \  /( (__  ) _ (  )__)( (__  )  (  )__)  )   /     ║' )
	grtr+=( '║      (_)\_)  \/  \___)(_) (_)(____)\___)(_)\_)(____)(_)\_)     ║' )
	grtr+=( '║                ____  __  __    __    ____  __                  ║' )
	grtr+=( '║               ( ___)(  \/  )  /__\  (_  _)(  )                 ║' )
	grtr+=( '║                )__)  )    (  /(__)\  _)(_  )(__                ║' )
	grtr+=( '║               (____)(_/\/\_)(__)(__)(____)(____)               ║' )
	grtr+=( '║                                                                ║' )
	grtr+=( '║          https://github.com/lapicidae/nvchecker-email          ║' )
	grtr+=( '╚════════════════════════════════════════════════════════════════╝' )

	printf '%s\n' "${grtr[@]}"
	printf '\n'
	printf '┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄⚟ Settings ⚞┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄\n'
	printf '%-26s%s\n' 'Timezone:' "$TZ"
	if [ -n "$PUID" ]; then
		printf '%-26s%s\n' 'User ID:' "$PUID"
	fi
	if [ -n "$PGID" ]; then
		printf '%-26s%s\n' 'Group ID:' "$PGID"
	fi
	if [ -n "$APK_ADD" ]; then
		printf '%-26s%s\n' 'apk add:' "$APK_ADD"
	fi
	if [ -n "$CRON_SCHEDULE" ]; then
		if [ "$CRON_HUMAN" != 'false' ]; then
			printf '%-26s%s (%s)\n' 'Cron Time:' "$CRON_SCHEDULE" "$(cron-human "$CRON_SCHEDULE")"
		else
			printf '%-26s%s\n' 'Cron Time:' "$CRON_SCHEDULE"
		fi
	fi
	printf '┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄\n'
}


_initTZ () {		# set/change timezone
	if [ -r "/usr/share/zoneinfo/$TZ" ]; then
		CURRENT_TZ=$(readlink /etc/localtime)
		if [[ ! $CURRENT_TZ =~ $TZ ]]; then
			unlink /etc/localtime
			ln -s "/usr/share/zoneinfo/$TZ" /etc/localtime
			echo "$TZ" >/etc/timezone
			printf 'New timezone %s set!\n' "$TZ"
		fi
	fi
}


_chngCron () {		# change time of cronjob
	if [ -n "$1" ]; then
		local command=$1
		local user=${3:-"nvchk"}
		local group=${4:-"$user"}
		local tmpCron
		
		tmpCron=$(mktemp -t 'crontab.XXXXXX')

		crontab -u "$user" -l > "$tmpCron"
		mapfile -d ' ' -t ctab_old < <(grep -E "\b$command(\s|$)" "$tmpCron" | tr -d '\n')

		if [[ "${ctab_old[0]}" = '@'* ]]; then
			ctab_schedule="${ctab_old[0]}"
			ctab_command="${ctab_old[*]:1}"
		else
			ctab_schedule="${ctab_old[*]:0:5}"
			ctab_command="${ctab_old[*]:5}"
		fi

		if [ -z "$ctab_command" ] || [ -z "$ctab_schedule" ]; then
			return 0
		fi

		local time="${2:-"$ctab_schedule"}"		# use $ctab_schedule if $2 is empty

		if [ "$time" != "$ctab_schedule" ]; then
			printf '%s crontab: set start to %s\n' "$command" "$time"
			sed -i "/$command/d" "$tmpCron"
			echo "$time $ctab_command" >> "$tmpCron"
			chown "$user":"$group" "$tmpCron"
			crontab -u "$user" "$tmpCron"
		# else
		# 	printf '%s crontab: desired (%s) and current (%s) start time are identical\n' "$command" "$time" "$ctab_schedule"
		fi

		rm -f "$tmpCron"
	fi
}


_apkAdd () {
	apk -q update
	mapfile -td ',' apk < <(printf '%s' "$@")
	for app in "${apk[@]}"; do
		if ! apk -q info --installed "$app"; then
			if apk -q info --size "$app" &>/dev/null; then
				printf 'Installer: %s will be installed\n' "$app"
				apk add --no-cache --upgrade "$app"
			else
				printf 'Installer: %s is not available\n' "$app"
			fi
		elif apk -q info --installed "$app"; then
			printf 'Installer: "%s" is already installed\n' "$app"
		fi
	done
}


## Profit!
_intro

if [ -n "$APK_ADD" ]; then
	printf '\n┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄⚟ Installer ⚞┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄\n'
	_apkAdd "$APK_ADD"
fi


printf '\n┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄⚟ Initialising ⚞┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄\n'

_initTZ

if [ -n "$PUID" ] && [ "$PUID" != "$(id -u "$User")" ]; then
	printf 'Change ID of user %s to %s\n' "$User" "$PUID"
	usermod --non-unique --uid "$PUID" "$User"
fi

if [ -n "$PGID" ] && [ "$PGID" != "$(id -g "$Group")" ]; then
	printf 'Change ID of group %s to %s\n' "$Group" "$PGID"
	groupmod --non-unique --gid "$PGID" "$Group"
fi

if [ ! -d "$confDir" ]; then
	printf 'Folder "%s" does not exist and is therefore created\n' "$confDir"
	mkdir -p "$confDir"
fi

if [ ! -e "$confFile" ]; then
	printf 'File "%s" does not exist, the default file is used\n' "$confFile"
	cp -n /defaults/nvchecker.toml "$confFile"
fi

if [ ! -e "$confEmail" ]; then
	printf 'File "%s" does not exist, the default file is used\n' "$confEmail"
	cp -n /defaults/email.toml "$confEmail"
fi

chown -R "${User}:${Group}" "$confDir"

# first run
newverFile=$(yq '.__config__.newver' "$confFile")
oldverFile=$(yq '.__config__.oldver' "$confFile")

if [ ! -e "$newverFile" ]; then
	printf 'File "%s" missing execute "nvchecker"\n' "$newverFile"
	$runUser nvchecker --file "$confFile" --tries 1 --logging error
fi

if [ ! -e "$oldverFile" ]; then
	printf 'File "%s" missing execute "nvtake --all"\n' "$oldverFile"
	$runUser nvtake --file "$confFile" --all
fi


printf '\n┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄⚟ Prepare ⚞┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄\n'

$runUser nvchecker --file "$confFile" --tries 1 --logging error

if nvcmp --file "$confFile" | grep -qi none; then
	mapfile -t nameARR < <( nvcmp --file "$confFile" | grep -i none | cut -d ' ' -f 1 )
	for n in "${nameARR[@]}"; do
		printf  '%s: update version records' "$n"
		$runUser nvtake --file "$confFile" "$n"
	done
fi

# cronjobs
if [ -n "$CRON_SCHEDULE" ]; then
	_chngCron 'nvchecker-email' "$CRON_SCHEDULE"
fi


printf '\n┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄⚟ Start %s ⚞┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄\n' "${1//[[:blank:]]/}"

exec "$@"
