#!/bin/zsh
set -e

print_section() {
  echo "\n🔧 $1...\n"
}

# Ask for sudo password upfront
print_section "Requesting sudo access"
if sudo -v; then
  # Keep-alive: update the existing `sudo` time stamp until the script finishes
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
else
  echo "❌ Failed to obtain sudo privileges."
  exit 1
fi

# 1. Install Xcode Command Line Tools
print_section "Checking Xcode Command Line Tools"
if ! xcode-select -p &>/dev/null; then
  echo "Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "❗ Please wait for installation to finish, then rerun this script."
  exit 1
else
  echo "✅ Xcode Command Line Tools already installed."
fi

# 2. Install Homebrew
print_section "Installing Homebrew"

if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Detect Homebrew install location and set environment for current script
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    echo "❌ Homebrew installed but 'brew' not found in expected locations."
    exit 1
  fi
else
  echo "✅ Homebrew already installed."
  eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || \
  eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null
fi

brew analytics off
brew update

# 3. Install Brew Formulae
print_section "Installing CLI tools"
brew install zoxide
brew install wget
brew install bat
brew install jq
brew install starship
brew install zsh-autosuggestions

# 4. Install GUI apps
print_section "Installing GUI apps"
brew install --cask raycast
brew install --cask iterm2
brew install --cask firefox
brew install --cask vlc
brew install --cask spotify
brew install --cask 1password
brew install --cask proxyman
brew install --cask visual-studio-code

# 5. Fonts
print_section "Installing fonts"
brew tap homebrew/cask-fonts
brew install --cask sf-symbols
brew install --cask font-sf-mono
brew install --cask font-sf-pro
brew install --cask font-hack-nerd-font
brew install --cask font-jetbrains-mono
brew install --cask font-fira-code

# 6. Mac App Store apps
print_section "Installing Mac App Store apps"
if ! command -v mas &>/dev/null; then
  brew install mas
fi
mas install 497799835 # Xcode

# 7. macOS Defaults
print_section "Applying macOS settings"

# Prevent .DS_Store files from being created on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Automatically hide the Dock when not in use
defaults write com.apple.dock autohide -bool true

# Disable automatic rearrangement of Spaces based on recent use
defaults write com.apple.dock "mru-spaces" -bool false

# Always show all file extensions in Finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Set custom location for screenshots
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"

# Disable shadow around screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# Set screenshot format to PNG
defaults write com.apple.screencapture type -string "png"

# Disable Finder window animations
defaults write com.apple.finder DisableAllAnimations -bool true

# Do not show external hard drives on the desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false

# Do not show internal hard drives on the desktop
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false

# Do not show mounted network servers on the desktop
defaults write com.apple.finder ShowMountedServersOnDesktop -bool false

# Do not show removable media (USB keys, etc.) on the desktop
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false

# Show hidden files in Finder
defaults write com.apple.Finder AppleShowAllFiles -bool true

# Prevent Time Machine from prompting to use new hard drives as backup volumes
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool YES

defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# 8. Dotfiles
print_section "Setting up dotfiles"
if [ -d "$HOME/dotfiles" ]; then
  echo "✅ Dotfiles already exist. Skipping clone."
else
  git clone --bare https://github.com/Morniak/dotfiles $HOME/dotfiles
  git --git-dir=$HOME/dotfiles/ --work-tree=$HOME checkout
  git --git-dir=$HOME/dotfiles/ --work-tree=$HOME config --local status.showUntrackedFiles no
fi

# 9. Source Zsh config
print_section "Sourcing .zshrc"

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

if [ -f "$HOME/.zshrc" ]; then
  source "$HOME/.zshrc"
  echo "✅ .zshrc sourced"
else
  echo "⚠️ No .zshrc file found"
fi

# 10. Keyboard layout
print_section "Installing Aer Keyboard Layout"

AER_REPO="https://github.com/Morniak/aer.git"
AER_DIR="/tmp/aer"

# Clone the repo into /tmp
if [ -d "$AER_DIR" ]; then
  echo "🧹 Removing previous clone from $AER_DIR"
  rm -rf "$AER_DIR"
fi

echo "📥 Cloning Aer layout into $AER_DIR..."
git clone "$AER_REPO" "$AER_DIR"

# Install the keyboard layout (requires sudo)
LAYOUT_SRC="$AER_DIR/v2/osx/aer-v2.keylayout"
LAYOUT_DEST="/Library/Keyboard Layouts/"

if [ -f "$LAYOUT_SRC" ]; then
  echo "🛠️ Installing Aer layout to $LAYOUT_DEST (requires sudo)"
  sudo cp "$LAYOUT_SRC" "$LAYOUT_DEST"
  echo "✅ Aer keyboard layout installed successfully."
else
  echo "❌ Layout file not found at $LAYOUT_SRC"
fi

echo "\n📌 Manual step required:"
echo "1. Go to System Settings > Keyboard > Input Sources."
echo "2. Click the '+' button and select 'Aer v2' from the list."
echo "3. (Optional) Set it as your default input source."
echo "4. Log out and back in if the layout doesn't appear immediately.\n"

open "x-apple.systempreferences:com.apple.Keyboard-Settings.extension"
read

# 11. Raycast extensions
print_section "Raycast Extension Setup"

raycast_extensions=(
  "raycast/github"
  "erics118/change-case"
  "thomas/color-picker"
)

for extension in "${raycast_extensions[@]}"; do
  echo "\n🧩 Opening Raycast extension: $extension"
  open "raycast://extensions/$extension"
  echo "⏳ Press [Enter] after installing or skipping '$extension'..."
  read
done

echo "\n✅ All Raycast extensions have been processed."

# 12. Cleanup
print_section "Cleaning up"
brew cleanup
sudo -k

echo "\n✅ Installation complete!\n"
