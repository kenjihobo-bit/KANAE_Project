#!/usr/bin/env node
// Geminiに1つの質問(プロンプト)を投げて、回答をテキストで標準出力に返すだけのスクリプト。
//
// 使い方:
//   node scripts/ask-gemini.js "質問文をここに書く"
//
// 環境変数:
//   GEMINI_API_KEY (必須) … .envから自動的に読み込む
//   GEMINI_MODEL   (任意) … 省略時は gemini-3.6-flash

import { GoogleGenAI } from '@google/genai';
import { loadEnv } from './load-env.js';

loadEnv();

const apiKey = process.env.GEMINI_API_KEY;
if (!apiKey) {
  console.error('エラー: GEMINI_API_KEY が設定されていません(.envを確認してください)。');
  process.exit(1);
}

const prompt = process.argv.slice(2).join(' ');
if (!prompt) {
  console.error('使い方: node scripts/ask-gemini.js "質問文"');
  process.exit(1);
}

const model = process.env.GEMINI_MODEL || 'gemini-3.6-flash';
const ai = new GoogleGenAI({ apiKey });

try {
  const response = await ai.models.generateContent({ model, contents: prompt });
  console.log(response.text ?? '(応答が空でした)');
} catch (err) {
  console.error(`Gemini呼び出し中にエラーが発生しました: ${err.message}`);
  process.exit(1);
}
