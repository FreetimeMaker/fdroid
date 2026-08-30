const { put } = require('@vercel/blob');
const fs = require('fs');
const path = require('path');

const REPO_DIR = path.join(__dirname, '../../fdroid/repo');
const PREFIX = 'fdroid/repo';

async function uploadDir(dir, prefix) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    const blobPath = `${prefix}/${entry.name}`;
    if (entry.isDirectory()) {
      await uploadDir(fullPath, blobPath);
    } else {
      const buffer = fs.readFileSync(fullPath);
      await put(blobPath, buffer, {
        access: 'public',
        addRandomSuffix: false,
        token: process.env.BLOB_READ_WRITE_TOKEN,
      });
      console.log(`Uploaded ${blobPath}`);
    }
  }
}

uploadDir(REPO_DIR, PREFIX).catch((err) => {
  console.error(err);
  process.exit(1);
});