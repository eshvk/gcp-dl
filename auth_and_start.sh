#!/bin/bash
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

set -e

# get service account auth info
service_account_email=`lookup_value_from_json $GOOGLE_APPLICATION_CREDENTIALS client_email`
service_account_project=`lookup_value_from_json $GOOGLE_APPLICATION_CREDENTIALS project_id`

# Handle special flags if we're root
if [ $UID == 0 ] ; then
    # Change UID of NB_USER to NB_UID if it does not match
    if [ "$NB_UID" != $(id -u $NB_USER) ] ; then
        usermod -u $NB_UID $NB_USER
        chown -R $NB_UID $CONDA_DIR .
    fi

    # Enable sudo if requested
    if [ ! -z "$GRANT_SUDO" ]; then
        echo "$NB_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/notebook
    fi

    # set up auth
    su $NB_USER -c "echo project_id=${service_account_project} >> ${HOME}/.bigqueryrc"
    su $NB_USER -c "env PATH=$PATH gcloud auth activate-service-account ${service_account_email} --key-file=$GOOGLE_APPLICATION_CREDENTIALS"

    # give the notebook user ownership of its home
    chown -R $NB_UID /home/$NB_USER

    # Exec the command as NB_USER
    exec su $NB_USER -c "env PATH=$PATH $*"
else
    # set up auth
    echo project_id=${service_account_project} >> ${HOME}/.bigqueryrc
    gcloud auth activate-service-account ${service_account_email} --key-file=$GOOGLE_APPLICATION_CREDENTIALS
    # Exec the command
    exec $*
fi
