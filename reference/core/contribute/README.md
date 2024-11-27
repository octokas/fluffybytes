# FluffyBytes: Getting Started Guide 🚀
---
## Overview
Welcome to FluffyBytes! 🎉 We're excited to have you join us on this journey to build and manage enterprise-grade cloud infrastructure. This guide will help you get up and running quickly with our platform.

FluffyBytes provides a robust, secure, and scalable infrastructure solution that puts you in control. Whether you're setting up a minimal local development environment or deploying a full production system with CloudHSM, we've got you covered.

_What you'll find in this guide:_
- Step-by-step setup instructions for your development environment
- Core concepts and architectural overview
- Security best practices and compliance guidance
- Operational guidelines for day-to-day management

Let's get started building something amazing together! 💪

---

## Table of Contents
- [Installation Instructions](/reference/book/getting-started-guide.md#installation-instructions)
  - [macOS](/reference/book/getting-started-guide.md#macos-installation)
  - [Ubuntu](/reference/book/getting-started-guide.md#ubuntu-installation)
  - [FreeBSD](/reference/book/getting-started-guide.md#freebsd-installation)
- [Project Setup](/reference/book/getting-started-guide.md#project-setup)
  - [clone repo](/reference/book/getting-started-guide.md#clone-repo)
  - [initialize dev environment](/reference/book/getting-started-guide.md#initialize-dev-environment)
  - [verify installation](/reference/book/getting-started-guide.md#verify-installation)
- [Development Modes](/reference/book/getting-started-guide.md#development-modes)
  - [local-only (minimal)](/reference/book/getting-started-guide.md#local-only-mode-minimal)
  - [standard w/ aws](/reference/book/getting-started-guide.md#standard-mode-aws)
  - [full w/ cloudhsm](/reference/book/getting-started-guide.md#full-mode-with-cloudhsm)
- [Directory Structure](/reference/book/getting-started-guide.md#directory-structure)
- [Quick Start Commands](/reference/book/getting-started-guide.md#quick-start-commands)
  - [local dev](/reference/book/getting-started-guide.md#local-development)
  - [run tests](/reference/book/getting-started-guide.md#run-tests)
  - [deploy infra](/reference/book/getting-started-guide.md#deploy-infrastructure)
  - [clean up](/reference/book/getting-started-guide.md#clean-up)
  - [show costs](/reference/book/getting-started-guide.md#show-costs)
- [Common Issues and Solutions](/reference/book/getting-started-guide.md#common-issues-and-solutions)
  - [permission issues](/reference/book/getting-started-guide.md#permission-issues)
  - [dev env issues](/reference/book/getting-started-guide.md#development-environment)
- [Contributing](/reference/book/getting-started-guide.md#contributing)
  - [code standards](/reference/book/getting-started-guide.md#code-standards)
  - [commit messages](/reference/book/getting-started-guide.md#commit-messages)
  - [pull requests](/reference/book/getting-started-guide.md#pull-requests)
  - [issues](/reference/book/getting-started-guide.md#issues)
  - [roadmap](/reference/book/getting-started-guide.md#roadmap)
  - [license](/reference/book/getting-started-guide.md#license)
  - [contributors](/reference/book/getting-started-guide.md#contributors)
---

## Installation Instructions

### macOS Installation
```zsh
## 🌈 install lolcat if not already installed
brew install lolcat

## 🍺 install Homebrew if not already installed
BREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
echo '/bin/bash -c "$(curl -fsSL $BREW_INSTALL_URL)"' | lolcat

## 🌈 install core dependencies
brew install --verbose \
  go \
  terraform \
  yarn \
  jq \
  aws-cli \
  saml2aws \
  multisaml2aws \
  npm-check

## 🌈 install Oh My Zsh (if you haven't already)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### Ubuntu Installation
```bash
## 🌈 update package list
sudo apt update

## 🌈 install core dependencies
sudo apt install -y \
  golang-go \
  jq \
  zsh \
  ruby     # for lolcat

## 🌈 install Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt update && sudo apt install terraform

## 🌈 install Node.js and Yarn
curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt install -y nodejs
npm install -g yarn npm-check

## 🌈 install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### FreeBSD Installation
```bash
## 🌈 install core dependencies
pkg install \
  go \
  yarn \
  node \
  jq \
  ruby \
  aws-cli \
  terraform

## 🌈 install lolcat
gem install lolcat

## 🌈 install npm-check
npm install -g npm-check
```

## Project Setup

##### [Clone the Repository](https://github.com/your-org/fluffy-bytes.git)
```zsh
## 🌈 clone the repository
git clone git@github.com:your-org/fluffy-bytes.git
cd fluffy-bytes
```

##### [Initialize Development Environment](https://github.com/your-org/fluffy-bytes/blob/main/scripts/init.sh)
```zsh
## 🌈 initialize development environment
make init
```

##### [Verify Installation](https://github.com/your-org/fluffy-bytes/blob/main/scripts/verify-deps.sh)
```zsh
## 🌈 verify installation
make verify-deps | lolcat  # cause infrastructure should be fun! 🌈
```

## Development Modes

#### [Local-Only Mode (Minimal)](https://github.com/your-org/fluffy-bytes/blob/main/scripts/dev-local.sh)
```zsh
## 🌈 start local development environment
make dev-local

## This provides:
## - Local storage emulation
## - Mock AWS services via LocalStack
# - Basic event processing
```

#### [Standard Mode (AWS)](https://github.com/your-org/fluffy-bytes/blob/main/scripts/dev-standard.sh)
```zsh
## 🌈 Configure AWS credentials
aws configure

# Initialize infrastructure
make dev-standard

# This sets up:
# - Basic AWS infrastructure
# - EKS cluster
# - Event processing
```

#### [Full Mode (with CloudHSM)](https://github.com/your-org/fluffy-bytes/blob/main/scripts/dev-full.sh)
```zsh
## 🌈 Requires additional AWS permissions and setup
make dev-full
```

<!-- # This includes everything in Standard plus:
# - CloudHSM cluster
# - Advanced security features
# - Full monitoring stack -->


## Directory Structure
```
fluffy-bytes/
├── .github/                   # github actions
├── reference/                 # reference materials
  ├── business/                # business logic
  ├── core/                    # core functionality
    ├── guides/                # documentation
      ├── api/                  # apis
      ├── arch/                  # architecture
      ├── deploy/                  # architecture
      ├── iaac/                  # infrastructure as code
      ├── local/                  # local development
      └── prs/                    # pull requests
    ├── launch/                  # environments
      ├── dev/                  # development
      ├── stg/                  # staging
      └── prod/                  # production
    └── src/                     # sourcecode
```

## Quick Start Commands

```zsh
# Start local development
make dev

# Run tests
make test | lolcat

# Deploy infrastructure
make deploy ENV=dev

# Clean up
make clean

# Show infrastructure costs
make show-costs | lolcat
```

## Common Issues and Solutions

### 1. Permission Issues
```zsh
# Fix AWS credentials
aws configure

# Verify access
aws sts get-caller-identity
```

### 2. Development Environment
```zsh
# Reset local environment
make clean
make init

# Update dependencies
make update-deps
```

<!-- //TODO:
1. Core Concepts with architecture diagrams
2. Detailed module documentation
3. Local development environment setup
4. Security implementation guide
5. Add more specific details for preferred tools like
   1. custom ZSH configurations
   2. Yarn scripts!
-->
