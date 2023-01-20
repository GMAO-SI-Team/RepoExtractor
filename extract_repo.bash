#!/usr/bin/env bash

# Based on https://betterdev.blog/minimal-safe-bash-script-template/

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat << EOF # remove the space between << and EOF, this is due to web plugin issue
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [--develop] [--create-repo] [--push] [-o org] -d directory -r repo --newrepo newrepo

This script will be use git filter-repo to extract a single directory from a git repo
and create a new repo with only that directory.

Usage: extract_repo.bash -d <directory> -o <github-org) -r <repo_name> --newrepo <new_repo_name>
Example: extract_repo.bash -d "src" -o "my-org" -r "my-repo" --newrepo "my-new-repo"

The script will create a new directory with the name of the new repo and clone the repo into it.
Then it will run git filter-repo to extract the directory and create a new repo with only that directory.
Finally it will push the new repo to the remote.

Available options:

-h, --help         Print this help and exit
-v, --verbose      Print script debug info
-n, --dry-run      Dry-run
    --develop      Also checkout and push develop branch
    --create-repo  Create the new repo on github
-d, --directory    Name to directory to extract
-o, --org          Github org to extract from (default: GEOS-ESM)
-r, --repo         Github repo to extract from
    --newrepo      Name of new repo to create
    --push         Push the new repo to the remote
EOF
  exit
}

cleanup() {
   trap - SIGINT SIGTERM ERR EXIT
   # script cleanup here
}

setup_colors() {
   if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
      NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
   else
      NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
   fi
}

msg() {
   echo >&2 -e "${1-}"
}

die() {
   local msg=$1
   local code=${2-1} # default exit status 1
   msg "$msg"
   exit "$code"
}

parse_params() {
   # default values of variables set from params
   directory=''
   org='GEOS-ESM'
   repo=''
   HAS_DEVELOP=FALSE
   DRYRUN=FALSE
   CREATE_REPO=FALSE
   DO_PUSH=FALSE

   while :; do
      case "${1-}" in
      -h | --help) usage ;;
      -v | --verbose) set -x ;;
      -n | --dry-run) DRYRUN=TRUE ;;
      --no-color) NO_COLOR=1 ;;
      --develop) HAS_DEVELOP=TRUE ;;
      --create-repo) CREATE_REPO=TRUE ;;
      --push) DO_PUSH=TRUE ;;
      -d | --directory) # directory to extract
         directory="${2-}"
         shift
         ;;
      -o | --org) # GitHub organization
         org="${2-}"
         shift
         ;;
      -r | --repo) # GitHub repository to extract from
         repo="${2-}"
         shift
         ;;
      --newrepo) # New repository name
         newrepo="${2-}"
         shift
         ;;
      -?*) die "Unknown option: $1" ;;
      *) break ;;
      esac
      shift
   done

   args=("$@")

   # check required params and arguments
   [[ -z "${directory-}" ]] && die "Missing required parameter: directory"
   [[ -z "${repo-}" ]] && die "Missing required parameter: repo"
   [[ -z "${newrepo-}" ]] && die "Missing required parameter: newrepo"
   #[[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

   return 0
}

parse_params "$@"
setup_colors

# Main body

# This script will be use git filter-repo to extract a single directory from a git repo
# and create a new repo with only that directory.

# First, error out if CREATE_REPO is FALSE and DO_PUSH is TRUE

if [[ $CREATE_REPO == FALSE ]] && [[ $DO_PUSH == TRUE ]]; then
   die "Cannot push to remote if repo does not exist. Please set --create-repo"
fi

# All commands below will use DRYRUN=FALSE to test the script without actually running the commands.

# Set working directory

WORKDIR=${script_dir}/working-dir

# Set default files directory

DEFAULT_FILES_DIR=${script_dir}/default-files

# Create the working dir

if [[ $DRYRUN == TRUE ]]; then
   msg "${GREEN}mkdir -p ${WORKDIR}${NOFORMAT}"
else
   mkdir -p "${WORKDIR}"
fi

# change to the working directory

if [[ $DRYRUN == TRUE ]]; then
   msg "${GREEN}cd ${WORKDIR}${NOFORMAT}"
else
   cd "${WORKDIR}"
fi

# Clone the repo into the new directory

if [[ $DRYRUN == TRUE ]]; then
   msg "${GREEN}gh repo clone ${org}/${repo} ${newrepo}${NOFORMAT}"
