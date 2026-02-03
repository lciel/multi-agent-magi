#!/bin/bash
# 🔷 MAGI SYSTEM 起動スクリプト
# Launch Script for Multi-AI Decision System
#
# 使用方法:
#   ./launch_magi.sh           # 3賢者で起動して自動アタッチ（デフォルト）
#   ./launch_magi.sh -n 5      # 5賢者で起動して自動アタッチ
#   ./launch_magi.sh -d        # 起動のみ（アタッチしない）
#   ./launch_magi.sh -h        # ヘルプ表示

set -e

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 言語設定を読み取り（デフォルト: ja）
LANG_SETTING="ja"
if [ -f "./config/settings.yaml" ]; then
    LANG_SETTING=$(grep "^language:" ./config/settings.yaml 2>/dev/null | awk '{print $2}' || echo "ja")
fi

# シェル設定を読み取り（自動検出または設定ファイル）
if [ -f "./config/settings.yaml" ]; then
    SHELL_SETTING=$(grep "^shell:" ./config/settings.yaml 2>/dev/null | awk '{print $2}')
fi

# 設定がない場合または auto の場合は自動検出
if [ -z "$SHELL_SETTING" ] || [ "$SHELL_SETTING" = "null" ] || [ "$SHELL_SETTING" = "auto" ]; then
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_SETTING="zsh"
    else
        SHELL_SETTING="bash"
    fi
fi

# 色付きログ関数（MAGI System スタイル）
log_info() {
    echo -e "\033[1;36m[SYSTEM]\033[0m $1"
}

log_success() {
    echo -e "\033[1;32m[OK]\033[0m $1"
}

log_init() {
    echo -e "\033[1;35m[INIT]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

# ═══════════════════════════════════════════════════════════════════════════════
# プロンプト生成関数（bash/zsh対応）
# ═══════════════════════════════════════════════════════════════════════════════
generate_prompt() {
    local label="$1"
    local color="$2"
    local shell_type="$3"

    if [ "$shell_type" == "zsh" ]; then
        # zsh用: %F{color}%B...%b%f 形式
        echo "(%F{${color}}%B${label}%b%f) %F{green}%B%~%b%f%# "
    else
        # bash用: \[\033[...m\] 形式
        local color_code
        case "$color" in
            red)     color_code="1;31" ;;
            green)   color_code="1;32" ;;
            yellow)  color_code="1;33" ;;
            blue)    color_code="1;34" ;;
            magenta) color_code="1;35" ;;
            cyan)    color_code="1;36" ;;
            *)       color_code="1;37" ;;  # white (default)
        esac
        echo "(\[\033[${color_code}m\]${label}\[\033[0m\]) \[\033[1;32m\]\w\[\033[0m\]\$ "
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# オプション解析
# ═══════════════════════════════════════════════════════════════════════════════
SETUP_ONLY=false  # デフォルトは全部起動
DETACHED=false    # デフォルトは自動アタッチ
SHELL_OVERRIDE=""
SAGE_COUNT=3      # デフォルト3賢者

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--setup-only)
            SETUP_ONLY=true
            shift
            ;;
        -d|--detached)
            DETACHED=true
            shift
            ;;
        -n|--sages)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                SAGE_COUNT=$2
                if [ "$SAGE_COUNT" -lt 3 ] || [ "$SAGE_COUNT" -gt 8 ]; then
                    echo "エラー: 賢者数は3-8の範囲で指定してください（指定値: $SAGE_COUNT）"
                    exit 1
                fi
                shift 2
            else
                echo "エラー: -n オプションには数値を指定してください"
                exit 1
            fi
            ;;
        -shell|--shell)
            if [[ -n "$2" && "$2" != -* ]]; then
                SHELL_OVERRIDE="$2"
                shift 2
            else
                echo "エラー: -shell オプションには bash または zsh を指定してください"
                exit 1
            fi
            ;;
        -h|--help)
            echo ""
            echo "🔷 MAGI SYSTEM 起動スクリプト"
            echo ""
            echo "使用方法: ./launch_magi.sh [オプション]"
            echo ""
            echo "オプション:"
            echo "  -n, --sages N       賢者の数を指定（3-8）デフォルト: 3"
            echo "  -d, --detached      起動後にアタッチしない"
            echo "  -s, --setup-only    tmux セッションのみ作成（Claude 起動なし）"
            echo "  -shell, --shell SH  シェルを指定（bash または zsh）"
            echo "  -h, --help          このヘルプを表示"
            echo ""
            echo "例:"
            echo "  ./launch_magi.sh              # 3賢者で起動して自動アタッチ（デフォルト）"
            echo "  ./launch_magi.sh -n 5         # 5賢者で起動して自動アタッチ"
            echo "  ./launch_magi.sh -d           # 起動のみ（アタッチしない）"
            echo "  ./launch_magi.sh -s           # セットアップのみ（Claude なし）"
            echo ""
            echo "tmux 操作:"
            echo "  Ctrl+b d            デタッチ"
            echo "  Ctrl+b 矢印         ペイン移動"
            echo ""
            exit 0
            ;;
        *)
            echo "不明なオプション: $1"
            echo "./launch_magi.sh -h でヘルプを表示"
            exit 1
            ;;
    esac
