#!/bin/bash
LISTDATE=$(date +%y%m%dT%H%M%S)
LISTS_DIR=lists_${LISTDATE}

if [[ $OSTYPE =~ "darwin" ]]; then
    TRANSMIT_CONFIG_PATH=$HOME/Library/Application\ Support/Transmission
else
    TRANSMIT_CONFIG_PATH=$HOME/.config/transmission
fi

TRANSMIT_BLOCKLIST_PATH=$TRANSMIT_CONFIG_PATH/blocklists
# Download lists, unpack and filter, write to stdout
if [[ ! -e ./${LISTS_DIR} ]]; then
    mkdir ${LISTS_DIR}
fi
BLIST_SRC="$(curl -s https://www.iblocklist.com/lists.php | grep -o -e "http://list.iblocklist.com/[a-zA-Z\?\=;&0-9]*" | tr '\n' ' ')"
for i in $BLIST_SRC; do
    # in order to have some safe filename, grab the listname from the url
    LISTNAME=$(echo $i | grep -o -E "list=[a-z]*" | grep -o -E "[a-z]*$")
    wget -O ${LISTS_DIR}/${LISTNAME}.gz $i #download the list
    gunzip ${LISTS_DIR}/${LISTNAME}.gz  #unpack the list
    
    # get rid of the uneccesary title with cut
    # there will be some dummyTitle in the final output
    cut -d ':' -s -f 2 ${LISTS_DIR}/${LISTNAME} >> ${LISTS_DIR}/cated.list 
    rm ${LISTS_DIR}/${LISTNAME} # it is not needed anymore, so get rid or it
done

if [[ ! -e final_list ]]; then
    mkdir final_list
fi
# Filter duplicate entrys, so we only have a rule once in the final list
uniq -i ${LISTS_DIR}/cated.list > final_list/${LISTDATE} 
# add the dummyTitle for the Rule. Transmission seems to need this in order to be able to digest the list
# That it is the same for all rules, seems not to matter. Rulenames are pointless with several 100k rules...
sed 's/\(.*\)/dummyTitle:\1/g' final_list/${LISTDATE} > final_list/${LISTDATE}.tmp
mv final_list/${LISTDATE}.tmp final_list/${LISTDATE}
AMT_RULES_ORIG=$(wc -l ${LISTS_DIR}/cated.list | cut -f 3 -d ' ')
AMT_RULES_new=$(wc -l final_list/${LISTDATE} | cut -f 3 -d ' ')

echo "Originally ${AMT_RULES_ORIG} where merged to ${AMT_RULES_new} Rules. That saved " $(($AMT_RULES_ORIG-$AMT_RULES_new)) " duplicates."

gzip -k final_list/${LISTDATE}
gzip ${LISTS_DIR}/cated.list
if [[ ! -e list_archive ]]; then
    mkdir list_archive
fi
mv ${LISTS_DIR}/cated.list.gz list_archive/$LISTDATE.gz
rm -Rf ${LISTS_DIR}
HERE=$PWD
cd "$TRANSMIT_BLOCKLIST_PATH"
rm list.txt*
cd "$HERE"
mv final_list/${LISTDATE} "$TRANSMIT_BLOCKLIST_PATH/list.txt"
exit 0
