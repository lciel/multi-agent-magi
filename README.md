# 🔷 MAGI SYSTEM

> Multi-AI Decision Support System
> Inspired by NEON GENESIS EVANGELION

**複数AI による集合知意思決定システム**

---

## 概要

MAGI System は、エヴァンゲリオンの MAGI システムをモチーフとした AI 意思決定支援システムです。

- **マギ (MAGI)**: 質問を分析し、複数の 賢者 (Sage) に最適な役割を割り当て
- **賢者 (3-8人)**: 異なる視点・専門性で独立して意見を形成
- **統合回答**: マギ が全 賢者の意見を分析・統合し、最終回答を生成

### 用途

- プロジェクト進め方の相談
- 技術選定（React vs Vue 等）
- プロダクト意見収集
- 戦略的意思決定
- 倫理的判断

### 特徴

✅ **動的役割設計**: 質問内容に応じて最適な役割を自動設計
✅ **独立性保持**: 各賢者は他の意見を見ずに独立判断
✅ **対立視点配置**: 批判者・楽観者等、多様な視点を保証
✅ **3-8人の柔軟な人数**: 質問の複雑さに応じて最適な人数
✅ **イベント駆動**: ポーリングなし、API代金節約

---

## システム構成

```
人間
  ↓ 質問
マギ (MAGI)
  ↓ 諮問
賢者 1-8（賢者）
  ↓ 意見
マギ (MAGI)
  ↓ 統合回答
人間
```

### tmux ペイン配置

デフォルトは3賢者（`-n` オプションで3-8人に変更可能）

**注意**: 7-8賢者の起動にはターミナルウィンドウの高さが十分に必要です。サイズ不足の場合は起動時にエラーが表示されます。

**1-4賢者の場合（2列レイアウト）:**
```
┌──────────┬──────────┐
│          │  sage4   │
│          ├──────────┤
│   MAGI   │  sage3   │
│  (NERV)  ├──────────┤
│          │  sage2   │
│          ├──────────┤
│          │  sage1   │
└──────────┴──────────┘
```

**5-8賢者の場合（3列レイアウト、`./launch_magi.sh -n 8`）:**
```
┌──────────┬──────────┬──────────┐
│          │  sage4   │  sage8   │
│          ├──────────┼──────────┤
│   MAGI   │  sage3   │  sage7   │
│  (NERV)  ├──────────┼──────────┤
│          │  sage2   │  sage6   │
│          ├──────────┼──────────┤
│          │  sage1   │  sage5   │
└──────────┴──────────┴──────────┘
```

- MAGI: 左列フルハイト（1-4賢者時35%幅、5-8賢者時30%幅）
- 中列: sage1-4（5-8賢者時のみ、35%幅）
- 右列: sage5-8（5-8賢者時のみ、35%幅）

**注意**: 7-8賢者の起動には十分なターミナル高さ（推奨60行以上）が必要です。

---

## インストール

### 前提条件

- tmux
- Node.js (18以上)
- Claude Code CLI (`npm install -g @anthropic-ai/claude-code`)

### セットアップ

```bash
cd /Users/louis/tmp/multi-agent-magi
chmod +x first_setup.sh launch_magi.sh
./first_setup.sh
```

---

## 使い方

### 1. システム起動

```bash
# 起動（3賢者、デフォルト）
./launch_magi.sh
```

起動すると自動的にマギのペインにアタッチされ、すぐに質問を開始できます。

**賢者数を変更:**
```bash
./launch_magi.sh -n 5  # 5賢者で起動
./launch_magi.sh -n 8  # 8賢者で起動（最大、大きなウィンドウが必要）
```

**バックグラウンド起動:**
```bash
./launch_magi.sh -d           # 起動のみ（アタッチしない）
tmux attach-session -t nerv   # 後でアタッチ
```

**tmux の基本操作：**
- `Ctrl+b d` - デタッチ（バックグラウンドに戻す）
- `Ctrl+b 矢印` - ペイン移動
- `Ctrl+L` - 画面リフレッシュ

### 2. マギ に直接質問

**例**：
- 「React vs Vue どっちがいい？」
- 「新機能を追加すべきか、既存機能の改善を優先すべきか？」
- 「このプロダクトのUIをどう改善すべき？」

マギ が自動的に：
1. 質問を分析
2. 最適な 賢者の人数と役割を決定
3. 賢者に諮問
4. 意見を統合して回答

### 3. (オプション) YAML 経由で質問

より詳細な設定が必要な場合、`queue/human_to_magi.yaml` を編集：

```yaml
question:
  id: "q_001"
  timestamp: "2026-02-02T15:30:00"
  content: "新規プロジェクトでReact vs Vueどちらを選ぶべきか？"
  context:
    project_type: "Webアプリケーション"
    team_size: 5
  sage_count: null  # null = マギ が自動決定
  status: pending
```

マギ に「queue/human_to_magi.yaml に質問がある。処理してください。」と伝える。

### 4. 回答確認

