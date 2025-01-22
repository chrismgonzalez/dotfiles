#!/bin/bash

# Requirements
#   You will need to have created a GitHub Access Token with admin:public_key permissions
#   Use when needing to create a new ssh key

# Usage
#   chmod +x autokey-github.sh
#   ./autokey-github.sh <YOUR-GITHUB-USER-EMAIL> <YOUR-GITHUB-ACCESS-TOKEN>

# Reference
#   https://nathanielhoag.com/blog/2014/05/26/automate-ssh-key-generation-and-deployment/
#   https://gist.github.com/nhoag/7043570bfe32003eb8a1
#   https://help.github.com/articles/testing-your-ssh-connection/
#   https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/
#   https://developer.github.com/v3/users/keys/
#   https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent

set -e

# Generate SSH Key and Deploy to Github

EMAIL=$1
TOKEN=$2 # must have admin:public_key for DELETE


ssh-keygen -q -t ed25519 -C "$EMAIL" -N "" -f ~/.ssh/github_rsa

PUBKEY=`cat ~/.ssh/github_rsa.pub`
TITLE=`hostname`

RESPONSE=`curl -s -H "Authorization: token ${TOKEN}" \
  -X POST --data-binary "{\"title\":\"${TITLE}\",\"key\":\"${PUBKEY}\"}" \
  https://api.github.com/user/keys`

KEYID=`echo $RESPONSE \
  | grep -o '\"id.*' \
  | grep -o "[0-9]*" \
  | grep -m 1 "[0-9]*"`

echo "Public key deployed to remote service"

# Add SSH Key to the local ssh-agent"

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/github_rsa

echo "Added SSH key to the ssh-agent"

# Test the SSH connection

ssh -T git@github.com