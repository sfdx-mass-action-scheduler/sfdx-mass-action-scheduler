#!/usr/bin/env bash

# Convert source format to mdapi format, which creates a package.xml
sfdx force:source:convert -d mdapi

# Replace the package.xml in the manifest folder
# https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_develop_any_org.htm
# http://www.illuminatedcloud.com/announcements/2061releasenotes
rm manifest/package.xml || true
mkdir -p manifest
mv mdapi/package.xml manifest/package.xml

# Delete the converted mdapi folder
rm -rf mdapi
