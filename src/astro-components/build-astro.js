#!/usr/bin/env node

/**
 * Build script for Astro components
 * Compiles Astro components and copies them to Phoenix assets directory
 */

import { execSync } from 'child_process';
import { copyFileSync, existsSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const projectRoot = join(__dirname, '../..');
const astroDir = join(__dirname, '.');
const assetsDir = join(projectRoot, 'assets');

console.log('🚀 Building Astro components...');

try {
  // Build Astro components
  console.log('📦 Building Astro project...');
  execSync('npm run build', { 
    cwd: astroDir, 
    stdio: 'inherit' 
  });

  // Create assets directory if it doesn't exist
  const astroAssetsDir = join(assetsDir, 'astro');
  if (!existsSync(astroAssetsDir)) {
    mkdirSync(astroAssetsDir, { recursive: true });
  }

  // Copy built assets to Phoenix assets directory
  console.log('📋 Copying built assets...');
  
  // Copy JavaScript files
  const distDir = join(astroDir, 'dist');
  const jsFiles = ['_astro/*.js', '_astro/*.mjs'];
  
  jsFiles.forEach(pattern => {
    try {
      execSync(`cp -r ${join(distDir, pattern)} ${astroAssetsDir}/`, { 
        stdio: 'inherit' 
      });
    } catch (error) {
      console.warn(`Warning: Could not copy ${pattern}:`, error.message);
    }
  });

  // Copy CSS files
  try {
    execSync(`cp -r ${join(distDir, '_astro/*.css')} ${astroAssetsDir}/`, { 
      stdio: 'inherit' 
    });
  } catch (error) {
    console.warn('Warning: Could not copy CSS files:', error.message);
  }

  console.log('✅ Astro components built and copied successfully!');
  console.log(`📁 Assets copied to: ${astroAssetsDir}`);

} catch (error) {
  console.error('❌ Error building Astro components:', error.message);
  process.exit(1);
}
