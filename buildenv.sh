#!/bin/bash

set -e

# Gather inputs
GITREPO=$(readlink -e $(dirname $0)) # The repo base so we can pull files as needed
DESTINATION=${1:-.}
SETTINGS=$(readlink -e ${2:-$GITREPO/settings-prod})
# We do not take a variable settings template, as that would lead to a risk
# of out-of-sync settings for test & deploy envronments

# Install prerequisites
apt-get install -qq -y python3-venv build-essential python3-dev python-setuptools

# Pillow deps
apt-get install -qq -y libtiff5-dev libjpeg62-turbo-dev zlib1g-dev \
	libfreetype6-dev liblcms2-dev libwebp-dev tcl8.5-dev tk8.5-dev \
	python-tk libmysqlclient-dev

# clean up critical files so we can "recreate" the environment without
# actually wiping everything (and incurring an expensive pip download)
rm -rf "$DESTINATION"/pressers_name
rm -rf "$DESTINATION"/manage.py
mkdir -p "$DESTINATION"

# Change to destination
cd "$DESTINATION"

#virtualenv -q .
python3 -m venv .

if [ ! -e lib/python ]
then
    PYPATH=$(ls -d lib/python* | sort | tail -n 1)
    ln -s "$(basename $PYPATH)" "lib/python"
fi

. bin/activate

pip install -q --upgrade -r "$GITREPO"/requirements.txt

# Re-init project
bin/django-admin.py startproject pressers_name .

# And copy in the static data
rsync -qavz "$GITREPO/"payload/* "$DESTINATION"

cat "$SETTINGS" >> ./pressers_name/settings.py

# Disable debug
sed -i 's/DEBUG = True/DEBUG = False/' ./pressers_name/settings.py

# Do not fail if timezone info fails to load
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p`cat ~/mysql-root-pass` mysql | grep -v "Warning: Unable to load" || :

yes | python3 manage.py migrate -v 0 --fake-initial
yes "yes" | python3 manage.py collectstatic
