// Init Elm app
const root = document.getElementById('root');
const ElmApp = Elm.Main.embed(root);

// When a response is sent by Elm app, forward it to service worker
ElmApp.ports.requestResponse.subscribe((response) => {
 requestResponse(response.requestId, response.passthrough, response.body)
});


// Install service worker
window.addEventListener('load', () => {
  navigator.serviceWorker.register('/serviceWorker.js').then((registration) => {
    // Registration was successful
    onReady()
  }).catch((err) => {
    // registration failed :(
    console.log('ServiceWorker registration failed: ', err)
  })
})

/**
 * Communication channel between page and service worker
 * cf: http://stackoverflow.com/questions/30177782/chrome-serviceworker-postmessage
 */
let workerChannel

function onReady() {
  // Create a message channel to communicate with the worker
  workerChannel = new MessageChannel()
  workerChannel.port1.onmessage = (event) => {
    onWorkerMessage(event)
  }

  // Send a message to the worker so it can uses the channel
  navigator.serviceWorker.controller.postMessage({
    type: 'OPEN_CHANNEL',
  }, [workerChannel.port2])
}

/**
 * Send a message to the service worker
 */
function sendMessage(message) {
  workerChannel.port1.postMessage(message)
}

function onWorkerMessage(event) {
  //console.log('message from worker:', event)
  if (!event.data.type) {
    return
  }

  const payload = event.data.payload

  switch (event.data.type) {
    case 'NEW_REQUEST':
      // When a request is intercepted, forward it to the Elm app
      ElmApp.ports.newRequest.send(payload)
      break;
    default:
      // Ignore message
  }
}

/**
 * Send a request response to the service worker
 * @param requestId Id of request to respond to
 * @param passthrough If true, worker will just let the request pass through
 * (i.e perform the actual request)
 * @param {string} body Response body
 * @param {object} params Init params that should be given to fetch Response() constructor
 */
function requestResponse(requestId, passthrough, body, params) {
  sendMessage({
    type: 'REQUEST_RESPONSE',
    payload: { requestId, passthrough, body, params },
  })
}

/**
 * Just a simple demo feature that triggers an HTTP request
 */
function fetchRequest() {
  // Perform a fetch
  fetch('/api/users/'+Math.random()).then((response) => {
    console.log('fetch sucess!', response)
  }, (error) => {
    console.log('fetch error...', error)
  })
}
