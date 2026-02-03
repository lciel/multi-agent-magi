#!/bin/bash
# ============================================================
# first_setup.sh - MAGI System 初回セットアップスクリプト
# Ubuntu / WSL / Mac 用環境構築ツール
# ============================================================
# 実行方法:
#   chmod +x first_setup.sh
#   ./first_setup.sh
# ============================================================

set -e

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# アイコン付きログ関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${CYAN}${BOLD}━━━ $1 ━━━${NC}\n"
}

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 結果追跡用変数
RESULTS=()
HAS_ERROR=false

echo ""
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║  🔷 MAGI SYSTEM インストーラー                                ║"
echo "  ║     Initial Setup Script for Multi-AI Decision System        ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "  このスクリプトは初回セットアップ用です。"
echo "  依存関係の確認とディレクトリ構造の作成を行います。"
echo ""
echo "  インストール先: $SCRIPT_DIR"
echo ""

# ============================================================
# STEP 1: OS チェック
# ============================================================
log_step "STEP 1: システム環境チェック"

# OS情報を取得
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$NAME
    OS_VERSION=$VERSION_ID
    log_info "OS: $OS_NAME $OS_VERSION"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS_NAME="macOS"
    OS_VERSION=$(sw_vers -productVersion)
    log_info "OS: $OS_NAME $OS_VERSION"
else
    OS_NAME="Unknown"
    log_warn "OS情報を取得できませんでした"
fi

RESULTS+=("システム環境: OK")

# ============================================================
# STEP 2: tmux チェック・インストール
# ============================================================
log_step "STEP 2: tmux チェック"

if command -v tmux &> /dev/null; then
    TMUX_VERSION=$(tmux -V | awk '{print $2}')
    log_success "tmux がインストール済みです (v$TMUX_VERSION)"
    RESULTS+=("tmux: OK (v$TMUX_VERSION)")
else
    log_error "tmux がインストールされていません"
    echo ""
    echo "  インストール方法:"
    echo "    Ubuntu/Debian: sudo apt-get install tmux"
    echo "    Fedora:        sudo dnf install tmux"
    echo "    macOS:         brew install tmux"
    echo ""
    RESULTS+=("tmux: 未インストール (手動インストール必要)")
    HAS_ERROR=true
fi

# ============================================================
# STEP 3: Claude Code CLI チェック
# ============================================================
log_step "STEP 3: Claude Code CLI チェック"

if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "unknown")
    log_success "Claude Code CLI がインストール済みです"
    log_info "バージョン: $CLAUDE_VERSION"
    RESULTS+=("Claude Code CLI: OK")
else
    log_error "Claude Code CLI がインストールされていません"
    echo ""
    echo "  インストールコマンド:"
    echo "     npm install -g @anthropic-ai/claude-code"
    echo ""
    RESULTS+=("Claude Code CLI: 未インストール")
    HAS_ERROR=true
fi

# ============================================================
# STEP 4: ディレクトリ構造作成
# ============================================================
log_step "STEP 4: ディレクトリ構造作成"

# 必要なディレクトリ一覧
DIRECTORIES=(
    "queue/opinions"
    "config"
    "instructions"
    "logs"
    "memory"
)

CREATED_COUNT=0
EXISTED_COUNT=0

for dir in "${DIRECTORIES[@]}"; do
    if [ ! -d "$SCRIPT_DIR/$dir" ]; then
        mkdir -p "$SCRIPT_DIR/$dir"
        log_info "作成: $dir/"
        CREATED_COUNT=$((CREATED_COUNT + 1))
    else
        EXISTED_COUNT=$((EXISTED_COUNT + 1))
    fi
done

if [ $CREATED_COUNT -gt 0 ]; then
    log_success "$CREATED_COUNT 個のディレクトリを作成しました"
fi
if [ $EXISTED_COUNT -gt 0 ]; then
    log_info "$EXISTED_COUNT 個のディレクトリは既に存在します"
fi

RESULTS+=("ディレクトリ構造: OK (作成:$CREATED_COUNT, 既存:$EXISTED_COUNT)")

# ============================================================
# STEP 5: 設定ファイル初期化
# ============================================================
log_step "STEP 5: 設定ファイル確認"

# config/settings.yaml
if [ ! -f "$SCRIPT_DIR/config/settings.yaml" ]; then
    log_info "config/settings.yaml を作成中..."
    cat > "$SCRIPT_DIR/config/settings.yaml" << 'EOF'
