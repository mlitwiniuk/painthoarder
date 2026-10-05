#!/usr/bin/env node

import * as esbuild from 'esbuild'
import rails from 'esbuild-rails'
import path from 'path'
import { execFileSync } from 'node:child_process'
import { copy } from 'esbuild-plugin-copy'

const entryPoints = [
  'application.js',
  'service-worker.js'
]
const config = {
  absWorkingDir: path.join(process.cwd(), 'app/assets/javascripts'),
  bundle: true,
  entryPoints: entryPoints,
  minify: process.env.RAILS_ENV == 'production',
  outdir: path.join(process.cwd(), 'app/assets/builds'),
  plugins: [
    rails(),
    copy({
      resolveFrom: path.join(process.cwd(), 'public/assets'),
      assets: [
        {
          from: [
            './node_modules/heroicons/24/**/*.svg',
          ],
          to: ['./icons/heroicons'],
          keepStructure: true
        }
      ]
    }),
    {
      name: 'service-worker',
      setup(build) {
        build.onEnd(result => {
          if (result.errors.length) return
          execFileSync(process.execPath, ['script/build-service-worker.mjs'], { stdio: 'inherit' })
        })
      }
    }
  ],
  sourcemap: process.argv.includes('--sourcemap')
}

if (process.argv.includes('--watch')) {
  const context = await esbuild.context({ ...config, logLevel: 'info' })
  await context.watch()
  console.log('Watching for changes...')
} else {
  await esbuild.build(config)
  console.log('JavaScript build complete')
}