else
   gh repo clone ${org}/${repo} ${newrepo}
fi

# Change into the new directory

if [[ $DRYRUN == TRUE ]]; then
   msg "${GREEN}cd ${newrepo}${NOFORMAT}"
else
   cd ${newrepo}
fi

# Using fd, find the path to the directory ${directory} and store it in a variable

if [[ $DRYRUN == TRUE ]]; then
   path="/path/to/${directory}"
   msg "${GREEN}path=${path}${NOFORMAT}"
else
   path=$(fd -t d ${directory})
   msg "${YELLOW}path=${path}${NOFORMAT}"
fi

# Run git filter-repo to extract the directory

if [[ $DRYRUN == TRUE ]]; then
   msg "${GREEN}git filter-repo --subdirectory-filter ${path}${NOFORMAT}"
else
   git filter-repo --subdirectory-filter ${path}
fi

# Make sure we are on main branch

if [[ $DRYRUN == TRUE ]]; then
   msg "${GREEN}git checkout main${NOFORMAT}"
else
   git checkout main
fi

# Create a new repo on GitHub if CREATE_REPO=TRUE

if [[ $CREATE_REPO == TRUE ]]; then
   if [[ $DRYRUN == TRUE ]]; then
      msg "${GREEN}gh repo create ${org}/${newrepo} --public ${NOFORMAT}"
   else
      gh repo create ${org}/${newrepo} --public 
   fi
fi

# Add the new origin as a remote

if [[ $DRYRUN == TRUE ]]; then
   msg "${GREEN}git remote add origin git@github.com:${org}/${newrepo}.git${NOFORMAT}"
else
   git remote add origin git@github.com:${org}/${newrepo}.git
fi

# Copy the files from the default-files directory to the new repo

if [[ $DRYRUN == TRUE ]]; then
   msg "${GREEN}cp -Rv ${DEFAULT_FILES_DIR}/ ${WORKDIR}/${newrepo}${NOFORMAT}"
else
   cp -Rv ${DEFAULT_FILES_DIR}/ ${WORKDIR}/${newrepo}
fi

# Create a new README.md file

if [[ $DRYRUN == TRUE ]]; then
   msg "${GREEN}echo '# ${newrepo}' > ${WORKDIR}/${newrepo}/README.md${NOFORMAT}"
else
   echo "# ${newrepo}" > ${WORKDIR}/${newrepo}/README.md
fi

# Add the files to the new repo

if [[ $DRYRUN == TRUE ]]; then
   msg "${GREEN}git add .${NOFORMAT}"
else
   git add .
fi

# Commit the changes

if [[ $DRYRUN == TRUE ]]; then
   msg "${GREEN}git commit -m "Add default files"${NOFORMAT}"
else
   git commit -m "Add default files"
fi

# If the repo has a develop branch, checkout and merge with main

if [[ $HAS_DEVELOP == TRUE ]]; then

   # Merge the main branch into develop and add, commit, and push the changes
   if [[ $DRYRUN == TRUE ]]; then
      msg "${GREEN}git checkout develop${NOFORMAT}"
      msg "${GREEN}git merge --no-edit main${NOFORMAT}"
   else
      git checkout develop
      git merge --no-edit main
   fi
fi

# Push the new repo to the remote if DO_PUSH=TRUE

if [[ $DO_PUSH == TRUE ]]; then
   if [[ $DRYRUN == TRUE ]]; then
      msg "${GREEN}git checkout main${NOFORMAT}"
      msg "${GREEN}git push -u origin main${NOFORMAT}"
   else
      git checkout main
      git push -u origin main
   fi

   if [[ $HAS_DEVELOP == TRUE ]]; then
      if [[ $DRYRUN == TRUE ]]; then
         msg "${GREEN}git checkout develop${NOFORMAT}"
         msg "${GREEN}git push -u origin develop${NOFORMAT}"
      else
         git checkout develop
         git push -u origin develop
      fi
   fi
fi

# Output parameters

msg "${RED}Read parameters:${NOFORMAT}"
msg "- directory: ${directory}"
msg "- repo: ${repo}"
msg "- org: ${org}"
msg "- newrepo: ${newrepo}"
msg "- develop: ${HAS_DEVELOP}"
msg "- create-repo: ${CREATE_REPO}"
msg "- push: ${DO_PUSH}"
#msg "- arguments: ${args[*]-}"
