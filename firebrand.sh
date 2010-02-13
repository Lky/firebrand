#!/bin/sh
#
# firebrand - a script to brand firefox without recompilation
#
#
# This script replaces and changes (a few) files in an existing firefox 
# installation. Run it after a firefox installation or upgrade, and restart 
# firefox. The program icon may not be (visibly) replaced until your desktop 
# environment is restarted.
#
# To revert to the original brand, simply reinstall firefox.
#
# Dependencies: curl, zip, unzip
#

#FIREFOXDIR: Where firefox's data files resides.

# Gran Paradiso:
FIREFOXDIR=/usr/lib/firefox-3.6
FIREFOXSTRING="Namoroka"
FIREFOXSTRINGPREFS="Namoroka"

NEWICONSDIR=""                              # If empty, the script uses a temporary directory for the replacement icons.
                                            # If you want to avoid downloading the icons every time you rebrand firefox,
                                            # point NEWICONSDIR to a suitable directory.

SOURCEBASE="http://mxr.mozilla.org/seamonkey/source" # The URL under which the "other-licenses" directory resides.


CHROMEDIR=$FIREFOXDIR/chrome                # Simply the firefox chrome directory.



die() {
    EXITCODE="${1:-9}"
    MESSAGE="$2"

    echo -e "\n$MESSAGE"

    exit $EXITCODE
}



get_icon() {
    local ICON="$1"
    local SOURCEFILE="$2"

    echo -n " - $ICON"

    if [ -e "$NEWICONSDIR/$ICON" ] ; then
        if [ -f "$NEWICONSDIR/$ICON" ] ; then
            echo " is present."
            return 0
        else
            echo " is present but is not a file. Quitting."
            exit 1
        fi
    fi

    echo -n ": Downloading... "
    if curl -sS "${SOURCEBASE}${SOURCEFILE}" > "$NEWICONSDIR/$ICON" ; then
        echo "Done."
        return 0
    else
        exit 1
    fi
}



TEMPDIR=$(mktemp -d -t firebrand-work-XXXXXXXX)

if [ $? -ne 0 ] ; then
    die 1 "Could not create temporary work directory."
fi

if [ "x$NEWICONSDIR" == "x" ] ; then
    NEWICONSDIR=$(mktemp -d -t firebrand-icon-XXXXXXXX)

    if [ $? -ne 0 ] ; then
        die 1 "Could not create temporary icon directory."
    fi
else
    [ -e "$NEWICONSDIR" ] || mkdir -p "$NEWICONSDIR" || die 1 "Could not create icon directory $NEWICONSDIR."
fi



echo -e "\033[1mChecking replacement icons\033[0m"
get_icon "mozicon50.xpm"    "/other-licenses/branding/firefox/mozicon50.xpm?raw=1"
get_icon "mozicon16.xpm"    "/other-licenses/branding/firefox/mozicon16.xpm?raw=1"
get_icon "mozicon128.png"   "/other-licenses/branding/firefox/mozicon128.png?raw=1"
get_icon "document.png"     "/other-licenses/branding/firefox/document.png?raw=1"
get_icon "icon48.png"       "/other-licenses/branding/firefox/content/icon48.png?raw=1"
get_icon "icon64.png"       "/other-licenses/branding/firefox/content/icon64.png?raw=1"
get_icon "about.png"        "/other-licenses/branding/firefox/content/about.png?raw=1"
get_icon "aboutCredits.png" "/other-licenses/branding/firefox/content/aboutCredits.png?raw=1"
get_icon "aboutFooter.png"  "/other-licenses/branding/firefox/content/aboutFooter.png?raw=1"
get_icon "default16.png"    "/other-licenses/branding/firefox/default16.png?raw=1"
get_icon "default32.png"    "/other-licenses/branding/firefox/default32.png?raw=1"
get_icon "default48.png"    "/other-licenses/branding/firefox/default48.png?raw=1"

cp "$NEWICONSDIR/mozicon50.xpm" "$NEWICONSDIR/default.xpm"
cp "$NEWICONSDIR/default16.png" "$NEWICONSDIR/default16.png"
cp "$NEWICONSDIR/default32.png" "$NEWICONSDIR/default32.png"
cp "$NEWICONSDIR/default48.png" "$NEWICONSDIR/default48.png"
cp "$NEWICONSDIR/icon64.png"     "/usr/share/pixmaps/firefox.png"

echo -e "\033[1mBranding chrome/en-US.jar\033[0m"
echo -n " - Unzipping branding files in chrome/en-US.jar to temporary directory... "
unzip -q -d "$TEMPDIR" "$CHROMEDIR/en-US.jar" locale/branding/brand.dtd locale/branding/brand.properties && echo "Done." || die 1 "Failed."

for FILE in $TEMPDIR/locale/branding/* ; do
    sed -i "s|$FIREFOXSTRING|Firefox|g" "$FILE" && echo " - Successfully edited ${FILE}" || die 1 "Could not edit ${FILE}."
done

echo -n " - Replacing old branding files in chrome/en-US.jar... "
( cd $TEMPDIR && zip -q -r "$CHROMEDIR/en-US.jar" locale/branding/* ) && echo "Done." || die 1 "Failed."


echo -e "\033[1mBranding chrome/browser.jar\033[0m"
echo -n " - Making new branding icon structure in temporary directory... "
mkdir -p "$TEMPDIR/content/branding" || die 1 "Could not create $TEMPDIR/content/branding."
cp "$NEWICONSDIR"/{about.png,aboutCredits.png,aboutFooter.png,icon48.png,icon64.png} "$TEMPDIR/content/branding/" || die 1 "Could not copy new icons to $TEMPDIR/content/branding/."
echo "Done."
echo -n " - Replacing old branding icon structure in chrome/browser.jar... "
( cd $TEMPDIR && zip -q -r "$CHROMEDIR/browser.jar" content/branding/* ) && echo "Done." || die 1 "Failed."

echo -e "\033[1mBranding defaults/preferences/firefox.js\033[0m"
sed -i "s|$FIREFOXSTRINGPREFS|Firefox|g" $FIREFOXDIR/defaults/preferences/firefox.js && echo " - Successfully edited $FIREFOXDIR/defaults/preferences/firefox.js." || die 1 "Could not edit $FIREFOXDIR/defaults/preferences/firefox.js."

echo -e "\033[1mBranding icons\033[0m"
echo -n " - Replacing icons in chrome/icons/default/... "
cp "$NEWICONSDIR"/{default48.png,default32.png,default16.png} $FIREFOXDIR/chrome/icons/default/ && echo "Done." || die 1 "Failed."

echo -n " - Replacing icons in icons/... "
cp "$NEWICONSDIR"/{document.png,mozicon128.png,mozicon16.xpm,mozicon50.xpm} $FIREFOXDIR/icons/ && echo "Done." || die 1 "Failed."

chmod 644 $FIREFOXDIR/chrome/icons/default/* $FIREFOXDIR/icons/*
chown root:root $FIREFOXDIR/chrome/icons/default/* $FIREFOXDIR/icons/*

chmod 644 /usr/share/pixmaps/firefox.png 
chown root:root /usr/share/pixmaps/firefox.png
