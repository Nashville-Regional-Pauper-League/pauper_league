#!/bin/sh

set -e

release=bin/pauper_league

$release eval "PauperLeague.Release.migrate"
echo "Deploy Status: " $?

exec $release start