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

if [ "${MONGO_HOST}" == "**None**" ]; then
   echo "You need to set the MONGO_HOST environment variable."
   exit 1
fi

if [ "${MONGO_USER}" == "**None**" ]; then
   echo "You need to set the MONGO_USER environment variable."
   exit 1
fi

if [ "${MONGO_PASSWORD}" == "**None**" ]; then
   echo "You need to set the MONGO_PASSWORD environment variable or link to a container named Mongo."
   exit 1
fi
DUMP_FILE="/tmp/dump.mongo.gz"
MONGO_HOST_OPTS="-h $MONGO_HOST -P $MONGO_PORT -u$MONGO_USER -p$MONGO_PASSWORD"

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
   echo "Creating dump for ${MONGO_DATABASE} from ${MONGO_HOST}..."
   DUMP_FILE="/tmp/dump.sql.gz"
   echo "mongodump $MONGO_HOST_OPTS --db $MONGO_DATABASE --gzip --archive=$DUMP_FILE"
   mongodump  $MONGO_HOST_OPTS --db $MONGO_DATABASE --gzip --archive=$DUMP_FILE
}

restore() {

   DUMP_PATH="/tmp/$1"

   echo "Restore MONGO database from ${DUMP_PATH}..."
   if ! gunzip <${DUMP_PATH} | mongorestore $MONGO_HOST_OPTS --gzip --archive=${DUMP_PATH}; then
      echo "Error restoring database" >&2
      exit 1
   fi

   echo "Restore finished: ${DUMP_PATH} -> ${MONGO_DATABASE}"

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
   [ ! -f /tmp/$2 ] && echo "/tmp/$2 does not exists" && exit 1
   restore $2

   ;;
 'okay')
 echo $2
 ;;
esac
