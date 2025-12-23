#!/usr/bin/env node

/**
 * Link Checker for flow-cli Documentation
 * Checks for broken internal and external links in markdown files
 */

const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');

const results = {
  filesChecked: 0,
  totalLinks: 0,
  brokenLinks: [],
  internalLinks: 0,
  externalLinks: 0
};

// Files to check
const filesToCheck = [
  'README.md',
  'docs/index.md',
  'docs/user/WORKFLOWS-QUICK-WINS.md',
  'docs/user/ALIAS-REFERENCE-CARD.md',
  'docs/user/WORKFLOW-QUICK-REFERENCE.md',
  'docs/user/PICK-COMMAND-REFERENCE.md',
  'docs/user/DASHBOARD-QUICK-REF.md',
  'docs/getting-started/quick-start.md',
  'docs/getting-started/installation.md',
  'docs/architecture/README.md',
  'docs/architecture/ARCHITECTURE-QUICK-WINS.md'
];

// Extract markdown links
function extractLinks(content) {
  // Match [text](url) and [text]: url
  const linkPattern = /\[([^\]]+)\]\(([^)]+)\)|\[([^\]]+)\]:\s*(\S+)/g;
  const links = [];
  let match;

  while ((match = linkPattern.exec(content)) !== null) {
    const url = match[2] || match[4];
    if (url && !url.startsWith('#')) { // Skip anchor-only links
      links.push({
        text: match[1] || match[3],
        url: url
      });
    }
  }

  return links;
}

// Check if internal file exists
function checkInternalLink(baseFile, url) {
  const baseDir = path.dirname(baseFile);

  // Remove anchor
  const cleanUrl = url.split('#')[0];
  if (!cleanUrl) return true; // Anchor-only in same file

  const targetPath = path.resolve(baseDir, cleanUrl);
  return fs.existsSync(targetPath);
}

// Check external link (with timeout)
function checkExternalLink(url) {
  return new Promise((resolve) => {
    const protocol = url.startsWith('https') ? https : http;
    const timeout = 5000; // 5 second timeout

    const req = protocol.get(url, { timeout }, (res) => {
      resolve(res.statusCode >= 200 && res.statusCode < 400);
    });

    req.on('error', () => resolve(false));
    req.on('timeout', () => {
      req.destroy();
      resolve(null); // null = timeout
    });
  });
}

// Process a single file
async function processFile(filePath) {
  console.log(`\nChecking: ${filePath}`);

  if (!fs.existsSync(filePath)) {
    console.log(`  ⚠️  File not found: ${filePath}`);
    return;
  }

  results.filesChecked++;
  const content = fs.readFileSync(filePath, 'utf8');
  const links = extractLinks(content);

  console.log(`  Found ${links.length} links`);

  for (const link of links) {
    results.totalLinks++;
    const { url, text } = link;

    // Categorize link
    const isExternal = url.startsWith('http://') || url.startsWith('https://');

    if (isExternal) {
      results.externalLinks++;
      console.log(`  🌐 External: ${url.substring(0, 50)}...`);

      const status = await checkExternalLink(url);
      if (status === false) {
        results.brokenLinks.push({
          file: filePath,
          url,
          text,
          type: 'external',
          reason: 'HTTP error or unreachable'
        });
        console.log(`    ❌ BROKEN`);
      } else if (status === null) {
        console.log(`    ⏱️  Timeout (may be slow)`);
      } else {
        console.log(`    ✅ OK`);
      }
    } else {
      results.internalLinks++;
      console.log(`  📄 Internal: ${url}`);

      if (!checkInternalLink(filePath, url)) {
        results.brokenLinks.push({
          file: filePath,
          url,
          text,
          type: 'internal',
          reason: 'File not found'
        });
        console.log(`    ❌ BROKEN - file not found`);
      } else {
        console.log(`    ✅ OK`);
      }
    }
  }
}

// Main execution
async function main() {
  console.log('='.repeat(60));
  console.log('flow-cli Documentation Link Checker');
  console.log('='.repeat(60));

  const rootDir = process.cwd();

  for (const file of filesToCheck) {
    const fullPath = path.join(rootDir, file);
    await processFile(fullPath);
  }

  // Print summary
  console.log('\n' + '='.repeat(60));
  console.log('SUMMARY');
  console.log('='.repeat(60));
  console.log(`Files checked:    ${results.filesChecked}`);
  console.log(`Total links:      ${results.totalLinks}`);
  console.log(`  Internal links: ${results.internalLinks}`);
  console.log(`  External links: ${results.externalLinks}`);
  console.log(`Broken links:     ${results.brokenLinks.length}`);

  if (results.brokenLinks.length > 0) {
    console.log('\n' + '='.repeat(60));
    console.log('BROKEN LINKS');
    console.log('='.repeat(60));

    results.brokenLinks.forEach((broken, idx) => {
      console.log(`\n${idx + 1}. ${broken.type.toUpperCase()} LINK`);
      console.log(`   File: ${broken.file}`);
      console.log(`   Text: "${broken.text}"`);
      console.log(`   URL:  ${broken.url}`);
      console.log(`   Reason: ${broken.reason}`);
    });

    console.log('\n' + '='.repeat(60));
    console.log('RECOMMENDATIONS');
    console.log('='.repeat(60));

    const internal = results.brokenLinks.filter(l => l.type === 'internal');
    const external = results.brokenLinks.filter(l => l.type === 'external');

    if (internal.length > 0) {
      console.log(`\n📄 ${internal.length} Internal link(s) to fix:`);
      internal.forEach(l => {
        console.log(`   - ${l.file}: "${l.url}"`);
        console.log(`     → Check if file was moved/renamed`);
      });
    }

    if (external.length > 0) {
      console.log(`\n🌐 ${external.length} External link(s) to verify:`);
      external.forEach(l => {
        console.log(`   - ${l.file}: ${l.url}`);
        console.log(`     → Check if URL is correct or site is down`);
      });
    }
  } else {
    console.log('\n✅ All links are valid!');
  }

  console.log('\n');
  process.exit(results.brokenLinks.length > 0 ? 1 : 0);
}

main().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
