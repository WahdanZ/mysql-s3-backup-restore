FROM alpine:latest
ENV LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8"
ARG OC_VERSION=4.5
ARG BUILD_DEPS='tar gzip'
ARG RUN_DEPS='curl ca-certificates gettext'
RUN apk add --update --no-cache -v --virtual .build-deps \
   curl py-pip \
   && apk add nano \
    && apk add mongodb-tools \
    && apk add -v  \
        mysql-client \
           && pip install awscli \
    && apk --no-cache del \
        binutils \
        curl \
      &&  apk del py-pip \
    && rm -rf /var/cache/apk/*
    
RUN apk --no-cache add $BUILD_DEPS $RUN_DEPS && \
    curl -sLo /tmp/oc.tar.gz https://mirror.openshift.com/pub/openshift-v$(echo $OC_VERSION | cut -d'.' -f 1)/clients/oc/$OC_VERSION/linux/oc.tar.gz && \
    tar xzvf /tmp/oc.tar.gz -C /usr/local/bin/ && \
    rm -rf /tmp/oc.tar.gz && \
    apk del $BUILD_DEPS



ENV MYSQL_OPTIONS --quote-names --quick --add-drop-table --add-locks --allow-keywords --disable-keys --extended-insert --single-transaction --create-options --comments --net_buffer_length=16384
ENV MYSQL_DATABASE btt-db
ENV MYSQL_HOST localhost
ENV MYSQL_PORT 3306
ENV MYSQL_USER **None**
ENV MYSQL_PASSWORD **None**


ENV MONGO_DATABASE btt-db
ENV MONGO_HOST localhost
ENV MONGO_PORT 27018
ENV MONGO_USER **None**
ENV MONGO_PASSWORD **None**


ENV S3_ACCESS_KEY_ID **None**
ENV S3_SECRET_ACCESS_KEY **None**
ENV S3_BUCKET **None**
ENV S3_REGION us-west-1
ENV S3_ENDPOINT **None**
ENV S3_S3V4 no
ENV S3_PREFIX 'backup'
ENV S3_FILENAME **None**
ENV MULTI_FILES no
ENV SCHEDULE **None**

ADD ./mongo.sh /opt/mongo.sh
ADD ./mysql.sh /opt/mysql.sh
ADD ./start.sh /opt/start.sh
RUN chmod 777 /opt/*.sh
RUN chgrp -R 0 /opt && \
    chmod -R g=u /opt
#WORKDIR /opt

ENTRYPOINT ["tail"]
CMD ["-f","/dev/null"]


