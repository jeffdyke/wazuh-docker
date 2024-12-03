FROM alpine:latest

RUN apk add --no-cache aws-cli bash
COPY ./crontab /etc/crontab/root
ENTRYPOINT ["crond", "-f", "-d", "8"]
