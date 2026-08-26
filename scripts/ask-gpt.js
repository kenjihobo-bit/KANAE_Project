#!/usr/bin/env node
// GPTに1つの質問(プロンプト)を投げて、回答をテキストで標準出力に返すだけのスクリプト。
//
// 使い方:
//   node scripts/ask-gpt.js "質問文をここに書く"
//
// 環境変数:
//   OPENAI_API_KEY (必須) … .envから自動的に読み込む
//   OPENAI_MODEL   (任意) … 省略時は gpt-5.6-terra(コスト重視。品質優先ならgpt-5.6-solを指定)

import OpenAI from 'openai';
import { loadEnv } from './load-env.js';

loadEnv();

const apiKey = process.env.OPENAI_API_KEY;
if (!apiKey) {
  console.error('エラー: OPENAI_API_KEY が設定されていません(.envを確認してください)。');
  process.exit(1);
}

const prompt = process.argv.slice(2).join(' ');
if (!prompt) {
  console.error('使い方: node scripts/ask-gpt.js "質問文"');
  process.exit(1);
}

const model = process.env.OPENAI_MODEL || 'gpt-5.6-terra';
const client = new OpenAI({ apiKey });

try {
  const response = await client.responses.create({ model, input: prompt });
  console.log(response.output_text ?? '(応答が空でした)');
} catch (err) {
  console.error(`GPT呼び出し中にエラーが発生しました: ${err.message}`);
  process.exit(1);
}
