socket = io()

# Canvas setup
canvas = document.getElementById 'game-canvas'
ctx = canvas.getContext '2d'
canvas.width = 1200
canvas.height = 800

# Load player sprite
playerImage = new Image()
playerImage.src = 'https://saahild.com/oneko.gif'

# Game state from server
players = []

socket.on 'connect', ->
  console.log 'Connected to server'

socket.on 'game-code', (code) -> 
  console.log "code #{code}"
  document.querySelector('#game-code').innerText = code
  document.querySelector("#game-qr-code").src = "/game-qr?code=#{code}"

# Receive game state updates from server
socket.on 'game-state', (state) ->
  players = state.players

###
  Renders all players on the canvas.
  Alive players shown with sprite, dead players shown as faded.
###
render = ->
  # Clear canvas
  ctx.fillStyle = '#0f0f23'
  ctx.fillRect 0, 0, canvas.width, canvas.height

  for player in players
    ctx.save()
    ctx.translate player.x, player.y

    if player.alive
      # Draw player sprite centered
      ctx.drawImage playerImage, -25, -25, 50, 50
    else
      # Draw dead player as faded circle
      ctx.globalAlpha = 0.3
      ctx.beginPath()
      ctx.arc 0, 0, 25, 0, Math.PI * 2
      ctx.fillStyle = '#666'
      ctx.fill()

    ctx.restore()

  requestAnimationFrame render

# Start render loop once image loads
playerImage.onload = ->
  render()

# Fallback: start render even if image fails
playerImage.onerror = ->
  console.warn 'Failed to load player image, using fallback'
  render()

# Start render loop after short delay as backup
setTimeout (-> render() unless players.length), 1000

socket.emit "type", "server"