`queue/final_answer.yaml` を読む：

```bash
cat queue/final_answer.yaml
```

---

## ディレクトリ構造

```
/Users/louis/tmp/multi-agent-magi/
├── CLAUDE.md                    # システム詳細仕様
├── README.md                    # このファイル
├── first_setup.sh               # 初回セットアップ
├── launch_magi.sh               # 起動スクリプト
├── config/
│   ├── settings.yaml            # 言語・シェル設定
│   └── magi_personas.yaml       # ペルソナプリセット
├── instructions/
│   ├── magi.md                  # マギ指示書
│   └── sage.md                  # 賢者指示書
├── queue/
│   ├── human_to_magi.yaml       # 人間→マギ質問
│   ├── magi_to_sage.yaml        # マギ→賢者諮問
│   ├── opinions/                # 賢者意見格納
│   │   ├── sage1_opinion.yaml
│   │   ├── sage2_opinion.yaml
│   │   └── ... (sage3-8)
│   └── final_answer.yaml        # マギ→人間回答
├── logs/                        # ログ
└── memory/                      # Memory MCP
```

---

## 例: React vs Vue 技術選定

### 質問（人間）

```yaml
question:
  content: "新規プロジェクトでReact vs Vueどちらを選ぶべきか？"
  context:
    project_type: "Webアプリケーション"
    team_size: 5
  sage_count: null
  status: pending
```

### マギ の役割設計

```yaml
consultation:
  question: "React vs Vue?"
  sage_count: 5
  roles:
    sage1:
      persona: "シニアフロントエンドエンジニア"
      perspective: "技術的専門性"
    sage2:
      persona: "QAエンジニア"
      perspective: "品質・テスト容易性"
    sage3:
      persona: "初心者ユーザー"
      perspective: "学習曲線"
    sage4:
      persona: "批判者"
      perspective: "リスク・弱点"
    sage5:
      persona: "採用担当"
      perspective: "採用・開発者体験"
```

### 賢者の意見

- **sage1** (技術): React推奨（TypeScript統合、エコシステム）
- **sage2** (QA): React推奨（テストツール充実）
- **sage3** (初心者): Vue推奨（学習曲線が緩やか）
- **sage4** (批判者): React推奨（Vue はエンタープライズ実績少ない）
- **sage5** (採用): React推奨（求人市場で有利）

### 統合回答

```yaml
answer:
  summary: "【結論】React を推奨（5票中4票）"
  magi_votes:
    react: 4
    vue: 1
  detailed_synthesis: |
    ## 結論
    React を推奨する。5人中4人が React を推奨した。

    ## 多数意見: React 推奨
    - 技術的優位性: TypeScript統合、エコシステム
    - 品質保証: テストツール充実
    - 採用優位性: 求人市場で有利

    ## 少数意見: Vue 推奨
    - 学習曲線: Vue の方が初心者に優しい
    - 注意: チーム内に初心者が多い場合、この視点は重要

    ## 推奨アクション
    1. React を選択
    2. 初心者向けオンボーディング資料を充実させる
    3. 3ヶ月後、チームの習熟度を再評価
  action_items:
    - "React を選択"
    - "初心者向けオンボーディング資料を作成"
    - "3ヶ月後に習熟度を再評価"
```

---

## 設定

### 言語設定

`config/settings.yaml` で言語を変更：

```yaml
language: ja  # ja (日本語), en (英語), es (スペイン語) 等
```

- **ja**: システマティックな日本語のみ
- **その他**: システマティックな日本語 + 翻訳併記

### シェル設定

```yaml
shell: bash  # bash or zsh
```

---

## トラブルシューティング

### tmux セッションが起動しない

```bash
# 既存セッションを確認
tmux ls

# 強制終了
tmux kill-session -t nerv
```

### Claude Code が起動しない

```bash
# Claude Code CLI がインストールされているか確認
which claude

# 未インストールの場合
npm install -g @anthropic-ai/claude-code
```

### send-keys が届かない

- 2回のBash呼び出しに分けているか確認
- マギ / 賢者 が処理中（busy）でないか確認
- 報告ファイル自体は正しく書かれているので、手動で確認可能

---

## アーキテクチャ詳細

詳細は `CLAUDE.md` を参照してください。

- 通信プロトコル
- YAMLファイル構造
- コンパクション復帰手順
- 設計哲学

---

## クレジット

このプロジェクトは [multi-agent-shogun](https://github.com/yohey-w/multi-agent-shogun) にインスパイアされて作成されました。

マルチエージェント通信プロトコル（YAML + tmux send-keys）のアイデアと設計思想を参考にしています。

---

## ライセンス

- MAGI System: オリジナル実装
- Evangelion MAGI System: モチーフとして使用（著作権: カラー）

---

## バージョン

- v1.0.0 (2026-02-02): 初版リリース

---

## サポート

質問・バグ報告は GitHub Issues へ。

---

🔷 **MAGI SYSTEM - Collective Intelligence for Better Decisions**
