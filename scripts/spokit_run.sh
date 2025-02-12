#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2086,SC1001,SC2317
# shellcheck source="$HOME/.bashrc"
# shellcheck source="${envPath}"

source ${HOME}/.bashrc

tmux new-session -d -s spokit

tmux send-keys -t spokit "${SPOKIT_INST_DIR}/spokit.sh $1" Enter

tmux a -t spokit

