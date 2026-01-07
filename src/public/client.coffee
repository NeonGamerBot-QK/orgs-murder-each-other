# Socket.io connection
socket = io()

# DOM Elements
joinScreen = document.getElementById 'join-screen'
controllerScreen = document.getElementById 'controller-screen'
gameCodeInput = document.getElementById 'game-code-input'
joinBtn = document.getElementById 'join-btn'
errorMsg = document.getElementById 'error-msg'
joystickContainer = document.getElementById 'joystick-container'
joystickKnob = document.getElementById 'joystick-knob'
shootBtn = document.getElementById 'shoot-btn'

# Joystick state
joystickActive = false
joystickCenter = { x: 0, y: 0 }
maxDistance = 45

# Join game handler
joinGame = ->
  code = gameCodeInput.value.trim().toUpperCase()
  if code.length < 4
    errorMsg.textContent = 'Please enter a valid game code'
    return
  
  errorMsg.textContent = ''
  socket.emit 'type', 'client'
  socket.emit 'join-game', code

joinBtn.addEventListener 'click', joinGame
gameCodeInput.addEventListener 'keypress', (e) ->
  joinGame() if e.key is 'Enter'

# Socket events
socket.on 'join-success', ->
  joinScreen.classList.add 'hidden'
  controllerScreen.classList.add 'active'

socket.on 'join-error', (msg) ->
  errorMsg.textContent = msg

# Calculates joystick position and emits movement data
updateJoystick = (clientX, clientY) ->
  rect = joystickContainer.getBoundingClientRect()
  joystickCenter.x = rect.left + rect.width / 2
  joystickCenter.y = rect.top + rect.height / 2
  
  deltaX = clientX - joystickCenter.x
  deltaY = clientY - joystickCenter.y
  
  distance = Math.sqrt(deltaX * deltaX + deltaY * deltaY)
  
  # Clamp to max distance
  if distance > maxDistance
    deltaX = (deltaX / distance) * maxDistance
    deltaY = (deltaY / distance) * maxDistance
    distance = maxDistance
  
  # Update knob position
  joystickKnob.style.transform = "translate(#{deltaX}px, #{deltaY}px)"
  
  # Normalize values to -1 to 1 range
  normalizedX = deltaX / maxDistance
  normalizedY = deltaY / maxDistance
  
  socket.emit 'joystick', { x: normalizedX, y: normalizedY }

# Reset joystick to center
resetJoystick = ->
  joystickKnob.style.transform = 'translate(0px, 0px)'
  socket.emit 'joystick', { x: 0, y: 0 }

# Touch events for joystick
joystickContainer.addEventListener 'touchstart', (e) ->
  e.preventDefault()
  joystickActive = true
  touch = e.touches[0]
  updateJoystick touch.clientX, touch.clientY

joystickContainer.addEventListener 'touchmove', (e) ->
  e.preventDefault()
  return unless joystickActive
  touch = e.touches[0]
  updateJoystick touch.clientX, touch.clientY

joystickContainer.addEventListener 'touchend', (e) ->
  e.preventDefault()
  joystickActive = false
  resetJoystick()

# Mouse events for joystick (for desktop testing)
joystickContainer.addEventListener 'mousedown', (e) ->
  joystickActive = true
  updateJoystick e.clientX, e.clientY

document.addEventListener 'mousemove', (e) ->
  return unless joystickActive
  updateJoystick e.clientX, e.clientY

document.addEventListener 'mouseup', ->
  return unless joystickActive
  joystickActive = false
  resetJoystick()

# Shoot button events
shootBtn.addEventListener 'touchstart', (e) ->
  e.preventDefault()
  shootBtn.classList.add 'pressed'
  socket.emit 'shoot', true

shootBtn.addEventListener 'touchend', (e) ->
  e.preventDefault()
  shootBtn.classList.remove 'pressed'
  socket.emit 'shoot', false

shootBtn.addEventListener 'mousedown', ->
  shootBtn.classList.add 'pressed'
  socket.emit 'shoot', true

shootBtn.addEventListener 'mouseup', ->
  shootBtn.classList.remove 'pressed'
  socket.emit 'shoot', false
