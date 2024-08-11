#!/bin/bash

source /etc/drumee/drumee.sh 
nodejs $DRUMEE_BACKEND_HOME/build/$USER/offline/db/patch.js $@

