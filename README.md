## Add credentials as env variables with the script provided by Open Stack

. ./*_project-openrc.sh


## Check env properly loaded

make check-env

## Initialize tofu

make init

## Provide Infrastructure

make apply

## Provide

make destroy

## Rebuild from scratch

make restart