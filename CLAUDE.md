# MAGI SYSTEM - システム構成

> **Version**: 1.0.0
> **Last Updated**: 2026-02-02
> **Inspired by**: NEON GENESIS EVANGELION

## 概要

MAGI System は、エヴァンゲリオンの MAGI システムをモチーフとした3レイヤーAI意思決定システムである。
複数の賢者が異なる視点で意見を形成し、マギ が統合して回答を生成する集合知システム。

**構造**: 人間 => マギ (MAGI) => 賢者 (3-8人の賢者)

**用途**: プロジェクト進め方相談、技術選定、プロダクト意見収集など、複雑な意思決定の支援

**通信**: YAML + tmux send-keys（イベント駆動）

---

## 階層構造

```
人間（The Lord）
  │
  ▼ 質問
┌──────────────┐
│  マギ     │ ← 質問分析・役割設計・回答統合
│  (NERV)      │
└──────┬───────┘
       │ YAMLファイル経由
       ▼
┌───┬───┬───┬───┬───┬───┬───┬───┐
│M1 │M2 │M3 │M4 │M5 │M6 │M7 │M8 │ ← 賢者 (Sage)
└───┴───┴───┴───┴───┴───┴───┴───┘
```

### マギ (MAGI) の役割

1. **質問分析**: 質問の種類・必要な視点を分析
2. **役割設計**: 各賢者の役割・ペルソナを動的に設計
3. **賢者人数決定**: 3-8人の最適な人数を決定
4. **回答統合**: 賢者からの意見を分析・統合
5. **最終回答生成**: 多数決・対立点の明示・アクションアイテム抽出

### 賢者 (Sage) の役割

1. **役割理解**: マギ から指定された役割を理解
2. **意見形成**: 指定された視点で独立して意見を形成
3. **報告**: 意見を マギ に報告

---

## 通信プロトコル

### イベント駆動通信（YAML + send-keys）

- ポーリング禁止（API代金節約のため）
- 質問・意見内容はYAMLファイルに書く
- 通知は tmux send-keys で相手を起こす（必ず Enter を使用）
- **send-keys は必ず2回のBash呼び出しに分けよ**（1回で書くとEnterが正しく解釈されない）：
  ```bash
  # 【1回目】メッセージを送る
  tmux send-keys -t nerv:0.0 'メッセージ内容'
  # 【2回目】Enterを送る
  tmux send-keys -t nerv:0.0 Enter
  ```

### 通信の流れ

```
【1】人間が質問
  → queue/human_to_magi.yaml に書き込み
  → マギ を起動

【2】マギ: 質問分析・役割設計
  → queue/human_to_magi.yaml を読む
  → 質問を分析（技術選定？戦略相談？）
  → 必要な賢者人数を決定（3-8人）
  → 各賢者の役割を設計
  → queue/magi_to_sage.yaml に諮問を書く
  → send-keys で各賢者を起動

【3】賢者: 意見形成
  → queue/magi_to_sage.yaml を読む
  → 自分のIDに対応する役割を確認
  → 役割に応じた意見を形成
  → queue/opinions/sage{N}_opinion.yaml に書く
  → send-keys で マギ に報告

【4】マギ: 回答統合
  → 全賢者からの報告を受ける
  → queue/opinions/*.yaml を収集
  → 意見を分析・統合
  → queue/final_answer.yaml に書く
  → 人間に通知（ターミナル表示）

【5】人間が回答確認
  → queue/final_answer.yaml を読む
```

---

## ファイル構成

```
/Users/louis/tmp/multi-agent-magi/
├── CLAUDE.md                          # このファイル
├── README.md                          # 使い方
├── first_setup.sh                     # 初回セットアップ
├── launch_magi.sh                     # 起動スクリプト
├── config/
│   ├── settings.yaml                  # 言語・シェル設定
│   └── magi_personas.yaml             # ペルソナプリセット
├── instructions/
│   ├── magi.md                        # マギ指示書
│   └── sage.md                        # 賢者指示書
├── queue/
│   ├── human_to_magi.yaml             # 人間→マギ質問
│   ├── magi_to_sage.yaml              # マギ→賢者諮問
│   ├── opinions/                      # 賢者意見格納
│   │   ├── sage1_opinion.yaml
│   │   ├── sage2_opinion.yaml
│   │   └── ... (sage3-8)
│   └── final_answer.yaml              # マギ→人間回答
├── logs/                              # ログ（将来実装）
└── memory/                            # Memory MCP（オプション）
```

---

## tmux セッション構成

### nerv セッション（可変ペイン数）

**セッション名**: `nerv`

**ペイン配置**: 賢者数に応じて動的に変化

**デフォルト**: 4ペイン（マギ + 3賢者）

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
  Pane 0
```
- MAGI: 左列フルハイト（35%幅）
- 賢者: 右列に縦積み（65%幅）

**5-8賢者の場合（3列レイアウト）:**
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
  Pane 0
```
- MAGI: 左列フルハイト（30%幅）
- 中列: sage1-4（35%幅）
- 右列: sage5-8（35%幅）

