#!/bin/bash
#Purpose: Displays drives that are failed or are going to fail.
#Created: radpawel
#Modified: ver 1.0
RED='\033[0;31m'
NC='\033[0m' # No Color
echo "#################################"
echo "Failed/Predictive Drive(s)"
echo $HOSTNAME
date +%F\ %T
echo "#################################"
HPUTIL="/usr/sbin/hpacucli ctrl "
#if there is instance running kill if first
pgrep hpacucli >/dev/null

if [ $? -eq "0" ]; then
     kill -9 $(pgrep hpacu) &>/dev/null
fi
echo
if [ `whoami` == 'root' ];then
    SLOT=$($HPUTIL all show detail | grep 'Smart Array'| awk '{print $6}')

    for i in $SLOT
        do
          CTRL=$($HPUTIL slot=$i show detail | grep 'Smart Array' | awk '{print $3}')
          printf "$CTRL\tSLOT:\t$i\n"
          #work for multiple failed drives on the same ctrl get them all
          $HPUTIL slot=$i pd all show | egrep -i -v "array" | egrep -i '(Predictive|Failure| failed)' > failedHdds.txt
            STATUS=$?
                  if [[ $STATUS -eq "0" ]];then
                          while read -r line
                              do
                                  FAILED=$(echo $line | awk '{print $2}')
                                  DRV_Detail=$($HPUTIL slot=$i PD $FAILED show detail | egrep '(Staus|Size|Serial)')
                                  printf "$RED%s\n%s\n%s$NC\n\n" "Drive Details:" "$DRIVE" "$DRV_Detail"
                                  $HPUTIL slot=$i array A pd $FAILED modify led=on >/dev/null

                                 if [[ $? -eq "0" ]];then
                                         printf "%s%s\n\n" "$FAILED" "--> Led lit successfully"
                                else
                                    printf "$RED%s%s$NC\n\n" "$FAILED " " Drive coudn't be light up!!!"
                                fi
                            done < failedHdds.txt
                  else
                      printf "\tNo failed/predictive failure!\n\n"
                fi
                rm -f failedHdds.txt
        done
else
         echo "This needs to be run as root."
fi



