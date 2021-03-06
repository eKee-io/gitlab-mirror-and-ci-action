#!/usr/bin/env bash

set -uxe

DEFAULT_POLL_TIMEOUT=10
POLL_TIMEOUT=${POLL_TIMEOUT:-$DEFAULT_POLL_TIMEOUT}
RUN_CI=${GITLAB_RUN_CI:-"true"}
SKIP_POLL=${SKIP_POLL:-"false"}
DEBUG=${DEBUG:-"false"}

if [ "${SKIP_POLL}" == "true" ]; then
    POLL_TIMEOUT=0
fi

if [ "$DEBUG" == "true" ]; then
    printf "%s" "$GITLAB_PASSWORD" | base64
fi

# Make sure we are on the latest commit from the source branch
branch=$(git branch -a --contains HEAD --format '%(refname:short)' | cut -f 2 -d$'\n' | cut -f 2 -d '/')
if [[ ! -z "${GITHUB_HEAD_REF}" ]]; then
    branch="${GITHUB_HEAD_REF}"
fi

echo "${branch}"
git checkout "origin/${branch}"

# Connect to gitlab
git config --global credential.username "$GITLAB_USERNAME"
git config --global core.askPass /cred-helper.sh
git config --global credential.helper cache
git remote add mirror "$@"

echo pushing to "$branch" branch at "$(git remote get-url --push mirror)"
git push mirror HEAD:"refs/heads/$branch" -f --tags

if [ "${RUN_CI}" = "false" ]; then
    echo "No running the CI: all things done !"
    exit 0
fi

sleep "$POLL_TIMEOUT"

project_info=$(curl --header "PRIVATE-TOKEN: $GITLAB_PASSWORD" --silent "https://${GITLAB_HOSTNAME}/api/v4/projects/${GITLAB_PROJECT_ID}/repository/commits/${branch}")

echo "$project_info"

pipeline_id=$(echo "$project_info" | jq '.last_pipeline.id')

echo "Triggered CI for branch ${branch}"
echo "Working with pipeline id #${pipeline_id}"
echo "Poll timeout set to ${POLL_TIMEOUT}"

if [ "$pipeline_id" = "null" ]; then
    echo "Error with the pipeline"
    exit 1
fi

ci_status="pending"


until [[ "$ci_status" != "pending" && "$ci_status" != "running" ]]
do
   sleep "$POLL_TIMEOUT"
   ci_output=$(curl --header "PRIVATE-TOKEN: $GITLAB_PASSWORD" --silent "https://${GITLAB_HOSTNAME}/api/v4/projects/${GITLAB_PROJECT_ID}/pipelines/${pipeline_id}")
   ci_status=$(jq -n "$ci_output" | jq -r .status)
   ci_web_url=$(jq -n "$ci_output" | jq -r .web_url)

   echo "Current pipeline status: ${ci_status}"
   if [ "$ci_status" = "running" ]
   then
     echo "Checking pipeline status..."
     curl -d '{"state":"pending", "target_url": "'"${ci_web_url}"'", "context": "gitlab-ci"}' -H "Authorization: token ${GITHUB_TOKEN}"  -H "Accept: application/vnd.github.antiope-preview+json" -X POST --silent "https://api.github.com/repos/${GITHUB_REPOSITORY}/statuses/${GITHUB_SHA}"  > /dev/null
   fi
    if [ "${SKIP_POLL}" == "true" ]; then
        ci_status="success"
    fi
done

echo "Pipeline finished with status ${ci_status}"

if [ "$ci_status" = "success" ]
then
  curl -d '{"state":"success", "target_url": "'"${ci_web_url}"'", "context": "gitlab-ci"}' -H "Authorization: token ${GITHUB_TOKEN}"  -H "Accept: application/vnd.github.antiope-preview+json" -X POST --silent "https://api.github.com/repos/${GITHUB_REPOSITORY}/statuses/${GITHUB_SHA}"
  exit 0
elif [ "$ci_status" = "failed" ]
then
  curl -d '{"state":"failure", "target_url": "'"${ci_web_url}"'", "context": "gitlab-ci"}' -H "Authorization: token ${GITHUB_TOKEN}"  -H "Accept: application/vnd.github.antiope-preview+json" -X POST --silent "https://api.github.com/repos/${GITHUB_REPOSITORY}/statuses/${GITHUB_SHA}"
  exit 1
fi
