#!/bin/bash

# ==========================================
# 🚀 Universal Auto Deployer for GitHub Pages
# ==========================================

# 現在のディレクトリ名（プロジェクト名として使用）
CURRENT_DIR_NAME=$(basename "$PWD")

# デプロイ先のリモートURL (origin)
REMOTE_URL=$(git remote get-url origin 2>/dev/null)

if [ -z "$REMOTE_URL" ]; then
  echo "❌ エラー: Gitリモート(origin)が見つかりません。"
  echo "このディレクトリはGit管理下ですか？ 'git remote add origin <URL>' を実行してください。"
  exit 1
fi

echo "📂 プロジェクト: $CURRENT_DIR_NAME"
echo "🔗 リモート: $REMOTE_URL"

BUILD_DIR=""

# --- 1. Flutterプロジェクトの場合 ---
if [ -f "pubspec.yaml" ]; then
  # プロジェクト名をpubspecから取得（name: xxx の行）
  PROJECT_NAME=$(grep 'name:' pubspec.yaml | head -n1 | awk '{print $2}')
  if [ -z "$PROJECT_NAME" ]; then
    PROJECT_NAME=$CURRENT_DIR_NAME
  fi

  echo "🐦 Flutterプロジェクト ($PROJECT_NAME) を検出しました。"
  echo "🔨 Web向けビルドを開始します..."
  
  # ベースhrefを設定してビルド (GitHub Pages用)
  flutter build web --base-href "/$CURRENT_DIR_NAME/" --release

  if [ $? -ne 0 ]; then
    echo "❌ Flutterのビルドに失敗しました。"
    exit 1
  fi

  BUILD_DIR="build/web"

# --- 2. Node.js / Static Web プロジェクト (簡易判定) ---
elif [ -f "package.json" ]; then
  echo "📦 Node.jsプロジェクトを検出しました。"
  
  if grep -q "\"build\"" package.json; then
    echo "🔨 'npm run build' を実行します..."
    npm install && npm run build
  else
    echo "⚠️ ビルドスクリプトが見つかりません。"
  fi
  
  # 一般的な出力先を確認
  if [ -d "dist" ]; then
    BUILD_DIR="dist"
  elif [ -d "build" ]; then
    BUILD_DIR="build"
  elif [ -d "public" ]; then
    BUILD_DIR="public"
  else
    echo "❌ デプロイ対象のフォルダ(dist, build, public)が見つかりません。"
    exit 1
  fi

else
  echo "❌ サポートされていないプロジェクト形式です。"
  echo "現在のディレクトリに pubspec.yaml または package.json が見つかりません。"
  exit 1
fi

# --- デプロイ処理 ---
if [ ! -d "$BUILD_DIR" ]; then
  echo "❌ エラー: ビルドディレクトリ '$BUILD_DIR' が存在しません。"
  exit 1
fi

echo "🚀 '$BUILD_DIR' の内容を GitHub Pages にデプロイします..."

# サブシェルで実行
(
  cd "$BUILD_DIR" || exit
  
  # 既存のgit設定を初期化（デプロイ専用）
  rm -rf .git
  git init
  git add .
  git commit -m "Deploy to GitHub Pages $(date)"
  git branch -M gh-pages
  git remote add origin "$REMOTE_URL"
  
  echo "📤 GitHubへPush中..."
  git push -f origin gh-pages
)

if [ $? -eq 0 ]; then
  echo "🎉 デプロイ完了！"
  echo "🌍 https://<User>.github.io/$CURRENT_DIR_NAME/ に反映されます。"
else
  echo "❌ Pushに失敗しました。"
  exit 1
fi
