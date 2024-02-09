#!/usr/bin/env bash

echo PATH="$HOME/.local/bin:$PATH" >> $HOME/.bashrc
echo export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH" >> $HOME/.bashrc
echo export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH" >> $HOME/.bashrc
echo export NODE_HOME=$HOME/cnode >> $HOME/.bashrc
echo export CARDANO_NODE_SOCKET_PATH="$HOME/cnode/db/socket" >> $HOME/.bashrc

echo export NODE_CONFIG=mainnet >> $HOME/.bashrc
echo export NODE_NETWORK='"--mainnet"' >> $HOME/.bashrc
echo export CARDANO_NODE_NETWORK_ID=mainnet >> $HOME/.bashrc

echo alias cnode='"journalctl -u cardano-node -f"' >> $HOME/.bashrc
echo alias cnstart='"sudo systemctl start cardano-node"' >> $HOME/.bashrc
echo alias cnrestart='"sudo systemctl reload-or-restart cardano-node"' >> $HOME/.bashrc
echo alias cnstop='"sudo systemctl stop cardano-node"' >> $HOME/.bashrc
echo alias glive="'cd $HOME/cnode/scripts; ./gLiveView.sh'" >> $HOME/.bashrc

tmux new-session -d -s session

tmux send-keys -t session:0 $HOME/sjg-tool/sjgtool.sh Enter

tmux a -t session