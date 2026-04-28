#!/usr/bin/env bash
set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
  echo "Run this script with sudo"
  exit 1
fi

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME="$(eval echo "~$REAL_USER")"

# Pinned versions — update to upgrade
NODE_MAJOR="${NODE_MAJOR:-23}"
NEOVIM_VERSION="${NEOVIM_VERSION:-latest}"  # set to e.g. v0.11.0 to pin

installed()     { command -v "$1" &>/dev/null; }
apt_installed() { dpkg -s "$1" &>/dev/null 2>&1; }

# Call installer only when the binary / package is absent
ensure()     { if installed "$1";     then echo "$1: already installed, skipping"; else "$2"; fi; }
ensure_apt() { if apt_installed "$1"; then echo "$1: already installed, skipping"; else "$2"; fi; }

apt-get update -qq
apt-get install -y curl ca-certificates build-essential
install -m 0755 -d /etc/apt/keyrings

install_docker() {
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  groupadd -f docker
  usermod -aG docker "$REAL_USER"
}

install_python_env() {
  apt-get install -y python3-venv python3-pip
}

install_kitty() {
  sudo -u "$REAL_USER" sh -c 'curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh'
  ln -sf "$REAL_HOME/.local/kitty.app/bin/kitty"  /usr/local/bin/kitty
  ln -sf "$REAL_HOME/.local/kitty.app/bin/kitten" /usr/local/bin/kitten
  update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/local/bin/kitty 100
}

install_zsh() {
  apt-get install -y zsh
  chsh -s "$(which zsh)" "$REAL_USER"
}

install_fd() {
  apt-get install -y fd-find
  ln -sf "$(which fdfind)" /usr/local/bin/fd
}

install_fzf() {
  sudo -u "$REAL_USER" git clone --depth 1 https://github.com/junegunn/fzf.git "$REAL_HOME/.fzf"
  sudo -u "$REAL_USER" "$REAL_HOME/.fzf/install" --key-bindings --completion --no-update-rc
  ln -sf "$REAL_HOME/.fzf/bin/fzf" /usr/local/bin/fzf
}

install_tmux() {
  apt-get install -y tmux
}

install_nvim() {
  local url
  if [[ "$NEOVIM_VERSION" == "latest" ]]; then
    url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
  else
    url="https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/nvim-linux-x86_64.tar.gz"
  fi
  curl -L "$url" -o /tmp/nvim.tar.gz
  tar -C /opt -xzf /tmp/nvim.tar.gz
  rm /tmp/nvim.tar.gz
  ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
}

install_clangd() {
  apt-get install -y clangd tree-sitter-cli
}

install_node() {
  curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash -
  apt-get install -y nodejs
}

ensure     docker       install_docker
ensure_apt python3-venv install_python_env
ensure     kitty        install_kitty
ensure     zsh          install_zsh
ensure_apt fd-find      install_fd
ensure     fzf          install_fzf
ensure     tmux         install_tmux
ensure     nvim         install_nvim
ensure_apt clangd       install_clangd
ensure     node         install_node
