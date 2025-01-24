FROM debian:latest AS build
ARG LOG_STREAM_NAME
ARG LOG_GROUP_NAME
ARG REGION

RUN apt-get update &&  \
    apt-get install -y ca-certificates curl jq && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /etc/cwagentconfig

COPY ./config/cwagent.json /root/cwagent_tmpl.json
RUN jq '.logs.logs_collected.files.collect_list[0].log_stream_name = "${LOG_STREAM_NAME}" | .logs.logs_collected.files.collect_list[0].log_group_name="${LOG_GROUP_NAME}" | .agent.region = "${REGION}' /root/cwagent_tmpl.json > /etc/cwagentconfig/cwagent.json
RUN curl -O https://s3.amazonaws.com/amazoncloudwatch-agent/debian/amd64/latest/amazon-cloudwatch-agent.deb && \
    dpkg -i -E amazon-cloudwatch-agent.deb && \
    rm -rf /tmp/* && \
    rm -rf /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard && \
    rm -rf /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl && \
    rm -rf /opt/aws/amazon-cloudwatch-agent/bin/config-downloader

FROM scratch

COPY --from=build /tmp /tmp
COPY --from=build /etc/cwagentconfig/cwagent.json /etc/cwagentconfig/cwagent.json
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /opt/aws/amazon-cloudwatch-agent /opt/aws/amazon-cloudwatch-agent

ENV RUN_IN_CONTAINER="True"
ENTRYPOINT ["/opt/aws/amazon-cloudwatch-agent/bin/start-amazon-cloudwatch-agent"]