done

# シェル設定のオーバーライド（コマンドラインオプション優先）
if [ -n "$SHELL_OVERRIDE" ]; then
    if [[ "$SHELL_OVERRIDE" == "bash" || "$SHELL_OVERRIDE" == "zsh" ]]; then
        SHELL_SETTING="$SHELL_OVERRIDE"
    else
        echo "エラー: -shell オプションには bash または zsh を指定してください（指定値: $SHELL_OVERRIDE）"
        exit 1
    fi
fi

# ═══════════════════════════════════════════════════════════════════════════════
# バナー表示
# ═══════════════════════════════════════════════════════════════════════════════
show_banner() {
    clear

    echo ""
    echo -e "\033[1;35m╔══════════════════════════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;35m║\033[0m \033[1;36m███╗   ███╗ █████╗  ██████╗ ██╗    ███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗\033[0m \033[1;35m║\033[0m"
    echo -e "\033[1;35m║\033[0m \033[1;36m████╗ ████║██╔══██╗██╔════╝ ██║    ██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║\033[0m \033[1;35m║\033[0m"
    echo -e "\033[1;35m║\033[0m \033[1;36m██╔████╔██║███████║██║  ███╗██║    ███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║\033[0m \033[1;35m║\033[0m"
    echo -e "\033[1;35m║\033[0m \033[1;36m██║╚██╔╝██║██╔══██║██║   ██║██║    ╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║\033[0m \033[1;35m║\033[0m"
    echo -e "\033[1;35m║\033[0m \033[1;36m██║ ╚═╝ ██║██║  ██║╚██████╔╝██║    ███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║\033[0m \033[1;35m║\033[0m"
    echo -e "\033[1;35m║\033[0m \033[1;36m╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝    ╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝\033[0m \033[1;35m║\033[0m"
    echo -e "\033[1;35m╠══════════════════════════════════════════════════════════════════════════════════╣\033[0m"
    echo -e "\033[1;35m║\033[0m       \033[1;37mMulti-AI Decision Support System\033[0m    \033[1;36m🔷\033[0m    \033[1;35mInspired by EVANGELION\033[0m              \033[1;35m║\033[0m"
    echo -e "\033[1;35m╚══════════════════════════════════════════════════════════════════════════════════╝\033[0m"
    echo ""

    echo -e "\033[1;34m  ╔═════════════════════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;34m  ║\033[0m                    \033[1;37m【 MAGI - 3つの叡智による意思決定 】\033[0m                        \033[1;34m║\033[0m"
    echo -e "\033[1;34m  ╚═════════════════════════════════════════════════════════════════════════════╝\033[0m"
    echo ""

    cat << MAGI_EOF
                 ┌─────────────────────────────────────────┐
                 │  マギ (MAGI)                        │
                 │  - 質問分析                             │
                 │  - 役割設計                             │
                 │  - 回答統合                             │
                 └────────────┬────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
               ┌─────────┐         ┌─────────┐
               │ 賢者 1  │   ...   │ 賢者 ${SAGE_COUNT}  │
               │ (Sage)  │         │ (Sage)  │
               └─────────┘         └─────────┘
                     ${SAGE_COUNT} ユニット（可変）

MAGI_EOF

    echo ""
    echo -e "\033[1;33m  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓\033[0m"
    echo -e "\033[1;33m  ┃\033[0m  \033[1;37m🔷 MAGI SYSTEM\033[0m  〜 \033[1;36m複数AI による集合知意思決定システム\033[0m 〜              \033[1;33m┃\033[0m"
    echo -e "\033[1;33m  ┃\033[0m                                                                           \033[1;33m┃\033[0m"
    echo -e "\033[1;33m  ┃\033[0m    \033[1;35mマギ\033[0m: 質問分析・役割設計    \033[1;31m賢者\033[0m: 専門家として意見形成 (3-8人)  \033[1;33m┃\033[0m"
    echo -e "\033[1;33m  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\033[0m"
    echo ""
}

