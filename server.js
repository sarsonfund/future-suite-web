require('dotenv').config();

const express = require('express');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 8080;
const APP_DISPLAY_NAME = process.env.APP_DISPLAY_NAME || 'SF Digital (DEV)';
const APP_IDENTIFIER = process.env.APP_IDENTIFIER || 'sf-digital-dev';

const pillarUrls = {
  production: {
    privateLLM: 'https://agent1.manifest.network',
    portfolio: 'https://app.sumascan.ai',
    aiTools: 'https://manifest.network',
  },
  staging: {
    privateLLM: 'https://agent1.manifest.network',
    portfolio: 'https://app.sumascan.ai',
    aiTools: 'https://manifest.network',
  },
  dev: {
    privateLLM: 'https://agent1.manifest.network',
    portfolio: 'https://app.sumascan.ai',
    aiTools: 'https://manifest.network',
  },
};

function getPillarUrls() {
  if (APP_IDENTIFIER === 'sf-digital') return pillarUrls.production;
  if (APP_IDENTIFIER === 'sf-digital-qa') return pillarUrls.staging;
  return pillarUrls.dev;
}

function sendIndex(req, res) {
  const htmlPath = path.join(__dirname, 'public', 'index.html');
  let html = fs.readFileSync(htmlPath, 'utf8');
  const urls = getPillarUrls();
  html = html.replace(/__APP_DISPLAY_NAME__/g, APP_DISPLAY_NAME);
  html = html.replace(/__APP_IDENTIFIER__/g, APP_IDENTIFIER);
  html = html.replace(/__PILLAR_URL_PRIVATE_LLM__/g, urls.privateLLM);
  html = html.replace(/__PILLAR_URL_PORTFOLIO__/g, urls.portfolio);
  html = html.replace(/__PILLAR_URL_AI_TOOLS__/g, urls.aiTools);
  res.type('text/html').send(html);
}

app.get('/', sendIndex);
app.get('/index.html', sendIndex);

app.use(express.static(path.join(__dirname, 'public')));

// --- Prompt cron: sends a crypto prompt to agent1 every 15 minutes ---
const AGENT1_API_KEY = process.env.AGENT1_API_KEY;
const AGENT1_URL = 'https://agent1.manifest.network/v1/chat/completions';
const CRON_INTERVAL_MS = 15 * 60 * 1000;

const prompts = JSON.parse(fs.readFileSync(path.join(__dirname, 'prompts.json'), 'utf8'));
let promptIndex = 0;

async function sendPrompt() {
  if (!AGENT1_API_KEY) {
    console.log('[cron] AGENT1_API_KEY not set, skipping');
    return;
  }

  const prompt = prompts[promptIndex % prompts.length];
  console.log(`[cron] Sending prompt ${promptIndex + 1}/${prompts.length}: "${prompt.slice(0, 60)}..."`);

  try {
    const res = await fetch(AGENT1_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${AGENT1_API_KEY}`,
      },
      body: JSON.stringify({
        model: 'default',
        messages: [{ role: 'user', content: prompt }],
      }),
    });

    if (res.ok) {
      const data = await res.json();
      const reply = data.choices?.[0]?.message?.content?.slice(0, 100) || '(no content)';
      console.log(`[cron] Response OK: "${reply}..."`);
    } else {
      console.error(`[cron] Response error: ${res.status} ${res.statusText}`);
    }
  } catch (err) {
    console.error(`[cron] Request failed: ${err.message}`);
  }

  promptIndex++;
}

app.listen(PORT, () => {
  console.log(`${APP_DISPLAY_NAME} listening on port ${PORT}`);

  if (AGENT1_API_KEY) {
    console.log(`[cron] Prompt cron active — ${prompts.length} prompts, every 15 min`);
    sendPrompt();
    setInterval(sendPrompt, CRON_INTERVAL_MS);
  } else {
    console.log('[cron] AGENT1_API_KEY not set — prompt cron disabled');
  }
});
