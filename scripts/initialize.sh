#!/bin/bash -e

set -e

# runs the initialization script for the database
# SHOULD BE RUN ONLY ONCE AND MANUALLY
#
# if you are setting up the database for development and want seed data inserted
# set the DEV_SEED=1 variable

export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/vars.sh

echo "initializing the database"
${DIR}/../bin/rake db:setup

if [ -n "$DEV_SEED" ]; then
  ${DIR}/../bin/rake db:dev_seed
fi