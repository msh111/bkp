FROM centos:7

# Environment
ENV PS1 "\n\n>> bkp \W \$ "
ENV PATH $APP_ROOT/bin:$PATH
ENV TERM=xterm

# Packages
RUN yum -y install epel-release && \
    yum -y update && \
    yum -y clean all


# Packages
ENV PACKAGES \
    duplicity \
    wget \
    which \
    mariadb \
    python-pip

RUN yum -y --setopt=tsflags=nodocs update && \
    yum -y --setopt=tsflags=nodocs install $PACKAGES && \
    yum clean all

RUN pip install -U boto3

# Prepare folder for Duplicity cache
RUN mkdir -p /opt/bkp-cache /opt/backups \
 && chown -R 1001:root /opt/bkp-cache /opt/backups

## Backup Container Entrypoint
COPY entrypoint-bkp.sh /usr/local/bin/entrypoint-bkp.sh
RUN chmod u+x  /usr/local/bin/entrypoint-bkp.sh \
 && chown -R 1001:root /usr/local/bin/entrypoint-bkp.sh

# Ready
USER 1001
CMD ["/usr/local/bin/entrypoint-bkp.sh"]