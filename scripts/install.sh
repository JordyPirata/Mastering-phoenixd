#!/bin/bash

# This script is for install phoenix on a Linux system.

TAG="0.6.0"
PHOENIXD_URL="github.com/ACINQ/phoenixd/releases/download/v${TAG}"
PHOENIXD_ZIP="${PHOENIXD_URL}/phoenixd-${TAG}-linux-x64.zip"
VERIFIER_URL="https://raw.githubusercontent.com/btcgdl/Mastering-phoenixd/master/scripts/verify.sh"

echo ""
echo ""
echo "⚡️ Welcome to Mastering phoenixd installer"
echo "-----------------------------------------"
echo "Installing phoenixd ${TAG} from ${PHOENIXD_URL}"
echo ""
read -p "Absolute install directory path (default: $HOME/.local/bin): " USER_INSTALL_DIR

INSTALL_DIR="${USER_INSTALL_DIR:-$HOME/.local/bin}"

# Create installation directory
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# Download and extract phoenixd
echo "Downloading phoenixd..."
if ! wget -q "$PHOENIXD_ZIP"; then
  echo "❌ Failed to download phoenixd from ${PHOENIXD_ZIP}" >&2
  exit 1
fi

if [[ ! -f "verify.sh" ]]; then
  echo "Downloading the verification script..."
  if ! wget -q "$VERIFIER_URL"; then
    echo "❌ Failed to download the verification script." >&2
    exit 1
  fi
  chmod +x verify.sh
fi

./verify.sh
if [[ $? -ne 0 ]]; then
  echo "❌ Verification failed, aborting installation"
  exit 1
fi
rm verify.sh

unzip -j phoenixd-${TAG}-linux-x64.zip

rm -f phoenixd-${TAG}-linux-x64.zip

# Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && [[ "$INSTALL_DIR" == "$HOME/.local/bin" ]]; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
  echo "Added $HOME/.local/bin to PATH in ~/.bashrc"
  echo "Run 'source ~/.bashrc' to use phoenixd"
fi

echo "✅ phoenixd installed to $INSTALL_DIR"

# optionally create a systemd service to start alby hub
read -p "Do you want to setup a systemd service (requires sudo permission)? (y/n): " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo ""
  echo ""
  echo "Run 'phoenixd' to start the daemon"
  echo "Run 'phoenix-cli' to interact with the daemon"
  echo "✅ DONE"
  exit
fi

sudo tee /etc/systemd/system/phoenixd.service > /dev/null << EOF
[Unit]
Description=Phoenix Daemon
After=network.target

[Service]
ExecStart=$INSTALL_DIR/phoenixd --agree-to-terms-of-service --chain testnet
User=$USER
Restart=always
RestartSec=5
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

echo ""
sudo systemctl enable phoenixd
echo ""
sudo systemctl start phoenixd

echo "Run 'sudo systemctl start/stop phoenixd' to start/stop Phoenix Daemon"