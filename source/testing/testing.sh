#!/usr/bin/bash

USER=$(id -u -n)
EMAIL=${USER}@wisc.edu

# Recipients for email & text notifications
RECIPIENTS="${EMAIL}"

LOG=sleep_status.txt

SLEEP_DURATION=24
SLEEP_START=$(date '+%Y-%m-%d %H:%M:%S')

# Compose message
echo "Job ID: $CONDOR_JOB_ID" >> $LOG
echo "Ready at: ${SLEEP_START}" >> $LOG
echo "Waiting: ${SLEEP_DURATION}hr" >> $LOG
# Subject line
SUBJECT="CHTC Job Ready (${CONDOR_JOB_ID})"
# Send message to recipients
mailx -s "$SUBJECT" $RECIPIENTS < $LOG

# Sleep
sleep ${SLEEP_DURATION}h
