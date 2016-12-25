//console.log('Worker launched!')

/**
 * Store pending request in global scope
 * It's ok to do that because we don't need to persist state accross page reloads,
 * and because we want to store callbacks, we can't use IndexedDb
 */
const pendingRequests = {}

// Channel used to communicate between worker and page
let messageChannel = null

self.addEventListener('fetch', (event) => {
  if (messageChannel && event.request.url.match(/api/)) {
    const requestId = Math.random()
    event.respondWith(new Promise((resolve, reject) => {
      pendingRequests[requestId] = { event, resolve, reject }
      messageChannel.postMessage({
        type: 'NEW_REQUEST',
        payload: {
          id: requestId,
          url: event.request.url,
        },
      })
    }))
  } else {
    event.respondWith(fetch(event.request))
  }
})

self.addEventListener('message', (event) => {
  //console.log('Message channel opened in worker')
  messageChannel = event.ports[0]
  event.ports[0].onmessage = (event) => {
    //console.log('message received in worker', event)
    if (!event.data.type) {
      return
    }

    const payload = event.data.payload

    switch (event.data.type) {
      case 'REQUEST_RESPONSE':
        const requestId = payload.requestId
        const request = pendingRequests[requestId]
        if (payload.passthrough) {
          request.resolve(fetch(request.event.request))
        } else {
          request.resolve(new Response(payload.body, payload.params))
        }
        break;
      default:
        // Ignore message
    }
  }
})