# バナー表示実行
show_banner

echo -e "  \033[1;36mMAGI System 起動中...\033[0m (Initializing MAGI System)"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 1: 既存セッションクリーンアップ
# ═══════════════════════════════════════════════════════════════════════════════
log_info "🔷 既存セッションを終了中..."
tmux kill-session -t nerv 2>/dev/null && log_info "  └─ NERV セッション終了" || log_info "  └─ NERV セッションは存在せず"

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 2: システム状態ファイル作成
# ═══════════════════════════════════════════════════════════════════════════════
log_info "💾 システム状態を記録中..."

# system_state.yaml 作成（起動時の賢者数を記録）
cat > ./config/system_state.yaml << EOF
# MAGI システム状態（起動時に自動生成）
# この情報をマギが参照して、利用可能な賢者数を把握します
system:
  sage_count: ${SAGE_COUNT}
  session_name: nerv
  timestamp: "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
EOF

log_success "  └─ 利用可能な賢者数: ${SAGE_COUNT}人"

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 3: キューファイルリセット
# ═══════════════════════════════════════════════════════════════════════════════
log_info "💾 システムデータを初期化中..."

# human_to_magi.yaml リセット
cat > ./queue/human_to_magi.yaml << 'EOF'
question:
  id: null
  timestamp: null
  content: null
  context: {}
  magi_count: null
  status: idle
EOF

# magi_to_sage.yaml リセット
cat > ./queue/magi_to_sage.yaml << 'EOF'
consultation:
  question_id: null
  timestamp: null
  question: null
  magi_count: 0
  roles: {}
  status: idle
EOF

# final_answer.yaml リセット
cat > ./queue/final_answer.yaml << 'EOF'
answer:
  question_id: null
  timestamp: null
  summary: null
  magi_votes: {}
  detailed_synthesis: null
  action_items: []
  status: idle
EOF

# Sage opinion files リセット
for i in {1..8}; do
    cat > ./queue/opinions/sage${i}_opinion.yaml << EOF
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
done

log_success "✅ システムデータ初期化完了"

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 4: nervセッション作成（9ペイン：Main + Magi 1-8）
# ═══════════════════════════════════════════════════════════════════════════════
# tmux の存在確認
if ! command -v tmux &> /dev/null; then
    echo ""
    echo "  ╔════════════════════════════════════════════════════════╗"
    echo "  ║  [ERROR] tmux not found!                              ║"
    echo "  ║  tmux が見つかりません                                 ║"
    echo "  ╠════════════════════════════════════════════════════════╣"
    echo "  ║  Run first_setup.sh first:                            ║"
    echo "  ║  まず first_setup.sh を実行してください:               ║"
    echo "  ║     ./first_setup.sh                                  ║"
    echo "  ╚════════════════════════════════════════════════════════╝"
    echo ""
    exit 1
fi

log_init "🔷 NERV システムを初期化中（マギ + ${SAGE_COUNT}賢者）..."

# tmux セッション作成（サイズは自動検出）
if ! tmux new-session -d -s nerv -n "magi" 2>/dev/null; then
    echo ""
    echo "  ╔════════════════════════════════════════════════════════════╗"
    echo "  ║  [ERROR] Failed to create tmux session 'nerv'            ║"
    echo "  ║  tmux セッション 'nerv' の作成に失敗しました             ║"
    echo "  ╠════════════════════════════════════════════════════════════╣"
    echo "  ║  An existing session may be running.                     ║"
    echo "  ║  既存セッションが残っている可能性があります              ║"
    echo "  ║                                                          ║"
    echo "  ║  Check: tmux ls                                          ║"
    echo "  ║  Kill:  tmux kill-session -t nerv                        ║"
    echo "  ╚════════════════════════════════════════════════════════════╝"
    echo ""
    exit 1
fi

