#!/bin/zsh
set -e

print_section() {
  echo "\n🔧 $1...\n"
}

# Request sudo access upfront
print_section "Requesting sudo access"
if sudo -v; then
  # Keep sudo session alive
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
else
  echo "❌ Failed to obtain sudo privileges."
  exit 1
fi

# --- Xcode Command Line Tools ---

print_section "Checking Xcode Command Line Tools"
if ! xcode-select -p &>/dev/null; then
  echo "Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "❗ Installation in progress. Rerun this script when done."
  exit 1
else
  echo "✅ Xcode Command Line Tools already installed."
fi

# --- macOS Settings ---

print_section "Applying macOS settings"

# General Finder and Dock preferences
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock mru-spaces -bool false
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Screenshots
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture disable-shadow -bool true
defaults write com.apple.screencapture type -string "png"

# Finder visuals and desktop icons
defaults write com.apple.finder DisableAllAnimations -bool true
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false
defaults write com.apple.Finder AppleShowAllFiles -bool true

# Time Machine
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool YES

# Input preferences
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Disable Spotlight shortcut
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 "{enabled = 0;}"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 65 "{enabled = 0;}"

# Set Dock size to minimum (16 is the smallest allowed)
defaults write com.apple.dock tilesize -int 16

# Enable magnification (optional, if not already enabled)
defaults write com.apple.dock magnification -bool false

killall Dock

# --- Dotfiles ---

print_section "Setting up dotfiles"
if [ -d "$HOME/dotfiles" ]; then
  echo "✅ Dotfiles already exist. Skipping clone."
else
  rm "$HOME/.zshrc" 2> /dev/null || true
  git clone --bare https://github.com/Morniak/dotfiles $HOME/dotfiles
  git --git-dir=$HOME/dotfiles/ --work-tree=$HOME checkout
  git --git-dir=$HOME/dotfiles/ --work-tree=$HOME config --local status.showUntrackedFiles no
fi

# --- Homebrew ---

print_section "Installing Homebrew"
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    echo "❌ Homebrew installed but 'brew' not found."
    exit 1
  fi
else
  echo "✅ Homebrew already installed."
  eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || \
  eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null
fi

HOMEBREW_PREFIX=$(brew --prefix)
echo 'eval "$('"$HOMEBREW_PREFIX"'/bin/brew shellenv)"' >> ~/.zprofile
eval "$("$HOMEBREW_PREFIX"/bin/brew shellenv)"

brew analytics off
brew update

# --- CLI Tools ---

print_section "Installing CLI tools"
brew install fzf zoxide wget bat jq zsh-autosuggestions spaceship

# --- GUI Apps ---

print_section "Installing GUI apps"
brew install --cask raycast iterm2 firefox vlc spotify 1password proxyman visual-studio-code

# --- Fonts ---

print_section "Installing fonts"
brew install --cask sf-symbols font-sf-mono font-sf-pro font-hack-nerd-font font-jetbrains-mono font-fira-code

# --- Custom Keyboard Layout ---

print_section "Installing Aer Keyboard Layout"
AER_REPO="https://github.com/Morniak/aer.git"
AER_DIR="/tmp/aer"

[ -d "$AER_DIR" ] && echo "🧹 Removing previous clone" && rm -rf "$AER_DIR"

echo "📥 Cloning Aer layout..."
git clone "$AER_REPO" "$AER_DIR"

LAYOUT_SRC="$AER_DIR/v2/osx/aer-v2.keylayout"
LAYOUT_DEST="/Library/Keyboard Layouts/"

if [ -f "$LAYOUT_SRC" ]; then
  echo "🛠️ Installing Aer layout (requires sudo)"
  sudo cp "$LAYOUT_SRC" "$LAYOUT_DEST"
  echo "✅ Aer keyboard layout installed."
else
  echo "❌ Layout file not found: $LAYOUT_SRC"
fi

echo "\n📌 Manual step required:"
echo "1. System Settings > Keyboard > Input Sources"
echo "2. Add 'Aer v2'"
echo "3. Set as default if desired"
echo "4. Log out and back in if needed\n"

open "x-apple.systempreferences:com.apple.Keyboard-Settings.extension"
read

# --- Raycast Extensions ---

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

echo "\n✅ All Raycast extensions processed."

# --- Mac App Store apps ---

# print_section "Installing Mac App Store apps"
# command -v mas &>/dev/null || brew install mas
# mas install 497799835 # Xcode

# --- Cleanup ---

print_section "Cleaning up"
brew cleanup
sudo -k

echo "\n✅ Installation complete!\n"
