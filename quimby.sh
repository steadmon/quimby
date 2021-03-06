#!/bin/bash

# Author: nasamuffin
#
# Usage:
#
#   quimby <base-branch> <topic-branch> [-C <path>] [args-to-format-patch...]
#
# When you invoke 'quimby' against your topic, it does the following things:
#
# 1) Pushes (by force if necessary) <topic-branch> and <base-branch> to your
#    fork of Git on Github.
# 2) Calls 'git-format-patch' with the provided flags, plus --cover-letter if
#    more than one commit will exist.
#
# quimby must be run from inside a repo, or a repo must be specified with -C.
#
# You must set a Git config "quimby.fork" to contain the name of your fork of
# Git. This can take the form either of a previously configured remote, or a
# URL, as it will be passed directly to 'git push'.
#
#
# Some notes:
#
# - Actions will only be run if <base-branch>..<topic-branch> contains
#   dd/ci-swap-azure-pipelines-with-github-actions. That topic was merged to
#   'master' on April 29, 2020 (8cb514d1cb), but an older version of 'master'
#   may not run tests. Use an earlier commit of 'quimby' to get the GitGitGadget
#   PR workflow instead if your <base-branch> is that old.
# - <topic-branch> will be force-pushed to your own fork. If you're using quimby
#   because your usual workflow doesn't use Github at all, that shouldn't bother
#   you.

# Positional parameters
PARAMS=()

git_dir=

# Check for args
while (( "$#" )); do
  case "$1" in
    -C)
      git_dir="-C '$2'"
      shift 2
      ;;
    *)
      PARAMS+=("$1")
      shift
      ;;
  esac
done

if [[ "${#PARAMS[@]}" -lt 2 ]];
then
  # todo echo usage
  echo " quimby <base-branch> <topic-branch> [args-to-format-patch...]"
  exit
fi

# Check if we have a remote set up.
remote="$(git ${git_dir} config quimby.fork)"
while [[ -z "${remote}" ]]; do
  git ${git_dir} remote -v
  echo "quimby.fork is not configured. Please provide a remote name or URL:"
  read remote
  git ${git_dir} config quimby.fork "${remote}"
done

base_branch="${PARAMS[0]}"
topic_branch="${PARAMS[1]}"

# Force push to start an Actions run:
git ${git_dir} push "${remote}" "${base_branch}" +"${topic_branch}"
echo "Check the Actions tab on your fork to monitor the CI run."

# Determine whether a cover letter is needed
cover_letter_flag=
if [[ "$(git rev-list --count "${base_branch}..${topic_branch}")" -gt 1 ]];
then
  cover_letter_flag="--cover-letter"
fi

git format-patch ${cover_letter_flag} ${PARAMS[@]:2} \
  "${base_branch}..${topic_branch}"
