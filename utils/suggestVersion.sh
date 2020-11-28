#!/bin/bash
set -e
IS_PRE=""
for flag in "$@" ; do
    case "${flag}" in
        p|pre|prerelease) IS_PRE="1";;
    esac
done

IS_CLEAN="$(git diff-index --quiet HEAD; echo $?)"

if [[ $IS_CLEAN != 0 ]]; then 
  >&2 echo "Working directory is not clean. Refusing to proceed!" 
  exit 1
fi
>&2 echo "Working directory is clean. Proceeding!" 
IS_FAILING="$(npx jest --ci --bail --useStderr; echo $?)"
if [[ $IS_FAILING != 0 ]]; then 
  >&2 echo "Working directory tests are failing. Refusing to proceed!" 
  exit 1
fi
>&2 echo "Working directory tests are passing. Proceeding!" 


OLD_TAG="$(git describe --tags "$(git rev-list --tags --max-count=1)")"
TEST_DIFFER="$(git diff-index --quiet ${OLD_TAG} -- test jest.conf.js; echo $?)"
if [[ $TEST_DIFFER != 0 ]]; then
  >&2 echo "Tests differ!"
fi
git checkout "${OLD_TAG}" -- test jest.config.js
TEST_STATUS="$(npx jest --ci --bail --useStderr; echo $?)"
OLD_VERSION=OLD_TAG
if [[ $TEST_STATUS != 0 ]]; then
  >&2 echo "We fail old tests from tag ${OLD_TAG}. Suggesting a major bump!"
  echo 'major'
elif [[ $TEST_DIFFER != 0 ]]; then
  >&2 echo "Tests have changed since tag ${OLD_TAG}. Suggesting a minor bump!"
  echo 'minor'
else
  >&2 echo "We have the same tests as tag ${OLD_TAG}. Suggesting a patch bump!"
  echo 'patch'
fi
git checkout -- ./
