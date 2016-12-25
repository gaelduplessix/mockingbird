console.log('Worker launched!')

const pendingRequests = {}
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
  console.log('Message channel opened in worker')
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
        pendingRequests[requestId].resolve(new Response(payload.body, payload.params))
        break;
      default:
        // Ignore message
    }
  }
})
