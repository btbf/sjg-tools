#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2086,SC1001,SC2317
# shellcheck source="$HOME/.bashrc"
# shellcheck source="${envPath}"

source ${HOME}/.bashrc

tmux new-session -d -s sjgtool

tmux send-keys -t sjgtool ${CNM_INST_DIR}/sjgtool.sh Enter

tmux a -t sjgtool