# MAGI System 設定ファイル

# 言語設定
# ja: 日本語（戦国風日本語のみ、併記なし）
# en: 英語（戦国風日本語 + 英訳併記）
# その他の言語コード（es, zh, ko, fr, de 等）も対応
language: ja

# シェル設定
# bash: bash用プロンプト（デフォルト）
# zsh: zsh用プロンプト
shell: bash

# ログ設定
logging:
  level: info  # debug | info | warn | error
  path: "./logs/"
EOF
    log_success "settings.yaml を作成しました"
else
    log_info "config/settings.yaml は既に存在します"
fi

# config/magi_personas.yaml
if [ ! -f "$SCRIPT_DIR/config/magi_personas.yaml" ]; then
    log_info "config/magi_personas.yaml を作成中..."
    cat > "$SCRIPT_DIR/config/magi_personas.yaml" << 'EOF'
# MAGI ペルソナプリセット

technical:
  - name: "シニアフロントエンドエンジニア"
    perspective: "フロントエンド技術的専門性"
    areas: ["React", "Vue", "TypeScript", "パフォーマンス"]
  - name: "シニアバックエンドエンジニア"
    perspective: "バックエンド技術的専門性"
    areas: ["API設計", "データベース", "スケーラビリティ"]
  - name: "QAエンジニア"
    perspective: "品質保証・テスト"
    areas: ["テスト戦略", "バグ検出", "品質基準"]
  - name: "セキュリティエンジニア"
    perspective: "セキュリティ・脆弱性"
    areas: ["脅威分析", "認証", "データ保護"]
  - name: "SRE / DevOpsエンジニア"
    perspective: "運用・信頼性"
    areas: ["CI/CD", "監視", "インフラ", "可用性"]

management:
  - name: "プロダクトマネージャー"
    perspective: "プロダクト戦略・ロードマップ"
    areas: ["ビジョン", "優先順位", "リリース計画"]
  - name: "プロジェクトマネージャー"
    perspective: "スケジュール・リソース管理"
    areas: ["タイムライン", "リスク", "コスト"]
  - name: "CTO"
    perspective: "技術戦略・長期的影響"
    areas: ["技術スタック", "技術的負債", "採用"]

user_perspective:
  - name: "エンドユーザー代表"
    perspective: "ユーザー体験"
    areas: ["使いやすさ", "価値提供", "満足度"]
  - name: "初心者ユーザー"
    perspective: "新規ユーザー視点"
    areas: ["学習曲線", "直感性", "ドキュメント"]
  - name: "パワーユーザー"
    perspective: "ヘビーユーザー視点"
    areas: ["効率性", "カスタマイズ性", "高度な機能"]

critical:
  - name: "批判者"
    perspective: "懐疑的・批判的視点"
    areas: ["リスク", "弱点", "失敗シナリオ"]
  - name: "リスク分析専門家"
    perspective: "リスク評価"
    areas: ["脅威", "影響分析", "緩和策"]
  - name: "コスト最適化専門家"
    perspective: "コスト効率"
    areas: ["ROI", "予算", "リソース最適化"]

business:
  - name: "ビジネスアナリスト"
    perspective: "ビジネス価値"
    areas: ["売上", "成長", "競合優位性"]
  - name: "採用担当"
    perspective: "開発者体験・採用"
    areas: ["技術スタックの魅力", "学習環境"]

creative:
  - name: "UIデザイナー"
    perspective: "視覚デザイン"
    areas: ["美しさ", "一貫性", "ブランド"]
  - name: "UXリサーチャー"
    perspective: "ユーザーリサーチ"
    areas: ["ユーザー調査", "ペルソナ", "ジャーニー"]
EOF
    log_success "magi_personas.yaml を作成しました"
else
    log_info "config/magi_personas.yaml は既に存在します"
fi

# config/system_state.yaml（テンプレート）
if [ ! -f "$SCRIPT_DIR/config/system_state.yaml" ]; then
    log_info "config/system_state.yaml テンプレートを作成中..."
    cat > "$SCRIPT_DIR/config/system_state.yaml" << 'EOF'
# MAGI システム状態（起動時に自動生成）
# この情報をマギが参照して、利用可能な賢者数を把握します
system:
  sage_count: 3  # デフォルト値（launch_magi.sh で上書きされます）
  session_name: nerv
  timestamp: null
