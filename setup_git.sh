#!/bin/bash
set -e

echo "1. Kurekebisha .gitignore..."
sed -i 's|backend/\.venv/|backend/venv/|' .gitignore

echo "2. Kuondoa git ya ndani ndani ya umis_admin (kama ipo)..."
rm -rf umis_admin/.git

echo "3. Kuanzisha git..."
git init

echo "4. Kuongeza faili zote..."
git add .

echo "5. Kufanya commit ya kwanza..."
git commit -m "Initial commit"

echo ""
echo "IMEKAMILIKA. Sasa fungua GitHub, unda repository mpya (BILA README),"
echo "kisha kimbiza amri hizi ukibadilisha USERNAME na JINA-LA-REPO:"
echo ""
echo "  git remote add origin https://github.com/USERNAME/JINA-LA-REPO.git"
echo "  git branch -M main"
echo "  git push -u origin main"
