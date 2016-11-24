#!/bin/bash -e

set -e

# run the rails application
# configure the postgres config based on the env first

export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

${DIR}/../bin/rails s -p 80 -b '0.0.0.0'