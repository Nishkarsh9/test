#!/bin/bash
set -e

echo "Installing Python dependencies globally on the system layer..."

# Guarantee base core packages are present and fresh
apt-get update && apt-get install -y python3-pip
pip3 install --upgrade pip setuptools wheel

# Install production server runtime engines along with framework requirements
if [ -f "requirements.txt" ]; then
    echo "Installing application requirements from requirements.txt..."
    pip3 install -r requirements.txt
fi

echo "Python global package steps complete."
