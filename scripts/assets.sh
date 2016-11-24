#!/bin/bash -e

set -e

# runs the initialization script for the database
# SHOULD BE RUN ONLY ONCE AND MANUALLY
#
# if you are setting up the database for development and want seed data inserted
# set the DEV_SEED=1 variable

export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/vars.sh

echo "building the assets"
${DIR}/../bin/rake assets:precompile