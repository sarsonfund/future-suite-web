require('dotenv').config();

const express = require('express');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 8080;
const APP_DISPLAY_NAME = process.env.APP_DISPLAY_NAME || 'Future Suite (DEV)';
const APP_IDENTIFIER = process.env.APP_IDENTIFIER || 'future-suite-dev';

function sendIndex(req, res) {
  const htmlPath = path.join(__dirname, 'public', 'index.html');
  let html = fs.readFileSync(htmlPath, 'utf8');
  html = html.replace(/__APP_DISPLAY_NAME__/g, APP_DISPLAY_NAME);
  html = html.replace(/__APP_IDENTIFIER__/g, APP_IDENTIFIER);
  res.type('text/html').send(html);
}

app.get('/', sendIndex);
app.get('/index.html', sendIndex);

app.use(express.static(path.join(__dirname, 'public')));

app.listen(PORT, () => {
  console.log(`${APP_DISPLAY_NAME} listening on port ${PORT}`);
});
