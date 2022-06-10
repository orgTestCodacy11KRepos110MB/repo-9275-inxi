#!/bin/bash

## release_docs

## Prepare html doc pages for release 

DATE='2022-06-10'
VERSION='3.3.17'

echo "Loadihng changelog, help, and man data.."

# note: you need to make a symbolic link from real html /docs/ directory to here:
DEV="$HOME/bin/scripts/inxi/svn/branches/inxi-perl/"
HTML_CHANGE="${DEV}smxi.org-docs/inxi-changelog.htm"
HTML_CHANGE_TEMP="${DEV}smxi.org-docs/inxi-changelog-temp.htm"
HTML_OPTIONS="${DEV}smxi.org-docs/inxi-options.htm"
HTML_OPTIONS_TEMP="${DEV}smxi.org-docs/inxi-options-temp.htm"
HTML_MAN="${DEV}smxi.org-docs/inxi-man.htm"
HTML_MAN_TEMP="${DEV}smxi.org-docs/inxi-man-temp.htm"

echo "Updating HTML content"
pinxi -yh | sed 's/pinxi/inxi/g' >  ${DEV}dev/inxi-options.txt
mman -Thtml ${DEV}pinxi.1 | sed -e '/^<!DOCTYPE/,/^<body/{/^<!DOCTYPE/!{/^<body/!d}}' -e '/^<!DOCTYPE/d' -e '/^<body/d' -e '/<\/body/d' -e '/<\/html/d' -e '/^\s*<br\/>\s*$/d' > ${DEV}dev/inxi-man.txt

echo "Updating temp and full html files...";
sed -i -e "s/^Page Updated: .*/Page Updated: $DATE/" -e "s/^inxi version: .*/inxi version: $VERSION/" $HTML_CHANGE_TEMP $HTML_OPTION_TEMP $HTML_MAN_TEMP

cp -f $HTML_CHANGE_TEMP $HTML_CHANGE
cp -f $HTML_MAN_TEMP $HTML_MAN
cp -f $HTML_OPTIONS_TEMP $HTML_OPTIONS

echo "Ok, now copy:"
echo "dev/inxi-man.txt > docs/inxi-man.htm"
echo "dev/inxi-options.txt > docs/inxi-options.htm"
echo "pinxi.changelog > docs/inxi-changelog.htm'



