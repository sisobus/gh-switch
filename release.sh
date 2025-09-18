#!/bin/bash

# gh-switch Release Script
# Usage: ./release.sh <version> [commit message]
# Example: ./release.sh 1.0.3 "Add new feature"

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
HOMEBREW_TAP_PATH="../homebrew-tap"
FORMULA_FILE="$HOMEBREW_TAP_PATH/Formula/gh-switch.rb"

# Functions
print_header() {
    echo ""
    echo -e "${CYAN}${BOLD}===================================${NC}"
    echo -e "${CYAN}${BOLD}  gh-switch Release Script  ${NC}"
    echo -e "${CYAN}${BOLD}===================================${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}→ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ Error: $1${NC}"
    exit 1
}

print_warning() {
    echo -e "${YELLOW}⚠ Warning: $1${NC}"
}

# Check arguments
if [ -z "$1" ]; then
    print_error "Version number required!"
    echo "Usage: $0 <version> [commit message]"
    echo "Example: $0 1.0.3 \"Add new feature\""
    exit 1
fi

VERSION=$1
COMMIT_MESSAGE=${2:-"Release v$VERSION"}

# Validate version format
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_error "Invalid version format. Use semantic versioning (e.g., 1.0.3)"
fi

print_header

# Check prerequisites
print_step "Checking prerequisites..."

# Check if we're in the right directory
if [ ! -f "ghs" ]; then
    print_error "Must be run from gh-switch directory"
fi

# Check if homebrew-tap exists
if [ ! -d "$HOMEBREW_TAP_PATH" ]; then
    print_error "homebrew-tap not found at $HOMEBREW_TAP_PATH"
fi

# Check if Formula file exists
if [ ! -f "$FORMULA_FILE" ]; then
    print_error "Formula file not found at $FORMULA_FILE"
fi

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    print_warning "You have uncommitted changes in gh-switch"
    read -p "Do you want to continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check homebrew-tap for uncommitted changes
if [ -n "$(cd $HOMEBREW_TAP_PATH && git status --porcelain)" ]; then
    print_warning "You have uncommitted changes in homebrew-tap"
    read -p "Do you want to continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

print_success "Prerequisites checked"
echo ""

# Step 1: Update version in ghs
print_step "Updating version in ghs to $VERSION..."
sed -i '' "s/^VERSION=\".*\"$/VERSION=\"$VERSION\"/" ghs
print_success "Updated version in ghs"

# Step 2: Commit and push changes
print_step "Committing changes..."
git add ghs
git commit -m "$COMMIT_MESSAGE" || {
    print_warning "No changes to commit (version might be already set)"
}

print_step "Pushing to master..."
git push origin master
print_success "Pushed to master"

# Step 3: Create and push tag
print_step "Creating tag v$VERSION..."
git tag -a "v$VERSION" -m "$COMMIT_MESSAGE"

print_step "Pushing tag..."
git push origin "v$VERSION"
print_success "Tag v$VERSION created and pushed"

# Step 4: Calculate SHA256
print_step "Calculating SHA256 for release tarball..."
SHA256=$(curl -sL "https://github.com/sisobus/gh-switch/archive/refs/tags/v$VERSION.tar.gz" | shasum -a 256 | cut -d' ' -f1)

if [ -z "$SHA256" ]; then
    print_error "Failed to calculate SHA256"
fi

print_success "SHA256: $SHA256"

# Step 5: Update homebrew-tap Formula
print_step "Updating homebrew-tap Formula..."

cd "$HOMEBREW_TAP_PATH"

# Update Formula file
sed -i '' "s|url \"https://github.com/sisobus/gh-switch/archive/refs/tags/v.*\.tar\.gz\"|url \"https://github.com/sisobus/gh-switch/archive/refs/tags/v$VERSION.tar.gz\"|" Formula/gh-switch.rb
sed -i '' "s|sha256 \"[a-f0-9]*\"|sha256 \"$SHA256\"|" Formula/gh-switch.rb
sed -i '' "s|version \".*\"|version \"$VERSION\"|" Formula/gh-switch.rb

print_success "Formula updated"

# Step 6: Commit and push homebrew-tap
print_step "Committing homebrew-tap changes..."
git add Formula/gh-switch.rb
git commit -m "Update gh-switch to v$VERSION

$COMMIT_MESSAGE"

print_step "Pushing homebrew-tap..."
git push origin master
print_success "homebrew-tap updated"

# Return to original directory
cd - > /dev/null

# Success!
echo ""
echo -e "${GREEN}${BOLD}===================================${NC}"
echo -e "${GREEN}${BOLD}  Release v$VERSION Complete!  ${NC}"
echo -e "${GREEN}${BOLD}===================================${NC}"
echo ""
echo -e "${CYAN}Users can now install/update with:${NC}"
echo "  brew update"
echo "  brew upgrade gh-switch"
echo ""
echo -e "${CYAN}Or fresh install:${NC}"
echo "  brew tap sisobus/tap"
echo "  brew install gh-switch"
echo ""
echo -e "${CYAN}Test the new version:${NC}"
echo "  ghs version  # Should show: gh-switch version $VERSION"
echo ""