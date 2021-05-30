#! /bin/sh
set -e
if [ "${S3_ACCESS_KEY_ID}" == "**None**" ]; then
   echo "Warning: You did not set the S3_ACCESS_KEY_ID environment variable."
else
    export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
fi

if [ "${S3_SECRET_ACCESS_KEY}" == "**None**" ]; then
   echo "Warning: You did not set the S3_SECRET_ACCESS_KEY environment variable."

else
  export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
fi

if [ "${S3_BUCKET}" == "**None**" ]; then
   echo "You need to set the S3_BUCKET environment variable."
   exit 1
fi

if [ "${MYSQL_HOST}" == "**None**" ]; then
   echo "You need to set the MYSQL_HOST environment variable."
   exit 1
fi

if [ "${MYSQL_USER}" == "**None**" ]; then
   echo "You need to set the MYSQL_USER environment variable."
   exit 1
fi

if [ "${MYSQL_PASSWORD}" == "**None**" ]; then
   echo "You need to set the MYSQL_PASSWORD environment variable or link to a container named MYSQL."
   exit 1
fi
DUMP_FILE="/tmp/dump.sql.gz"
MYSQL_HOST_OPTS="-h $MYSQL_HOST -P $MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASSWORD"

upload_to_s3() {
   SRC_FILE=$1
   DEST_FILE=$2

   if [ "${S3_ENDPOINT}" == "**None**" ]; then
      AWS_ARGS=""
   else
      AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
   fi

   echo "Uploading ${DEST_FILE} on S3..."

   cat $SRC_FILE | aws $AWS_ARGS s3 cp - s3://$S3_BUCKET/$S3_PREFIX/$DEST_FILE

   if [ $? != 0 ]; then
      echo >&2 "Error uploading ${DEST_FILE} on S3"
   fi

   rm $SRC_FILE
}
download_from_s3() {
   DEST_FILE=$1
   if [ "${S3_ENDPOINT}" == "**None**" ]; then
      AWS_ARGS=""
   else
      AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
   fi

   echo "Downloading ${DEST_FILE} from S3(${S3_ENDPOINT})..."
    echo "aws $AWS_ARGS s3 cp  s3://$S3_BUCKET/$S3_PREFIX/$DEST_FILE "/tmp/$DEST_FILE""
    aws $AWS_ARGS s3 cp  s3://$S3_BUCKET/$S3_PREFIX/$DEST_FILE "/tmp/$DEST_FILE"

   if [ $? != 0 ]; then
      echo >&2 "Error downloading ${DEST_FILE} from S3"
   fi
}

backup() {
   echo "Creating dump for ${MYSQL_DATABASE} from ${MYSQL_HOST}..."
   DUMP_FILE="/tmp/dump.sql.gz"
   echo "mysqldump $MYSQL_HOST_OPTS $MYSQL_OPTIONS $MYSQL_DATABASE | gzip >$DUMP_FILE"
   mysqldump -alv $MYSQL_HOST_OPTS $MYSQL_OPTIONS $MYSQL_DATABASE | gzip >$DUMP_FILE
}

restore() {

   DUMP_PATH="/temp/$1"
   if ! mysql ${MYSQL_OPTIONS} -e "use ${MYSQL_DATABASE};"; then
      echo "${MYSQL_DATABASE} doesn't exists. Create new one..."
      mysql $MYSQL_HOST_OPTS ${MYSQL_OPTIONS} -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};"
   fi

   echo "Restore MySQL database from ${DUMP_PATH}..."
   if ! gunzip <${DUMP_PATH} | mysql $MYSQL_HOST_OPTS ${MYSQL_OPTIONS} ${MYSQL_DATABASE}; then
      echo "Error restoring database" >&2
      exit 1
   fi

   echo "Restore finished: ${DUMP_PATH} -> ${MYSQL_DATABASE}"

}
DUMP_START_TIME=$(date +"%Y-%m-%dT%H%M%SZ")

case "$1" in
'backup')
   backup
   echo $?
   if [ $? == 0 ]; then
     echo "okay"
      if [ "${S3_FILENAME}" == "**None**" ]; then
         S3_FILE="${DUMP_START_TIME}.dump.sql.gz"
      else
         S3_FILE="${S3_FILENAME}.sql.gz"
      fi

      upload_to_s3 $DUMP_FILE $S3_FILE
   else
      echo >&2 "Error creating dump of  databases"
   fi
   echo "SQL backup finished"
   ;;
'restore')
   [ -z "$2" ] && echo "DEST_FILE parameter empty" && exit 1
   download_from_s3 $2
   [ ! -f /temp/$2 ] && echo "/tmp/$2 does not exists" && exit 1
   restore $2

   ;;
 'okay')
 echo $2
 ;;
esac
