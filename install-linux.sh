#!/bin/bash

GIT_INSTALL_DIR="${GIT_INSTALL_DIR/'~'/"$HOME"}"
GIT_EXECUTABLE_DIR="$GIT_INSTALL_DIR/bin"

echo "Installing Git version $GIT_VERSION into $GIT_INSTALL_DIR".
export PATH="$GIT_EXECUTABLE_DIR:$PATH"

if [ "$(git --version || git -v)" == "git version $GIT_VERSION" ]; then
  echo "Git version $GIT_VERSION is already available. Skipping installation."
  exit 0
fi

WGET_OPTS=()

if [ "$VERBOSE" == "true" ]; then
  STDOUT_REDIR=/dev/stdout
else
  STDOUT_REDIR=/dev/null
  WGET_OPTS+="-q"
fi

fail() {
  local msg="$1"
  local ret="$2"

  if [ -z "$ret" ]; then
    ret=1
  fi

  echo "error: $msg" >&2
  exit $ret
}

sudo apt-get update >$STDOUT_REDIR || fail "unable to update apt repository"
sudo apt-get install libz-dev libssl-dev libcurl4-gnutls-dev libexpat1-dev gettext cmake gcc >$STDOUT_REDIR || fail "unable to install compiler dependencies"

wget "${WGET_OPTS[@]}" https://mirrors.edge.kernel.org/pub/software/scm/git/git-"$GIT_VERSION".tar.gz || fail "unable to download specified git version"

tar -xzf git-"$GIT_VERSION".tar.gz >$STDOUT_REDIR || fail "unable to extract source code"
cd git-"$GIT_VERSION"

sudo make prefix="$GIT_INSTALL_DIR" all || fail "unable to make"
sudo make prefix="$GIT_INSTALL_DIR" install || fail "unable to make"

if [ "$(git --version || git -v)" != "git version $GIT_VERSION" ]; then
  fail "installation failed"
  exit 1
fi

echo "Successfully installed Git version $GIT_VERSION."
