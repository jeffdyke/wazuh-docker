FROM alpine:latest
ARG S3_ENV_PATH
RUN apk add --no-cache aws-cli bash cat sed

COPY ./crontab /root/crontab
RUN cat /root/crontab | sed "s:S3_TMPL_PATH:${S3_ENV_PATH}" > /etc/crontab/root

ENTRYPOINT ["crond", "-f", "-d", "8"]
