# gh-switch

Switch between multiple GitHub accounts instantly.

## Requirements
- GitHub CLI (`gh`)
- Git
- GitHub Personal Access Token for each account

## Install

### Homebrew
```bash
brew tap sisobus/tap
brew install gh-switch
ghs setup  # Set up your accounts
```

### Manual
```bash
# Download and make executable
curl -O https://raw.githubusercontent.com/sisobus/gh-switch/main/ghs
chmod +x ghs
sudo mv ghs /usr/local/bin/

# Set up your accounts
ghs setup
```

## Usage
```bash
ghs main        # Switch to main account
ghs second      # Switch to secondary account
ghs             # Show current status
ghs clean       # Clean git URL rewrites
```

## What it does
- Switches GitHub CLI account
- Updates git config (user.name, user.email)
- Sets HTTPS credentials
- Configures git URLs with token auth

## Get Personal Access Token
GitHub Settings → Developer settings → Personal access tokens → Generate new token (classic)

Required scopes: `repo`, `workflow` (optional), `admin:org` (optional)

## Uninstall

### Homebrew
```bash
brew uninstall gh-switch
```

### Manual
```bash
sudo rm /usr/local/bin/ghs
rm -rf ~/.config/gh-switch
```