**起動オプション**: `-n` で3-8賢者に変更可能

**注意**: 7-8賢者の起動にはターミナルウィンドウの高さが十分に必要です（推奨60行以上）。サイズ不足の場合は起動時にエラーメッセージが表示されます。

- Pane 0 (nerv:0.0): マギ（NERV）- 質問分析、役割設計、回答統合
- 各賢者は環境変数 `AGENT_ROLE` で自身のIDを識別（sage1, sage2, ...）

---

## 言語設定

config/settings.yaml の `language` で言語を設定する。

```yaml
language: ja  # ja, en, es, zh, ko, fr, de 等
```

### language: ja の場合
システマティックな日本語のみ。併記なし。
- 「了解しました」 - 了解
- 「確認しました」 - 理解した
- 「意見を報告します」 - 意見完成

### language: ja 以外の場合
システマティックな日本語 + ユーザー言語の翻訳を括弧で併記。
- 「了解しました (Acknowledged)」 - 了解
- 「確認しました (Confirmed)」 - 理解した
- 「意見を報告します (Reporting opinion)」 - 意見完成

---

## 主要YAMLファイル構造

### queue/human_to_magi.yaml
```yaml
question:
  id: "q_001"
  timestamp: "2026-02-02T15:30:00"
  content: "新規プロジェクトでReact vs Vueどちらを選ぶべきか？"
  context:
    project_type: "Webアプリケーション"
    team_size: 5
  sage_count: null  # null=マギ決定、指定=その人数
  status: pending
```

### queue/magi_to_sage.yaml
```yaml
consultation:
  question_id: "q_001"
  timestamp: "2026-02-02T15:31:00"
  question: "新規プロジェクトでReact vs Vueどちらを選ぶべきか？"
  sage_count: 5
  roles:
    sage1:
      name: "MELCHIOR"
      persona: "シニアフロントエンド開発者"
      perspective: "技術的専門性"
      instruction: "技術的観点から両者を比較評価してください"
    sage2: {...}
    # ... sage3-5
  status: pending
```

### queue/opinions/sage{N}_opinion.yaml
```yaml
sage_id: sage1
role_name: "MELCHIOR"
persona: "シニアフロントエンド開発者"
question_id: "q_001"
timestamp: "2026-02-02T15:33:00"
opinion:
  stance: "React推奨"
  confidence: 8
  reasoning: "..."
  pros_cons: {...}
  recommendation: "..."
status: completed
```

### queue/final_answer.yaml
```yaml
answer:
  question_id: "q_001"
  timestamp: "2026-02-02T15:40:00"
  summary: "【結論】React を推奨（5票中4票）"
  sage_votes:
    react: 4
    vue: 1
  detailed_synthesis: "..."
  action_items: [...]
  status: completed
```

---

## 起動方法

### 初回セットアップ
```bash
cd /Users/louis/tmp/multi-agent-magi
./first_setup.sh
```

### 起動
```bash
./launch_magi.sh
```

### tmux セッションにアタッチ
```bash
tmux attach-session -t nerv
```

---

## 使用方法

1. **質問を書く**: queue/human_to_magi.yaml に質問を書く
2. **マギ を起動**: マギ ペイン(nerv:0.0) を選択
3. **質問処理を依頼**: 「queue/human_to_magi.yaml に質問がある。処理してください。」
4. **回答確認**: queue/final_answer.yaml を読む

---

## コンパクション復帰時（全エージェント必須）

コンパクション後は作業前に必ず以下を実行してください：

1. **自分の位置を確認**: `tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}'`
   - `nerv:0.0` → マギ
   - `nerv:0.1` ～ `nerv:0.8` → 賢者 1～8
2. **対応する instructions を読む**:
   - マギ → instructions/magi.md
   - 賢者 → instructions/sage.md
3. **instructions 内の「コンパクション復帰手順」に従い、正データから状況を再把握する**
4. **禁止事項を確認してから作業開始**

**重要**: 正データは各YAMLファイル（queue/human_to_magi.yaml, queue/magi_to_sage.yaml, queue/opinions/, queue/final_answer.yaml）です。
コンパクション復帰時は必ず正データを参照してください。

---

## 設計哲学

### 1. 動的役割設計
- マギ が質問内容に応じて各賢者の役割を設計
- 固定役割割当なし
- 質問に最適化された視点を提供

### 2. 独立性の保持
- 各賢者は他賢者の意見を見ずに独立して判断
- 多様な視点を保証

### 3. 対立視点の配置
- 必ず批判的視点を含める
- 楽観/悲観、短期/長期の両視点

### 4. シンプルな設計
- ダッシュボードなし
- final_answer.yaml を直接参照

---

## ライセンス・著作権

- MAGI System: オリジナル実装
- Evangelion MAGI System: モチーフとして使用（著作権: カラー）
- tmux send-keys プロトコル: multi-agent-shogun から継承

---

## バージョン履歴

- v1.0.0 (2026-02-02): 初版リリース
