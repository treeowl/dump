#!/bin/bash

set -eu

ver="$1"
user="$2"
# TODO get from keyring
pass="$3"
ret=0



log () {
  echo "# "$@
}

projectName=`ls *.cabal | sed s/.cabal//`

if [ -e "$projectName.cabal" ]; then
  log "Project Name: $projectName"
else
  log "*.cabal file not found, refusing release"
  exit 1
fi


if [ -z "$ver" ]; then
  log "Version not given, refusing release"
  exit 1
fi

if [ -z "$user" ]; then
  log "Username not given, refusing release"
  exit 1
fi

if [ -z "$pass" ]; then
  log "Password not given, refusing release"
  exit 1
fi

# getExitCode () {
#   "$@"
#   echo "$?"
# }


git diff --exit-code >/dev/null || ret=$?
if [ "$ret" -ne 0 ]; then
  git status --short
  log "There are uncommitted changes, refusing release"
  exit 2
fi

git diff --cached --exit-code >/dev/null || ret=$?
if [ "$ret" -ne 0 ]; then
  git status --short
  log "There are uncommitted staged changes, refusing release"
  exit 3
fi

rx="(version:\s+)([0-9\w.-]+)"
oldver=`cat "$projectName.cabal" | grep "^version:" | sed -re "s/$rx/\2/"`

cabal configure
cabal install --enable-test
cabal test

cabal sdist
cabal upload "dist/$projectName-$ver.tar.gz" --username "$user" --password "$pass"
neil docs --username "$user:$pass"

if [ "$ver" != "$oldver" ]; then
  msg="Bumping version v$oldver -> v$ver"
  sed -r -i -e "s/$rx/\1$ver/" "$projectName.cabal"
  git add -u
  git commit -m "$msg"
  log "$msg"
else
  log "Releasing $ver"
fi

git push

if [ ! `git tag -l "v$ver"` ]; then
  git tag "v$ver" HEAD
fi

git push --tags
