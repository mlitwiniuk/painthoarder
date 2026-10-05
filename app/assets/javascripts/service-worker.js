import { precacheAndRoute } from 'workbox-precaching'
import { setDefaultHandler } from 'workbox-routing'
import { NetworkOnly } from 'workbox-strategies'

setDefaultHandler(new NetworkOnly())

precacheAndRoute(self.__WB_MANIFEST || [])
