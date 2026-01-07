socket = io()
socket.emit "type", "server"
socket.on 'connect', ->
  console.log 'Connected to server'

