const fs = require('fs');
const path = require('path');

const baseDir = path.join(__dirname, '..', 'assets', 'curriculum');

function countJsonFiles(dir) {
  let count = 0;
  const items = fs.readdirSync(dir);
  items.forEach(item => {
    const fullPath = path.join(dir, item);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      count += countJsonFiles(fullPath);
    } else if (item.endsWith('.json')) {
      count++;
    }
  });
  return count;
}

const categories = fs.readdirSync(baseDir).filter(name => {
  return fs.statSync(path.join(baseDir, name)).isDirectory();
});

console.log("=== EMPIRICAL JSON CURRICULUM FILE COUNT ===");
let grandTotal = 0;

categories.forEach(cat => {
  const catPath = path.join(baseDir, cat);
  const count = countJsonFiles(catPath);
  console.log(`Category: ${cat.padEnd(15)} | Files: ${count}`);
  grandTotal += count;
});

console.log("==========================================");
console.log(`Grand Total JSON Files: ${grandTotal}`);
