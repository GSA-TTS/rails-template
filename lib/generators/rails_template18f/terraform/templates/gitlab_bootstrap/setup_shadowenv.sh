#!/usr/bin/env bash
#
# Setup .shadowenv.d/ files for terraform configuration

set -e

# ensure we're operating with the correct relative paths
cd `dirname "$0"`

shadowenv trust && eval "$(shadowenv hook)"

ans=""
prompt_ans() {
  local prompt="$1"
  local default="$2"
  if [ -n "$default" ]; then
    prompt="$prompt (default: $default)"
  fi
  read -r -p "$prompt: " ans
}

prompt_ans "GitLab hostname" "${GITLAB_HOSTNAME:=gsa.gitlab-dedicated.us}"
if [ -n "$ans" ]; then
  GITLAB_HOSTNAME="$ans"
fi

prompt_ans "GitLab project id" "$GITLAB_PROJECT_ID"
if [ -n "$ans" ]; then
  GITLAB_PROJECT_ID="$ans"
fi

if [ ! -d ../.shadowenv.d ]; then
  mkdir ../.shadowenv.d
fi

cat <<EOF > ../.shadowenv.d/100_gitlab_project.lisp
(provide "gitlab-backend-config")
(env/set "GITLAB_HOSTNAME" "$GITLAB_HOSTNAME")
(env/set "GITLAB_PROJECT_ID" "$GITLAB_PROJECT_ID")
EOF

prompt_ans "GitLab username" "$TF_HTTP_USERNAME"
if [ -n "$ans" ]; then
  TF_HTTP_USERNAME=$ans
fi
if [ -z "$TF_HTTP_PASSWORD" ]; then
  prompt_ans "GitLab PAT (with api scope)"
else
  prompt_ans "GitLab PAT (with api scope, Leave blank to re-use existing PAT)"
fi
if [ -n "$ans" ]; then
  TF_HTTP_PASSWORD=$ans
fi

cat <<EOF > ../.shadowenv.d/500_tf_backend_secrets.lisp
(provide "tf-backend-secrets")
(env/set "TF_HTTP_USERNAME" "$TF_HTTP_USERNAME")
(env/set "TF_HTTP_PASSWORD" "$TF_HTTP_PASSWORD")
EOF
