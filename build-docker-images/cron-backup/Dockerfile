FROM alpine:latest
ARG S3_ENV_PATH
RUN apk add --no-cache aws-cli bash sed

COPY ./config/crontab /var/spool/cron/crontabs/root

# ENTRYPOINT ["crond", "-f", "-d", "8"]
