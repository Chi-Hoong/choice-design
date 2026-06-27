import fs from 'node:fs';
const html = fs.readFileSync(new URL('../index.html', import.meta.url),'utf8');
const m = html.match(/<script>([\s\S]*?)<\/script>/);
if(!m){ console.error('no <script> found'); process.exit(1); }
let src = m[1];
const cut = src.indexOf('/* ============================== UI');
if(cut<0){ console.error('UI marker not found'); process.exit(1); }
src = src.slice(0, cut);                       // engine only, no DOM/UI/boot
const tail = fs.readFileSync(new URL('./harness_tail.js', import.meta.url),'utf8');
const outPath = new URL('./cf_headless.mjs', import.meta.url);
fs.writeFileSync(outPath, src + '\n' + tail);
console.log('built cf_headless.mjs:', (src+tail).length, 'chars; engine lines:', src.split('\n').length);
