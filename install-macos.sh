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
  xcode-select --install >$STDOUT_REDIR 2>&1
  brew install --quiet wget >$STDOUT_REDIR 2>&1 || return 1
}

download_and_extract_source_code() {
  local wget_opts=()
  if [ "$VERBOSE" != "true" ]; then
    wget_opts+="-q"
  fi

  wget "${wget_opts[@]}" https://mirrors.edge.kernel.org/pub/software/scm/git/git-"$GIT_VERSION".tar.gz || return 1
  tar -xzf git-"$GIT_VERSION".tar.gz >$STDOUT_REDIR 2>&1 || return 1
}

install_git() {
  cd git-"$GIT_VERSION" >$STDOUT_REDIR 2>&1 || return 1

  NO_GETTEXT=1 make prefix="$GIT_INSTALL_DIR" all >$STDOUT_REDIR 2>&1 || return 1
  NO_GETTEXT=1 make prefix="$GIT_INSTALL_DIR" install >$STDOUT_REDIR 2>&1 || return 1

  cd ~- >$STDOUT_REDIR 2>&1
}

if [ -z "$GIT_VERSION" ]; then
  fail "GIT_VERSION is not set."
fi

if [ -z "$GIT_INSTALL_DIR" ]; then
  fail "GIT_INSTALL_DIR is not set."
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
  STDOUT_REDIR=/dev/stdout
else
  STDOUT_REDIR=/dev/null
fi

install_dependencies || fail "Failed to install dependencies."
download_and_extract_source_code || fail "Failed to download specified Git version."
install_git || fail "Failed to install Git."

if [ "$(git --version)" != "git version $GIT_VERSION" ]; then
  fail "Installation failed."
fi

echo "Successfully installed Git version $GIT_VERSION."
