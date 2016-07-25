#!/bin/sh
set -e

# increment build number
PROJECT_DIR="Opptur"
INFOPLIST_FILE="Info.plist"
versionNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${PROJECT_DIR}/${INFOPLIST_FILE}")
buildNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${PROJECT_DIR}/${INFOPLIST_FILE}")
buildNumber=$(($buildNumber + 1))
triplet="$versionNumber ($buildNumber)"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${PROJECT_DIR}/${INFOPLIST_FILE}"
changelog=$(git log --pretty=%s origin/HEAD..HEAD)

# tag release
git add "${PROJECT_DIR}/${INFOPLIST_FILE}"
git commit -m "increment to ${triplet}"
git tag -a "release-$versionNumber-$buildNumber" -m "$changelog"
git push origin $lastTag
git push --tags
