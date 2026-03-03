const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch({ headless: "new" });
  const page = await browser.newPage();
  await page.goto('https://v1.samehadaku.how/', { waitUntil: 'networkidle2' });
  const content = await page.content();
  console.log(content.substring(0, 500));
  await browser.close();
})();
