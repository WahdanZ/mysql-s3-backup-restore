FROM quay.io/jitesoft/alpine:latest


RUN apk add --update --no-cache -v --virtual .build-deps \
   curl py-pip \
    && apk add -v  \
        mysql-client \
           && pip install awscli \
    && apk --no-cache del \
        binutils \
        curl \
      &&  apk del py-pip \
    && rm -rf /var/cache/apk/*


ENV MYSQL_OPTIONS --quote-names --quick --add-drop-table --add-locks --allow-keywords --disable-keys --extended-insert --single-transaction --create-options --comments --net_buffer_length=16384
ENV MYSQL_DATABASE btt-db
ENV MYSQL_HOST localhost
ENV MYSQL_PORT 13306
ENV MYSQL_USER admin
ENV MYSQL_PASSWORD BVGAkbHn7mNMevNr
ENV S3_ACCESS_KEY_ID AKIAIOSFODNN7EXAMPLE
ENV S3_SECRET_ACCESS_KEY AKIAIOSFODNN7EXAMPLE
ENV S3_BUCKET btt-db
ENV S3_REGION us-west-1
ENV S3_ENDPOINT http://minio-btt-testing.kermit-noprod-b.itn.intraorange/
ENV S3_S3V4 true
ENV S3_PREFIX 'backup'
ENV S3_FILENAME **None**
ENV MULTI_FILES no
ENV SCHEDULE **None**

ADD ./script.sh /opt/script.sh
ADD ./start.sh /opt/start.sh
RUN chmod 777 /opt/*.sh

WORKDIR /opt

CMD ["/opt/start.sh"]


