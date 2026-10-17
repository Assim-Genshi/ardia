# Shared environment for the Ardia engine build: plain Chromium + ungoogled-chromium + our
# series (docs/engine-build.md). Source this file.
export CB=~/chromium-build
# The Ardia checkout (game-resource.sh reads the offline game from it): the one this file is in, or
# ~/Documents/ardia for the copy in ~/chromium-build/scripts that the step scripts source.
if [[ -z "${AC_REPO:-}" ]]; then
  _ac_repo="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/../../.." && pwd)"
  if [[ ! -f "$_ac_repo/engine/patches/series" ]]; then
    if [[ -n "${GITHUB_WORKSPACE:-}" && -f "$GITHUB_WORKSPACE/engine/patches/series" ]]; then
      _ac_repo="$GITHUB_WORKSPACE"
    else
      _ac_repo="$HOME/Documents/ardia"
    fi
  fi
  export AC_REPO="$_ac_repo"
  unset _ac_repo
fi
if [[ -d "$CB/depot_tools" && ! -f "$CB/depot_tools/python3_bin_reldir.txt" ]]; then
  DEPOT_TOOLS_UPDATE=1 "$CB/depot_tools/update_depot_tools" || true
fi
export DEPOT_TOOLS_UPDATE=0
export PATH="$CB/depot_tools:$PATH"
# The Chromium tag step 1 checks out, and the ungoogled-chromium tags made for exactly it
# (its patches and domain substitution lists are version-specific).
export CHROMIUM_VERSION=154.0.8037.97
export UNGOOGLED_TAG=154.0.8037.97-1
export UNGOOGLED_MACOS_TAG=154.0.8037.97-1.1
export TARGET_CPU="${TARGET_CPU:-arm64}"
export GN_OUT_CONFIGS="${GN_OUT_CONFIGS:-Release_GN_${TARGET_CPU}}"
# Low priority for everything heavy. CPU-bound steps (compile/link) run in the
# background QoS band (-b): on this M5 Pro that confines them to the 10
# lower-tier cores and throttles their disk I/O. Background QoS also throttles
# network traffic to a crawl, so network-bound steps (sync) use the utility
# clamp with throttled disk I/O instead.
if [[ "${CI:-}" == "true" ]]; then
  lowprio() { "$@"; }
  lowprio_net() { "$@"; }
else
  lowprio() { taskpolicy -b nice -n 19 "$@"; }
  lowprio_net() { taskpolicy -c utility -d throttle nice -n 19 "$@"; }
fi
export DEPOT_TOOLS_METRICS=0