# ペイン作成: マギ（左フルハイト）+ 賢者（右側）
# 1-4人: 2列レイアウト (MAGI 35% | sages 65%)
# 5-8人: 3列レイアウト (MAGI 30% | sages1-4 35% | sages5-8 35%)

# Pane mapping array: sage番号 → pane番号
# インデックス配列を使用（bash 3.x 互換）
declare -a SAGE_PANE_MAP

if [ $SAGE_COUNT -le 4 ]; then
    # 1-4 sages: 2列レイアウト (MAGI 左 35% | sages 右 65%)

    # Step 1: 左右に分割（マギ35% | 賢者エリア65%）
    tmux split-window -h -t "nerv:0" -p 65

    # Step 2: 右側に賢者を配置（2人目以降）
    for ((i=2; i<=SAGE_COUNT; i++)); do
        tmux split-window -v -b -t "nerv:0.1"
    done

    # マギのペイン幅を35%に固定
    tmux resize-pane -t "nerv:0.0" -x 35%

    # Pane mapping: pane N = sage N (N >= 1)
    for ((i=1; i<=SAGE_COUNT; i++)); do
        SAGE_PANE_MAP[$i]=$i
    done
else
    # 5-8 sages: 3列レイアウト (MAGI 左 30% | sage1-4 中 35% | sage5-8 右 35%)
    # 注意: 7-8賢者はターミナルサイズにより起動失敗する可能性あり

    # Step 1: MAGI列 (pane 0) と右エリア (pane 1) を作成
    tmux split-window -h -t "nerv:0" -p 70 || {
        echo ""
        log_error "❌ ペイン作成エラー"
        echo "  ターミナルウィンドウサイズが不足しています。"
        echo "  より大きなウィンドウで起動するか、賢者数を減らしてください。"
        echo ""
        exit 1
    }

    # Step 2: 右エリア (pane 1) を中列 (pane 1) と右列 (pane 2) に分割
    tmux split-window -h -t "nerv:0.1" -p 50 || {
        echo ""
        log_error "❌ ペイン作成エラー"
        echo "  ターミナルウィンドウサイズが不足しています。"
        echo ""
        exit 1
    }

    # Step 3: 中列 (pane 1) を2つに分割 → sage1, sage2
    tmux split-window -v -t "nerv:0.1" || {
        echo ""
        log_error "❌ ペイン作成エラー"
        echo "  ターミナルウィンドウの高さが不足しています。"
        echo ""
        exit 1
    }
    # Now: pane 1 (sage1, top), pane 3 (sage2, bottom)

    # Step 4: 右列を必要に応じて分割
    if [ $SAGE_COUNT -ge 6 ]; then
        tmux split-window -v -t "nerv:0.2" || {
            echo ""
            log_error "❌ ペイン作成エラー（sage6）"
            echo "  ターミナルウィンドウの高さが不足しています。"
            echo "  賢者数を5以下にするか、ウィンドウを縦に拡大してください。"
            echo ""
            exit 1
        }
        # Now: pane 2 (sage5, top), pane 4 (sage6, bottom)
    fi

    # Step 5: 中列をさらに2回分割 → sage3, sage4
    tmux split-window -v -t "nerv:0.3" || {
        echo ""
        log_error "❌ ペイン作成エラー"
        echo "  ターミナルウィンドウの高さが不足しています。"
        echo ""
        exit 1
    }
    # Now: pane 1 (sage1), pane 3 (sage2), pane 5 (sage3, bottom)
    tmux split-window -v -t "nerv:0.5" || {
        echo ""
        log_error "❌ ペイン作成エラー"
        echo "  ターミナルウィンドウの高さが不足しています。"
        echo ""
        exit 1
    }
    # Now: pane 1 (sage1), pane 3 (sage2), pane 5 (sage3), pane 6 (sage4, bottom)

    # Step 6: 右列をさらに分割 (sage7-8)
    if [ $SAGE_COUNT -ge 7 ]; then
        tmux split-window -v -t "nerv:0.4" || {
            echo ""
            log_error "❌ ペイン作成エラー（sage7）"
            echo "  ターミナルウィンドウの高さが不足しています。"
            echo "  賢者数を6以下にするか、ウィンドウを縦に拡大してください。"
            echo ""
            exit 1
        }
        # pane 2 (sage5), pane 4 (sage6), pane 7 (sage7, bottom)
    fi
    if [ $SAGE_COUNT -ge 8 ]; then
        tmux split-window -v -t "nerv:0.7" || {
            echo ""
            log_error "❌ ペイン作成エラー（sage8）"
            echo "  ターミナルウィンドウの高さが不足しています。"
            echo "  賢者数を7以下にするか、ウィンドウを縦に拡大してください。"
            echo ""
            exit 1
        }
        # pane 2 (sage5), pane 4 (sage6), pane 7 (sage7), pane 8 (sage8, bottom)
    fi

    # マギのペイン幅を30%に固定
    tmux resize-pane -t "nerv:0.0" -x 30%

    # Pane mapping after layout creation:
    # 5 sages: pane 0=MAGI, 1=sage1, 3=sage2, 5=sage3, 6=sage4, 2=sage5
    # 6 sages: pane 0=MAGI, 1=sage1, 3=sage2, 5=sage3, 6=sage4, 2=sage5, 4=sage6
    # 7 sages: pane 0=MAGI, 1=sage1, 3=sage2, 5=sage3, 6=sage4, 2=sage5, 4=sage6, 7=sage7
    # 8 sages: pane 0=MAGI, 1=sage1, 3=sage2, 5=sage3, 6=sage4, 2=sage5, 4=sage6, 7=sage7, 8=sage8

    SAGE_PANE_MAP[1]=1
    SAGE_PANE_MAP[2]=3
    SAGE_PANE_MAP[3]=5
    SAGE_PANE_MAP[4]=6
    SAGE_PANE_MAP[5]=2
    if [ $SAGE_COUNT -ge 6 ]; then SAGE_PANE_MAP[6]=4; fi
    if [ $SAGE_COUNT -ge 7 ]; then SAGE_PANE_MAP[7]=7; fi
    if [ $SAGE_COUNT -ge 8 ]; then SAGE_PANE_MAP[8]=8; fi
