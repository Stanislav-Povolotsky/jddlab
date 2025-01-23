#!/bin/bash

# local/remote
MODE="$1"
if [[ "$MODE" == "" ]]; then 
    MODE=local
fi
BRANCH="$2"
# repo username/reponame (only for remote)
REPO="$3"

if [[ "$MODE" == "local" ]]; then
    # Installation mode
    #git clone -b $BRANCH --single-branch $REPOFULL .
    last_commit="commit $(TZ=UTC0 git log -1 --pretty=format:"%h at %ad" --date='format-local:%Y-%m-%d') on $(git branch --show-current) branch"
    commit_hash=$(git log -1 --pretty=format:"%h")
    remote_path=$(git remote get-url origin)
    github_url=$(echo "$remote_path" | sed -e 's/git@github.com:/https:\/\/github.com\//' -e 's/.git$//')
    commit_url="$github_url/commit/${commit_hash}"
else
    REPOFULL="https://github.com/$REPO"
    last_commit_data=$(curl -s "https://api.github.com/repos/$REPO/commits/$BRANCH")
    full_commit_hash=$(echo "$last_commit_data" | jq -r '.sha')
    commit_hash=${full_commit_hash:0:7}
    commit_date_utc=$(echo "$last_commit_data" | jq -r '.commit.committer.date')
    commit_date=$(date -d "$commit_date_utc" +%Y-%m-%d)
    remote_path="$REPOFULL"
    last_commit="commit $commit_hash at $commit_date on $BRANCH branch"
    commit_url="$REPOFULL/commit/${commit_hash}"
fi

echo "$last_commit"
echo "$commit_hash"
echo "$remote_path"
echo "$github_url"
echo "$commit_url"