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
ENV VERSION=4.6 \
    HELM2_VERSION=v2.17.0 \
    HELM3_VERSION=v3.5.3 \
    KUSTOMIZE_VERSION=v3.8.9 \
    SEISO_VERSION=v0.7.2 \
    KUBEVAL_VERSION=v0.16.1 \
    ARCHIVE=linux/oc \
    SHA256SUM= \
    HELM2_SHA256SUM=f3bec3c7c55f6a9eb9e6586b8c503f370af92fe987fcbf741f37707606d70296 \
    HELM3_SHA256SUM=2170a1a644a9e0b863f00c17b761ce33d4323da64fc74562a3a6df2abbf6cd70 \
    KUSTOMIZE_SHA256SUM=0829ad1df8b25c70e6e686638c83bdf0987d25a2b357ccca5cf80a5877f3674d \
    SEISO_SHA256SUM=221969945e5bbcdbf7b1dc6312e4b64460dce64d0f9a9bedcb9faaa8d3657f89 \
    KUBEVAL_SHA256SUM=2d6f9bda1423b93787fa05d9e8dfce2fc1190fefbcd9d0936b9635f3f78ba790 \
    SOPS_VERSION=v3.7.1 \
    SOPS_RELEASES_URL="https://github.com/mozilla/sops/releases/download" \
    OKD_DOWNLOAD_BASE_URL="https://mirror.openshift.com/pub/openshift-v4/clients/oc" \
    HELM_RELEASES_URL="https://get.helm.sh" \
    KUSTOMIZE_RELEASES_URL="https://github.com/kubernetes-sigs/kustomize/releases/download" \
    SEISO_RELEASES_URL="https://github.com/appuio/seiso/releases/download" \
    KUBEVAL_RELEASES_URL="https://github.com/instrumenta/kubeval/releases/download" \
    JQ_URL="https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64" \
    OC_PLUGINS_REPO="https://github.com/appuio/oc-plugins" \
    KUBECTL_PLUGINS_PATH="/opt/kube/plugins"

RUN set -x && \
    URL="${OKD_DOWNLOAD_BASE_URL}/${VERSION}/${ARCHIVE}.tar.gz" && \
    HELM2_URL="${HELM_RELEASES_URL}/helm-${HELM2_VERSION}-linux-amd64.tar.gz" && \
    HELM3_URL="${HELM_RELEASES_URL}/helm-${HELM3_VERSION}-linux-amd64.tar.gz" && \
    KUSTOMIZE_URL="${KUSTOMIZE_RELEASES_URL}/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" && \
    SEISO_URL="${SEISO_RELEASES_URL}/${SEISO_VERSION}/seiso_linux_amd64" && \
    KUBEVAL_URL="${KUBEVAL_RELEASES_URL}/${KUBEVAL_VERSION}/kubeval-linux-amd64.tar.gz" && \
    SOPS_URL="${SOPS_RELEASES_URL}/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux" && \
    cd /tmp && \
    curl -sSL "$URL" -o /tmp/oc.tgz && \
    curl -sSL "$HELM2_URL" -o /tmp/helm2.tgz && \
    curl -sSL "$HELM3_URL" -o /tmp/helm3.tgz && \
    curl -sSL "$KUSTOMIZE_URL" -o /tmp/kustomize.tgz && \
    curl -sSL "$SEISO_URL" -o /tmp/seiso && \
    curl -sSL "$KUBEVAL_URL" -o /tmp/kubeval.tgz && \
    curl -sSL "$JQ_URL" -o /tmp/jq && \
    curl -sSL "$SOPS_URL" -o /bin/sops && \
    echo "${SHA256SUM}  /tmp/oc.tgz" > /tmp/CHECKSUM && \
    echo "${HELM2_SHA256SUM}  /tmp/helm2.tgz" > /tmp/HELM2_CHECKSUM && \
    echo "${HELM3_SHA256SUM}  /tmp/helm3.tgz" > /tmp/HELM3_CHECKSUM && \
    echo "${KUSTOMIZE_SHA256SUM}  /tmp/kustomize.tgz" > /tmp/KUSTOMIZE_CHECKSUM && \
    echo "${SEISO_SHA256SUM}  /tmp/seiso" > /tmp/SEISO_CHECKSUM && \
    echo "${KUBEVAL_SHA256SUM}  /tmp/kubeval.tgz" > /tmp/KUBEVAL_CHECKSUM && \
    [ ! -z "$SHA256SUM" ] && sha256sum -c /tmp/CHECKSUM || echo "oc sha not checked" && \
    sha256sum -c /tmp/HELM2_CHECKSUM && \
    sha256sum -c /tmp/HELM3_CHECKSUM && \
    sha256sum -c /tmp/KUSTOMIZE_CHECKSUM && \
    sha256sum -c /tmp/SEISO_CHECKSUM && \
    sha256sum -c /tmp/KUBEVAL_CHECKSUM && \
    tar -xzvf /tmp/oc.tgz && \
    tar -xzvf /tmp/helm2.tgz && \
    mv -v "/tmp/linux-amd64/helm" /bin/helm2 && \
    rm -rf -v "/tmp/linux-amd64" && \
    tar -xzvf /tmp/helm3.tgz && \
    mv -v "/tmp/linux-amd64/helm" /bin/helm3 && \
    tar -xzvf /tmp/kustomize.tgz && \
    tar -xzvf /tmp/kubeval.tgz && \
    chmod 755 /tmp/kustomize /tmp/seiso /tmp/jq /bin/sops && \
    mv -v "/tmp/oc" /bin/ && \
    mv -v "/tmp/kubeval" /bin/ && \
    mv -v "/tmp/kustomize" /bin/ && \
    mv -v "/tmp/seiso" /bin/ && \
    mv -v "/tmp/jq" /bin/ && \
    ln -s /bin/oc /bin/kubectl && \
    ln -s /bin/helm3 /bin/helm && \
    rm -rf /tmp/* && \
    yum install -y git gettext && \
    yum clean all -y && \
    git clone --depth=1 ${OC_PLUGINS_REPO} ${KUBECTL_PLUGINS_PATH} && \
    helm2 init --client-only



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


