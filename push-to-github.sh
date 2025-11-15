#!/bin/bash
# Git Push Script for FTGO Azure Microservice Repository
# Bash version - Use with Git Bash or WSL

set -e  # Exit on error

echo "========================================="
echo "Git Push to GitHub (Bash)"
echo "========================================="
echo ""

cd "/c/Users/olisa/OneDrive/Desktop/Azure AKS architecture" || cd "$HOME/OneDrive/Desktop/Azure AKS architecture"

echo "Step 1: Initializing git..."
git init
echo ""

echo "Step 2: Adding files..."
git add .
echo ""

echo "Step 3: Committing..."
git commit -m "first commit" || echo "  (No changes to commit or already committed)"
echo ""

echo "Step 4: Setting branch to main..."
git branch -M main
echo ""

echo "Step 5: Configuring remote..."
git remote remove origin 2>/dev/null || true
# Replace YOUR_TOKEN with your GitHub Personal Access Token
git remote add origin https://Olisaemeka111:YOUR_TOKEN@github.com/Olisaemeka111/FTGO-Azure-Microservice-.git
echo ""

echo "Step 6: Pushing to GitHub..."
echo "Repository: https://github.com/Olisaemeka111/FTGO-Azure-Microservice-.git"
echo ""

if git push -u origin main; then
    echo ""
    echo "========================================="
    echo "✓ Successfully pushed to GitHub!"
    echo "========================================="
    echo ""
    echo "Repository URL: https://github.com/Olisaemeka111/FTGO-Azure-Microservice-"
    echo ""
else
    echo ""
    echo "========================================="
    echo "✗ Push failed. Check the error above."
    echo "========================================="
    echo ""
    exit 1
fi

