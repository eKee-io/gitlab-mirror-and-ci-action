# Mirror to GitLab and trigger GitLab CI

A GitHub Action that mirrors all commits to GitLab, triggers GitLab CI, and returns the results back to GitHub. 

This action uses active polling to determine whether the GitLab pipeline is finished. This means our GitHub Action will run for the same amount of time as it takes for GitLab CI to finish the pipeline. 

## Example workflow

This is an example of a pipeline that uses this action:

```workflow
name: Mirror and run GitLab CI

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v1
    - name: Mirror + trigger CI
      uses: eKee-io/gitlab-mirror-and-ci-action@master
      with:
        args: "https://gitlab.com/<namespace>/<repository>"
      env:
        GITLAB_HOSTNAME: "gitlab.ekee.io"
        GITLAB_USERNAME: ""
        GITLAB_PASSWORD: ${{ secrets.GITLAB_PASSWORD }} // Generate here: https://gitlab.com/profile/personal_access_tokens
        GITLAB_PROJECT_ID: "<GitLab project ID>"
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }} // https://help.github.com/en/articles/virtual-environments-for-github-actions#github_token-secret
        GITLAB_RUN_CI: "true"
```

Be sure to define the `GITLAB_PASSWORD` secret.

# Changelog from SvanBoxel/gitlab-mirror-and-ci-action

`2020-05-18`:
    - Add -f option on git push. With this option, we can push force on github, and the push will be propagated to our gitlab as well. Since our gitlab instance shall not be modified by anyone but github action, it should be running fine
    - Shellchecked the entrypoint. Add -xe options
`2020-05-26`:
    - Add the `GITLAB_RUN_CI` env var to trigger only the sync job
2020-07:
    - Add a detection of events triggered by github's `pull_requests` and `create.tag`
2020-07-28:
    - Add a skip polling option
