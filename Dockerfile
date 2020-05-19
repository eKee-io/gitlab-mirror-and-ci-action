FROM alpine:latest

LABEL "com.github.actions.name"="Mirror to GitLab and run GitLab CI"
LABEL "com.github.actions.description"="Automate mirroring of git commits to GitLab, trigger GitLab CI and post results back to GitHub"
LABEL "com.github.actions.icon"="git-commit"
LABEL "com.github.actions.color"="blue"

LABEL "repository"="https://github.com/eKee-io/gitlab-mirror-and-ci-action"
LABEL "homepage"="https://github.com/eKee-io/gitlab-mirror-and-ci-action"
LABEL "maintainer"="Cyril Duval <cyril@fayak.com>"

RUN apk update && apk add --no-cache bash git curl jq && rm -rf /var/cache/apk/*

COPY entrypoint.sh /entrypoint.sh
COPY cred-helper.sh /cred-helper.sh
ENTRYPOINT ["/entrypoint.sh"]
