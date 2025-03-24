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

download_and_extract_release() {
  local release_assets=$(GH_REPO=git-for-windows/git gh release view v$GIT_VERSION --json assets --jq '.assets[] | .name + "\t" + .url') || return 10
  local asset=$(awk -F '\t' '$1~"^PortableGit.+64-bit.7z.exe" {print}' <<<"$release_assets" | head -1)
  local asset_name=$(awk -F '\t' '{print $1}' <<<"$asset")
  local asset_url=$(awk -F '\t' '{print $2}' <<<"$asset")

  if [ -z "$asset_name" ] || [ -z "$asset_url" ]; then
    return 11
  fi

  curl -L --output $asset_name $asset_url >&3 2>&4 || return 12
  7z x $asset_name -r -aoa -o"git-$GIT_VERSION" >&3 2>&4 || return 13
}

install_git() {
  mkdir -p "$GIT_INSTALL_DIR" >&3 2>&4 || return 30
  cp -r git-$GIT_VERSION/* "$GIT_INSTALL_DIR" >&3 2>&4 || return 31
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

# Rename current git executable to prevent it from taking precedence over the new one
current_git=$(which git)

if [ -n "$current_git" ] && [ -f "$current_git" ]; then
  mv $current_git $current_git.old
fi

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

download_and_extract_release || fail "Failed to download specified Git version." $?
install_git || fail "Failed to install Git." $?

if [ "$(git --version)" != "git version $GIT_VERSION" ]; then
  fail "Installation failed."
fi

echo "Successfully installed Git version $GIT_VERSION."
