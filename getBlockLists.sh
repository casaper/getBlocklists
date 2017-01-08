#!/bin/bash

DESTINATION_DIR="final_list"
OUTOUT_FINAL_FILENAME="latest.p2p"

LISTDATE=$(date +%y%m%dT%H%M%S) # DateTime string for name
LISTS_DIR=lists_${LISTDATE}     # Temporary Dir name
export LC_ALL='C'               # For uniq and Sort
# Create lists directory in case its not yet there
if [[ ! -e ./${LISTS_DIR} ]]; then
    mkdir ${LISTS_DIR}
fi
# grab the lists uris from the website
BLOCKLIST_SOURCE_URL="$(curl -s https://www.iblocklist.com/lists.php | grep -o -e "http://list.iblocklist.com/[a-zA-Z\?\=;&0-9]*" | tr '\n' ' ')"
# grab the lists
for i in $BLOCKLIST_SOURCE_URL; do
    LISTNAME=$(echo $i | grep -o -E "list=[a-z]*" | grep -o -E "[a-z]*$") # list temp filename from uri
    curl "$i" > "${LISTS_DIR}/${LISTNAME}.gz"                             # download the list
    gunzip "${LISTS_DIR}/${LISTNAME}.gz"                                  # unpack the list
    cat "${LISTS_DIR}/${LISTNAME}" >> "${LISTS_DIR}/cated.list"           # concat it in one file
done

if [[ ! -e "${DESTINATION_DIR}" ]]; then
    mkdir "${DESTINATION_DIR}"
fi
# first uniq attempt
uniq -i "${LISTS_DIR}/cated.list" > "${DESTINATION_DIR}/${LISTDATE}.uniq1"
# second attempt with ip only
for i in $(cut -d ':' -s -f 2 "${DESTINATION_DIR}/${LISTDATE}.uniq1" | uniq -i); do
    echo "T:$i" >> "${DESTINATION_DIR}/${LISTDATE}.p2p"  # produce final p2p file
done
# create compressed version for archive purposes
gzip -k "${DESTINATION_DIR}/${LISTDATE}.p2p"
# rename to final filename
mv "${DESTINATION_DIR}/${LISTDATE}.p2p" "${DESTINATION_DIR}/${OUTOUT_FINAL_FILENAME}"
# delete stuff
rm -Rf "${LISTS_DIR}"
rm -Rf "${DESTINATION_DIR}/${LISTDATE}.uniq1"
exit 0
