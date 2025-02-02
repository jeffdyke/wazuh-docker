FROM alpine:latest
ARG S3_ENV_PATH
RUN apk add --no-cache aws-cli bash sed

COPY ./config/crontab /root/ossec-alerts
RUN set -e && \
    sed -i"" "s:S3_TMPL_PATH:${S3_ENV_PATH}:" /root/ossec-alerts && \
    cat /root/ossec-alerts | head -1 | tee -a /var/spool/cron/crontabs/root && \
    rm /root/ossec-alerts

ENTRYPOINT ["crond", "-f", "-d", "8"]
