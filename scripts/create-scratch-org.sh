#!/usr/bin/env bash

# =========================================================================== #
# USAGE
# -----
# create-scratch-org.sh [org alias]
#
# The $1 argument (optional) is what the alias should be.
# Default name is mas-scratch
# =========================================================================== #

# Exit when any command fails
set -e

# Set CLI API version to match sfdx-project.json
# https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_troubleshoot_api_sync.htm
echo "Setting CLI API Version to match sfdx-project.json"
api_version=$(cat sfdx-project.json | jq -r '.sourceApiVersion')
sfdx config:set apiVersion=$api_version

# Alias for the scratch org
org_alias=$1
if [ -z "$org_alias" ]; then
  org_alias="mas-scratch"
fi

echo "Creating scratch org with alias: ${org_alias}"

# Create scratch org
sfdx force:org:create -s -f config/project-scratch-def.json -d 30 -a $org_alias

# Deploy the code
sfdx force:source:deploy -p force-app -u $org_alias

# Assign permission set
sfdx force:user:permset:assign -n Mass_Action_Admin -u $org_alias

# Create a test account, only required for the report tests
sfdx force:data:record:create --sobjecttype Account --values "Name='dca_mass_action: MA Test Account'"

# Reset source tracking
sfdx force:source:tracking:reset --noprompt -u $org_alias

# User convenience, make our app the first in the app launcher
reorder_appmenu_apex=$(
  cat <<EOL
  List<AppMenuItem> menuItems = [
    SELECT ApplicationId FROM AppMenuItem
    WHERE Name = 'Mass_Action_Scheduler_Lightning'
  ];
  if (menuItems.size() > 0) {
    AppLauncher.AppMenu.setUserSortOrder(
      new List<ID> { menuItems[0].ApplicationId }
    );
  }
EOL
)
echo $reorder_appmenu_apex | sfdx force:apex:execute