fi

# ペインタイトル設定を動的に生成
# Pane 0: magi
# Pane 1-N: sage1-N
PANE_TITLES=("magi")
PANE_COLORS=("magenta")

for ((i=1; i<=SAGE_COUNT; i++)); do
    PANE_TITLES+=("sage${i}")
    PANE_COLORS+=("cyan")
done

# 各ペインにタイトルとプロンプトを設定
# MAGI (pane 0)
tmux select-pane -t "nerv:0.0" -T "${PANE_TITLES[0]}"
PROMPT_STR=$(generate_prompt "${PANE_TITLES[0]}" "${PANE_COLORS[0]}" "$SHELL_SETTING")
tmux send-keys -t "nerv:0.0" "cd \"$(pwd)\" && export PS1='${PROMPT_STR}' && clear" Enter

# Sages (pane 1-N, using SAGE_PANE_MAP for 5+ sages)
for ((i=1; i<=SAGE_COUNT; i++)); do
    PANE_IDX=${SAGE_PANE_MAP[$i]}
    tmux select-pane -t "nerv:0.${PANE_IDX}" -T "${PANE_TITLES[$i]}"
    PROMPT_STR=$(generate_prompt "${PANE_TITLES[$i]}" "${PANE_COLORS[$i]}" "$SHELL_SETTING")
    tmux send-keys -t "nerv:0.${PANE_IDX}" "cd \"$(pwd)\" && export PS1='${PROMPT_STR}' && clear" Enter
done

log_success "  └─ NERV システム起動完了"

# tmux オプションを設定（TUI 表示の改善）
tmux set-option -t nerv default-terminal "tmux-256color" > /dev/null 2>&1
tmux set-window-option -t nerv aggressive-resize on > /dev/null 2>&1

echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 5: Claude Code 起動（--setup-only でスキップ）
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$SETUP_ONLY" = false ]; then
    # Claude Code CLI の存在チェック
    if ! command -v claude &> /dev/null; then
        log_info "⚠️  claude コマンドが見つかりません"
        echo "  first_setup.sh を再実行してください:"
        echo "    ./first_setup.sh"
        exit 1
    fi

    log_init "🧠 全ユニット AI コアを起動中..."

    # マギ (opus) - 環境変数でペイン情報を設定
    tmux send-keys -t "nerv:0.0" "export TMUX_PANE_ID=nerv:0.0 AGENT_ROLE=magi"
    tmux send-keys -t "nerv:0.0" Enter
    sleep 0.2
    tmux send-keys -t "nerv:0.0" "MAX_THINKING_TOKENS=0 claude --model opus --dangerously-skip-permissions"
    tmux send-keys -t "nerv:0.0" Enter
    log_info "  └─ マギ (MAGI) 起動開始"

    # 賢者（1-N） - 各賢者に環境変数でペイン情報を設定
    for ((i=1; i<=SAGE_COUNT; i++)); do
        PANE_IDX=${SAGE_PANE_MAP[$i]}
        tmux send-keys -t "nerv:0.${PANE_IDX}" "export TMUX_PANE_ID=nerv:0.${PANE_IDX} AGENT_ROLE=sage${i}"
        tmux send-keys -t "nerv:0.${PANE_IDX}" Enter
        sleep 0.2
        tmux send-keys -t "nerv:0.${PANE_IDX}" "claude --dangerously-skip-permissions"
        tmux send-keys -t "nerv:0.${PANE_IDX}" Enter
    done
    log_info "  └─ 賢者 (1-${SAGE_COUNT}) 起動開始"

    # Bypass Permissions 警告が表示されるまで待機
    log_info "  └─ Bypass Permissions 警告を待機中..."
    sleep 8

    # 全ペインで自動承諾（Down + Enter）
    log_info "  └─ Bypass Permissions を自動承諾中..."
    # MAGI (pane 0)
    tmux send-keys -t "nerv:0.0" Down
    sleep 0.1
    tmux send-keys -t "nerv:0.0" Enter
    # Sages (using SAGE_PANE_MAP)
    for ((i=1; i<=SAGE_COUNT; i++)); do
        PANE_IDX=${SAGE_PANE_MAP[$i]}
        tmux send-keys -t "nerv:0.${PANE_IDX}" Down
        sleep 0.1
        tmux send-keys -t "nerv:0.${PANE_IDX}" Enter
    done

    # Claude Code の起動完了を待機
    sleep 3

    log_success "✅ 全ユニット コア起動完了"
    echo ""

    # ═══════════════════════════════════════════════════════════════════════════
    # STEP 5.5: 各エージェントに指示書を読み込ませる
    # ═══════════════════════════════════════════════════════════════════════════
    log_init "💿 各ユニットにプログラムをロード中..."
    echo ""

    echo "  Claude Code の起動を待機中（最大30秒）..."

    # マギ の起動を確認（最大30秒待機）
    for i in {1..30}; do
        if tmux capture-pane -t "nerv:0.0" -p | grep -q "bypass permissions"; then
            echo "  └─ マギ の Claude Code 起動確認完了（${i}秒）"
            break
        fi
        sleep 1
    done

    # マギ に指示書を読み込ませる
    log_info "  └─ マギ にプログラムをロード中..."
    tmux send-keys -t "nerv:0.0" "instructions/magi.md を読んで役割を理解してください。"
    sleep 0.5
    tmux send-keys -t "nerv:0.0" Enter

    # 賢者に指示書を読み込ませる（1-N）
    sleep 2
    log_info "  └─ 賢者 にプログラムをロード中..."
    for ((i=1; i<=SAGE_COUNT; i++)); do
        PANE_IDX=${SAGE_PANE_MAP[$i]}
        tmux send-keys -t "nerv:0.${PANE_IDX}" "instructions/sage.md を読んで、\$AGENT_ROLE 環境変数で指定された役割を理解してください。"
        sleep 0.3
        tmux send-keys -t "nerv:0.${PANE_IDX}" Enter
        sleep 0.5
    done

    log_success "✅ 全ユニット プログラムロード完了"
    echo ""

    # アタッチ前に全ペインをクリア（表示のずれを防ぐ）
    log_info "  └─ 画面をクリア中..."
    sleep 2
    # MAGI (pane 0)
    tmux send-keys -t "nerv:0.0" C-l
    sleep 0.1
    # Sages (using SAGE_PANE_MAP)
    for ((i=1; i<=SAGE_COUNT; i++)); do
        PANE_IDX=${SAGE_PANE_MAP[$i]}
        tmux send-keys -t "nerv:0.${PANE_IDX}" C-l
        sleep 0.1
    done
    sleep 1
