import { injectManifest } from 'workbox-build'
import config from '../workbox.config.js'

const { count, warnings } = await injectManifest(config)
warnings.forEach(warning => console.warn(warning))
console.log(`Service worker precaches ${count} files`)
