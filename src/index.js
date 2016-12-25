// Init Elm app
const root = document.getElementById('root');
const ElmApp = Elm.Main.embed(root);

ElmApp.ports.requestResponse.subscribe((response) => {
 console.log('response from elm!', response)
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
      console.log('new pending request', payload)
      ElmApp.ports.newRequest.send('' + payload.id)
      break;
    default:
      // Ignore message
  }

}

function requestResponse(requestId, body, params) {
  sendMessage({
    type: 'REQUEST_RESPONSE',
    payload: { requestId, body, params },
  })
}

setTimeout(() => {
  // Perform a fetch
  fetch('/api/users').then((response) => {
    console.log('sucess!', response)
  }, (error) => {
    console.log('error...', error)
  })
}, 500)
