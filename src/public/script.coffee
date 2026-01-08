socket = io()

# Canvas setup
canvas = document.getElementById 'game-canvas'
ctx = canvas.getContext '2d'
canvas.width = 1200
canvas.height = 800

# Load player sprite
playerImage = new Image()
playerImage.src = '/random-image'

# Game state from server
players = []

# Active slash animations
slashAnimations = []

###
  Creates a slash animation between attacker and target.
  @param {number} ax - Attacker X position
  @param {number} ay - Attacker Y position
  @param {number} tx - Target X position
  @param {number} ty - Target Y position
###
createSlashAnimation = (ax, ay, tx, ty) ->
  slashAnimations.push {
    ax, ay, tx, ty
    progress: 0
    particles: []
  }

socket.on 'connect', ->
  console.log 'Connected to server'

socket.on 'game-code', (code) -> 
  console.log "code #{code}"
  gameUrl = "/game?code=#{code}"
  document.querySelector('#game-code').innerText = code
  document.querySelector("#game-qr-code").src = "/game-qr?code=#{code}"
  document.querySelector("#game-link").href = gameUrl

# Receive game state updates from server
socket.on 'game-state', (state) ->
  players = state.players

# Handle kill animation event
socket.on 'kill-animation', (data) ->
  createSlashAnimation data.attackerX, data.attackerY, data.targetX, data.targetY

###
  Renders slash animation with energy arc and spark particles.
  @param {Object} slash - The slash animation object
###
renderSlash = (slash) ->
  { ax, ay, tx, ty, progress, particles } = slash
  
  # Calculate slash line properties
  dx = tx - ax
  dy = ty - ay
  dist = Math.sqrt(dx * dx + dy * dy)
  angle = Math.atan2(dy, dx)
  
  # Draw main slash arc (energy slice effect)
  if progress < 0.4
    slashProgress = progress / 0.4
    ctx.save()
    ctx.translate tx, ty
    ctx.rotate angle + Math.PI
    
    # Outer glow
    ctx.strokeStyle = "rgba(255, 255, 255, #{0.8 - slashProgress * 0.8})"
    ctx.lineWidth = 8 - slashProgress * 6
    ctx.lineCap = 'round'
    ctx.beginPath()
    ctx.arc 0, 0, 40, -0.8 + slashProgress, 0.8 - slashProgress
    ctx.stroke()
    
    # Inner bright slash
    ctx.strokeStyle = "rgba(230, 230, 250, #{1 - slashProgress})"
    ctx.lineWidth = 4 - slashProgress * 3
    ctx.beginPath()
    ctx.arc 0, 0, 40, -0.6 + slashProgress * 0.5, 0.6 - slashProgress * 0.5
    ctx.stroke()
    
    ctx.restore()
  
  # Generate spark particles on first frames
  if progress < 0.1 and particles.length < 12
    for i in [0..3]
      speed = 2 + Math.random() * 4
      pAngle = angle + Math.PI + (Math.random() - 0.5) * 1.5
      particles.push {
        x: tx
        y: ty
        vx: Math.cos(pAngle) * speed
        vy: Math.sin(pAngle) * speed
        life: 1
        size: 2 + Math.random() * 3
      }
  
  # Update and render particles
  for particle in particles
    continue if particle.life <= 0
    particle.x += particle.vx
    particle.y += particle.vy
    particle.vx *= 0.95
    particle.vy *= 0.95
    particle.life -= 0.04
    
    ctx.save()
    ctx.globalAlpha = particle.life
    ctx.fillStyle = '#fff'
    ctx.beginPath()
    ctx.arc particle.x, particle.y, particle.size * particle.life, 0, Math.PI * 2
    ctx.fill()
    ctx.restore()
  
  # Draw impact flash at target
  if progress < 0.15
    flashAlpha = (0.15 - progress) / 0.15
    ctx.save()
    ctx.globalAlpha = flashAlpha * 0.6
    ctx.fillStyle = '#fff'
    ctx.beginPath()
    ctx.arc tx, ty, 50 - progress * 200, 0, Math.PI * 2
    ctx.fill()
    ctx.restore()

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

  # Render and update slash animations
  for slash in slashAnimations
    renderSlash slash
    slash.progress += 0.02
  
  # Remove completed animations
  slashAnimations = slashAnimations.filter (s) -> s.progress < 1

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
