require('dotenv').config();

const express = require('express');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 8080;
const APP_DISPLAY_NAME = process.env.APP_DISPLAY_NAME || 'Future Suite (DEV)';
const APP_IDENTIFIER = process.env.APP_IDENTIFIER || 'future-suite-dev';

const pillarUrls = {
  production: {
    privateLLM: 'https://jaco.manifest.network',
    portfolio: 'https://www.sumascan.ai',
    aiTools: 'https://manifest.network',
  },
  staging: {
    privateLLM: 'https://jaco-stg.manifest.network',
    portfolio: 'https://www.sumascan.ai',
    aiTools: 'https://manifest.network',
  },
  dev: {
    privateLLM: 'https://jaco-stg.manifest.network',
    portfolio: 'https://www.sumascan.ai',
    aiTools: 'https://manifest.network',
  },
};

function getPillarUrls() {
  if (APP_IDENTIFIER === 'future-suite') return pillarUrls.production;
  if (APP_IDENTIFIER === 'future-suite-qa') return pillarUrls.staging;
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

app.listen(PORT, () => {
  console.log(`${APP_DISPLAY_NAME} listening on port ${PORT}`);
});