EOF
    log_success "system_state.yaml テンプレートを作成しました"
else
    log_info "config/system_state.yaml は既に存在します"
fi

RESULTS+=("設定ファイル: OK")

# ============================================================
# STEP 6: キューファイル初期化
# ============================================================
log_step "STEP 6: キューファイル初期化"

# human_to_magi.yaml
if [ ! -f "$SCRIPT_DIR/queue/human_to_magi.yaml" ]; then
    cat > "$SCRIPT_DIR/queue/human_to_magi.yaml" << 'EOF'
question:
  id: null
  timestamp: null
  content: null
  context: {}
  magi_count: null
  status: idle
EOF
    log_info "human_to_magi.yaml を作成しました"
fi

# magi_to_sage.yaml
if [ ! -f "$SCRIPT_DIR/queue/magi_to_sage.yaml" ]; then
    cat > "$SCRIPT_DIR/queue/magi_to_sage.yaml" << 'EOF'
consultation:
  question_id: null
  timestamp: null
  question: null
  magi_count: 0
  roles: {}
  status: idle
EOF
    log_info "magi_to_sage.yaml を作成しました"
fi

# final_answer.yaml
if [ ! -f "$SCRIPT_DIR/queue/final_answer.yaml" ]; then
    cat > "$SCRIPT_DIR/queue/final_answer.yaml" << 'EOF'
answer:
  question_id: null
  timestamp: null
  summary: null
  magi_votes: {}
  detailed_synthesis: null
  action_items: []
  status: idle
EOF
    log_info "final_answer.yaml を作成しました"
fi

# Magi opinion files (1-8)
for i in {1..8}; do
    OPINION_FILE="$SCRIPT_DIR/queue/opinions/sage${i}_opinion.yaml"
    if [ ! -f "$OPINION_FILE" ]; then
        cat > "$OPINION_FILE" << EOF
sage_id: sage${i}
role_name: null
persona: null
question_id: null
timestamp: null
opinion:
  stance: null
  confidence: null
  reasoning: null
  pros_cons: {}
  recommendation: null
status: idle
EOF
    fi
done
log_info "Sage opinion files (1-8) を確認/作成しました"

RESULTS+=("キューファイル: OK")

# ============================================================
# STEP 7: スクリプト実行権限付与
# ============================================================
log_step "STEP 7: 実行権限設定"

SCRIPTS=(
    "first_setup.sh"
    "launch_magi.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$SCRIPT_DIR/$script" ]; then
        chmod +x "$SCRIPT_DIR/$script"
        log_info "$script に実行権限を付与しました"
    fi
done

RESULTS+=("実行権限: OK")

# ============================================================
# 結果サマリー
# ============================================================
echo ""
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║  📋 セットアップ結果サマリー                                  ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo ""

for result in "${RESULTS[@]}"; do
    if [[ $result == *"未インストール"* ]] || [[ $result == *"失敗"* ]]; then
        echo -e "  ${RED}✗${NC} $result"
    elif [[ $result == *"アップグレード"* ]] || [[ $result == *"スキップ"* ]]; then
        echo -e "  ${YELLOW}!${NC} $result"
    else
        echo -e "  ${GREEN}✓${NC} $result"
    fi
done

echo ""

if [ "$HAS_ERROR" = true ]; then
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║  ⚠️  一部の依存関係が不足しています                           ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  上記の警告を確認し、不足しているものをインストールしてください。"
    echo "  すべての依存関係が揃ったら、再度このスクリプトを実行して確認できます。"
else
    echo "  ╔══════════════════════════════════════════════════════════════╗"
    echo "  ║  ✅ セットアップ完了！準備万端！                              ║"
    echo "  ╚══════════════════════════════════════════════════════════════╝"
fi

echo ""
echo "  ┌──────────────────────────────────────────────────────────────┐"
echo "  │  ➡️ 次のステップ                                             │"
echo "  └──────────────────────────────────────────────────────────────┘"
echo ""
echo "  MAGI システム起動:"
echo "     ./launch_magi.sh"
echo ""
echo "  詳細は README.md を参照してください。"
echo ""
echo "  ════════════════════════════════════════════════════════════════"
echo "   🔷 MAGI SYSTEM - AI Decision Support"
echo "  ════════════════════════════════════════════════════════════════"
echo ""

# 依存関係不足の場合は exit 1 を返す
if [ "$HAS_ERROR" = true ]; then
    exit 1
fi
