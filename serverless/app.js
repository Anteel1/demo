
const express = require('express');
const app = express();

app.use(express.json()); // parse JSON body
app.get('/health', (req, res) => {
  res.json({ ok: true, ts: Date.now() });
});

app.get('/random', (req, res) => {
  const nums = Array.from({ length: 6 }, () => Math.floor(Math.random() * 49) + 1)
    .sort((a, b) => a - b);
  res.json({ numbers: nums });
});

app.post('/echo', (req, res) => {
  res.json({ youSent: req.body });
});

module.exports = app;