fi

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 6: 環境確認・完了メッセージ
# ═══════════════════════════════════════════════════════════════════════════════
log_info "🔍 システム状態をチェック中..."
echo ""
echo "  ┌──────────────────────────────────────────────────────────┐"
echo "  │  📺 Tmux セッション状態                                  │"
echo "  └──────────────────────────────────────────────────────────┘"
tmux list-sessions | sed 's/^/     /'
echo ""
echo "  ┌──────────────────────────────────────────────────────────┐"
echo "  │  📋 ペイン配置                                           │"
echo "  └──────────────────────────────────────────────────────────┘"
echo ""
echo "     【nerv セッション】マギ(左) + ${SAGE_COUNT}賢者(右・縦積み)"
echo "     ┌─────────┬─────────┐"
echo "     │         │ sage1   │"
if [ "$SAGE_COUNT" -ge 2 ]; then
echo "     │         ├─────────┤"
echo "     │  MAGI   │ sage2   │"
fi
if [ "$SAGE_COUNT" -ge 3 ]; then
echo "     │         ├─────────┤"
echo "     │  (NERV) │ sage3   │"
fi
if [ "$SAGE_COUNT" -ge 4 ]; then
echo "     │         ├─────────┤"
echo "     │         │ sage4   │"
fi
if [ "$SAGE_COUNT" -ge 5 ]; then
echo "     │         ├─────────┤"
echo "     │         │ sage5   │"
fi
if [ "$SAGE_COUNT" -ge 6 ]; then
echo "     │         ├─────────┤"
echo "     │         │ sage6   │"
fi
if [ "$SAGE_COUNT" -ge 7 ]; then
echo "     │         ├─────────┤"
echo "     │         │ sage7   │"
fi
if [ "$SAGE_COUNT" -ge 8 ]; then
echo "     │         ├─────────┤"
echo "     │         │ sage8   │"
fi
echo "     └─────────┴─────────┘"
echo ""

echo ""
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║  🔷 MAGI SYSTEM 起動完了！                                ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo ""

if [ "$SETUP_ONLY" = true ]; then
    echo "  ⚠️  セットアップのみモード: Claude Codeは未起動です"
    echo ""
    echo "  手動でClaude Codeを起動するには:"
    echo "  ┌──────────────────────────────────────────────────────────┐"
    echo "  │  # マギ を起動                                        │"
    echo "  │  tmux send-keys -t nerv:0.0 'claude --model opus --dangerously-skip-permissions' Enter │"
    echo "  │                                                          │"
    echo "  │  # 賢者を一斉起動                                        │"
    echo "  │  for i in {1..${SAGE_COUNT}}; do \\                       │"
    echo "  │    tmux send-keys -t nerv:0.\\\$i \\                       │"
    echo "  │      'claude --dangerously-skip-permissions' Enter       │"
    echo "  │  done                                                    │"
    echo "  └──────────────────────────────────────────────────────────┘"
    echo ""
fi

if [ "$SETUP_ONLY" = true ]; then
    echo "  次のステップ:"
    echo "  ┌──────────────────────────────────────────────────────────┐"
    echo "  │  tmux セッションにアタッチして Claude を起動:             │"
    echo "  │     tmux attach-session -t nerv                          │"
    echo "  │                                                          │"
    echo "  │  各ペインで Claude を手動起動:                           │"
    echo "  │    マギ: MAX_THINKING_TOKENS=0 claude --model opus --dangerously-skip-permissions │"
    echo "  │    賢者: claude --dangerously-skip-permissions           │"
    echo "  └──────────────────────────────────────────────────────────┘"
fi
echo ""
echo "  ════════════════════════════════════════════════════════════"
echo "   🔷 MAGI SYSTEM - Collective Intelligence"
echo "  ════════════════════════════════════════════════════════════"
echo ""

# マギのペインにフォーカスを当てる
tmux select-pane -t nerv:0.0 > /dev/null 2>&1

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 7: 自動アタッチ（デフォルト）
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$SETUP_ONLY" = false ] && [ "$DETACHED" = false ]; then
    echo ""
    log_info "🔌 NERV セッションにアタッチします..."
    echo ""
    echo "  💡 ヒント:"
    echo "     - Ctrl+b d でデタッチ"
    echo "     - 表示が崩れた場合は各ペインで Ctrl+L でリフレッシュ"
    echo ""
    sleep 2

    # tmux セッションにアタッチ
    tmux attach-session -t nerv
fi
