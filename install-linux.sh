#!/bin/bash

fail() {
  local msg="$1"
  local ret="$2"

  if [ -z "$ret" ]; then
    ret=1
  fi

  echo "Error: $msg" >&2
  exit $ret
}

install_dependencies() {
  sudo apt-get update >&3 2>&4 || return 10
  sudo apt-get install wget libz-dev libssl-dev libcurl4-gnutls-dev libexpat1-dev gettext cmake gcc >&3 2>&4 || return 11
}

download_and_extract_source_code() {
  local wget_opts=()
  if [ "$VERBOSE" != "true" ]; then
    wget_opts+="-q"
  fi

  wget "${wget_opts[@]}" https://mirrors.edge.kernel.org/pub/software/scm/git/git-"$GIT_VERSION".tar.gz || return 30
  tar -xzf git-"$GIT_VERSION".tar.gz >&3 2>&4 || return 31
}

install_git() {
  cd git-"$GIT_VERSION" >&3 2>&4 || return 50

  make prefix="$GIT_INSTALL_DIR" all >&3 2>&4 || return 51
  make prefix="$GIT_INSTALL_DIR" install >&3 2>&4 || return 52

  cd ~- >&3 2>&4
}

if [ -z "$GIT_VERSION" ]; then
  fail "GIT_VERSION is not set." 128
fi

if [ -z "$GIT_INSTALL_DIR" ]; then
  fail "GIT_INSTALL_DIR is not set." 128
fi

if [ -z "$OUTPUT_FILE" ]; then
  fail "OUTPUT_FILE is not set." 128
fi

GIT_EXECUTABLE_DIR="$GIT_INSTALL_DIR/bin"

>$OUTPUT_FILE

echo "Installing Git version $GIT_VERSION."
export PATH="$GIT_EXECUTABLE_DIR:$PATH"

if command -v git >/dev/null 2>&1 && [ "$(git --version)" == "git version $GIT_VERSION" ]; then
  echo "Git version $GIT_VERSION is already available. Skipping installation."
  echo "installation-skipped=true" >>$OUTPUT_FILE
  exit 0
fi

if [ "$VERBOSE" == "true" ]; then
  exec 3>&1
  exec 4>&2
else
  exec 3>/dev/null
  exec 4>/dev/null
fi

install_dependencies || fail "Failed to install dependencies." $?
download_and_extract_source_code || fail "Failed to download specified Git version." $?
install_git || fail "Failed to install Git." $?

if [ "$(git --version)" != "git version $GIT_VERSION" ]; then
  fail "Installation failed."
fi

echo "Successfully installed Git version $GIT_VERSION."
