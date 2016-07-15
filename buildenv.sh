#!/bin/bash

set -xe

# Gather inputs
GITREPO=$(readlink -e $(dirname $0)) # The repo base so we can pull files as needed
DESTINATION=${1:-.}
SETTINGS=$(readlink -e ${2:-$GITREPO/settings-prod})
DEST_EXISTS=$(test -e "$DESTINATION"; echo $?)
# We do not take a variable settings template, as that would lead to a risk
# of out-of-sync settings for test & deploy envronments

# Install prerequisites
apt-get install -y virtualenv build-essential python-dev python-setuptools

# Pillow deps
apt-get install -y libtiff5-dev libjpeg62-turbo-dev zlib1g-dev \
	libfreetype6-dev liblcms2-dev libwebp-dev tcl8.5-dev tk8.5-dev \
	python-tk libmysqlclient-dev

# Change to our destination
mkdir -p "$DESTINATION"
cd "$DESTINATION"

virtualenv .
. bin/activate

pip install --upgrade -r "$GITREPO"/requirements.txt

# Add the django shell, if not there already
if [ ! -e "$DESTINATION"/manage.py ]
then
	bin/django-admin.py startproject pressers_name .
fi

# And copy in the static data
rsync -avz "$GITREPO/"payload/* "$DESTINATION"

if [ $DEST_EXISTS != 0 ]
then
	cat "$SETTINGS" >> ./pressers_name/settings.py
fi

mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p`cat ~/mysql-root-pass` mysql

yes | ./manage.py migrate --fake-initial
yes "yes" | ./manage.py collectstatic
