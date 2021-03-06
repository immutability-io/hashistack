#!/bin/bash
set -e

logger() {
  DT=$(date '+%Y/%m/%d %H:%M:%S')
  echo "$DT nomad.sh: $1"
}

# For some reason, fetching nomad fails the first time around, so we retry
retry() {
  local n=1
  local max=5
  local delay=15
  while true; do
    "$@" && break || {
      if [ $n -lt $max ]; then
        n=$((n+1))
        # No output on failure to allow redirecting output
        sleep $delay;
      else
        fail "The command has failed after $n attempts."
      fi
    }
  done
}

logger "Executing"

cd /tmp

CONFIGDIR=/ops/$1/nomad
NOMADVERSION=0.4.1
NOMADDOWNLOAD=https://releases.hashicorp.com/nomad/${NOMADVERSION}/nomad_${NOMADVERSION}_linux_amd64.zip
NOMADCONFIGDIR=/etc/nomad.d
NOMADDIR=/opt/nomad

logger "Fetching Nomad"
retry curl -L $NOMADDOWNLOAD > nomad.zip

logger "Installing Nomad"
unzip nomad.zip -d /usr/local/bin
chmod 0755 /usr/local/bin/nomad
chown root:root /usr/local/bin/nomad

logger "Configuring Nomad"
mkdir -p "$NOMADCONFIGDIR"
chmod 0755 $NOMADCONFIGDIR
mkdir -p "$NOMADDIR"
chmod 0777 $NOMADDIR
mkdir -p "$NOMADDIR/data"

# Nomad config
cp $CONFIGDIR/default.hcl $NOMADCONFIGDIR/.

# Upstart config
cp $CONFIGDIR/upstart.nomad /etc/init/nomad.conf

# Nomad join script
cp $CONFIGDIR/nomad_join.sh $NOMADDIR/.
chmod +x $NOMADDIR/nomad_join.sh

logger "Completed"
