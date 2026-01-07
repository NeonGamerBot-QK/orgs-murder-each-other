socket = io()
socket.on 'connect', ->
  console.log 'Connected to server'

socket.on 'game-code',(code) -> 
  console.log "code #{code}"
  document.querySelector('#game-code').innerText = code
  document.querySelector("#game-qr-code").src = "/game-qr?code=#{code}"


socket.emit "type", "server"
