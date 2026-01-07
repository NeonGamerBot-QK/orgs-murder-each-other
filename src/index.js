require("dotenv").config();

const express = require("express");
const app = express();
const server = require("http").createServer(app);
const helmet = require("helmet");
const QRCode = require("qrcode");
const SOCKETIO = require("socket.io").Server;
const io = new SOCKETIO(server);
app.use(
    helmet({
        // i hate csp sm
        contentSecurityPolicy: false,
        crossOriginResourcePolicy: {
            origin: "*",
        },
    }),
);
const clients = new Map(); // Map<socketId, { socket, x, y, velocity: {x, y}, alive }>
const PLAYER_SPEED = 5;
const KILL_RADIUS = 100;
const CANVAS_WIDTH = 1200;
const CANVAS_HEIGHT = 800;

/**
 * Generates a random spawn position within the canvas bounds.
 * @returns {{ x: number, y: number }} The spawn coordinates.
 */
function getRandomSpawn() {
    return {
        x: Math.random() * (CANVAS_WIDTH - 100) + 50,
        y: Math.random() * (CANVAS_HEIGHT - 100) + 50
    };
}

/**
 * Finds the nearest alive player within kill radius.
 * @param {string} attackerId - The socket ID of the attacking player.
 * @returns {string|null} The socket ID of the nearest target, or null if none in range.
 */
function findNearestTarget(attackerId) {
    const attacker = clients.get(attackerId);
    if (!attacker || !attacker.alive) return null;

    let nearestId = null;
    let nearestDist = KILL_RADIUS;

    for (const [id, player] of clients) {
        if (id === attackerId || !player.alive) continue;
        const dx = player.x - attacker.x;
        const dy = player.y - attacker.y;
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist < nearestDist) {
            nearestDist = dist;
            nearestId = id;
        }
    }
    return nearestId;
}

/**
 * Sends the current game state to the server display.
 */
function broadcastGameState() {
    if (!serverrr) return;
    const players = [];
    for (const [id, player] of clients) {
        players.push({
            id,
            x: player.x,
            y: player.y,
            alive: player.alive
        });
    }
    serverrr.emit('game-state', { players });
}

// Game loop: updates player positions and broadcasts state
setInterval(() => {
    for (const [id, player] of clients) {
        if (!player.alive) continue;
        player.x += player.velocity.x * PLAYER_SPEED;
        player.y += player.velocity.y * PLAYER_SPEED;
        // Clamp to canvas bounds
        player.x = Math.max(25, Math.min(CANVAS_WIDTH - 25, player.x));
        player.y = Math.max(25, Math.min(CANVAS_HEIGHT - 25, player.y));
    }
    broadcastGameState();
}, 1000 / 60); // 60 FPS
app.use(express.static(__dirname + "/public"));
app.set("view engine", "ejs");
app.set("views", __dirname + "/views");
app.get("/", (req, res) => {
    res.render("index");
});
app.get('/game', (req, res) => {
    res.render('client')
})
let serverrr = "";
app.get("/game-qr", (req, res) => {
    const code = req.query.code.slice(0, 6);
    const url = `http://${process.env.BASE_URL || "localhost:3000"}/game?code=${code}`;
    if (process.env.PRINT_QR_CODES) {
        console.debug(`qr for game #${code}`);
        QRCode.toString(url, function (e, qr) {
            console.debug(qr);
        });
    }
    QRCode.toBuffer(url, (e, c) => {
        res.set({ "Content-Type": "image/png" });
        res.end(c);
    });
});
// let server = null;

io.on("connection", (socket) => {
    let type = null;
    console.log(`Meow`);
    socket.on("type", (t) => {
        type = t;
        if (process.env.DEBUG_SHI) {
            console.debug(t, '#t')
        }
        switch (t) {
            case "server":
                serverrr = socket;
                serverrr.gameCode = Math.random().toFixed(20).toString().split('.')[1].slice(0, 6)
                socket.emit('game-code', serverrr.gameCode)
                break;
        }
    });

    // Client joins game with code
    socket.on('join-game', (code) => {
        if (type !== "client") return;
        if (!serverrr) {
            socket.emit("join-error", "No game is running");
            return;
        }
        if (serverrr.gameCode !== code) {
            socket.emit('join-error', "Invalid game code");
            return;
        }
        // Add player to clients map with random spawn
        const spawn = getRandomSpawn();
        clients.set(socket.id, {
            socket,
            x: spawn.x,
            y: spawn.y,
            velocity: { x: 0, y: 0 },
            alive: true
        });
        socket.emit('join-success');
    });

    // Client joystick movement
    socket.on('joystick', (data) => {
        const player = clients.get(socket.id);
        if (!player || !player.alive) return;
        player.velocity.x = data.x || 0;
        player.velocity.y = data.y || 0;
    });

    // Client shoot button
    socket.on('shoot', (isPressed) => {
        if (!isPressed) return;
        const attacker = clients.get(socket.id);
        if (!attacker || !attacker.alive) return;

        const targetId = findNearestTarget(socket.id);
        if (targetId) {
            const target = clients.get(targetId);
            if (target) {
                target.alive = false;
                target.socket.emit('you-died');
                // Emit kill animation to server display
                if (serverrr) {
                    serverrr.emit('kill-animation', {
                        attackerX: attacker.x,
                        attackerY: attacker.y,
                        targetX: target.x,
                        targetY: target.y
                    });
                }
            }
        }
    });

    socket.on('disconnect', () => {
        if (type === "server") {
            serverrr = null;
        } else {
            clients.delete(socket.id);
        }
    })
});
server.listen(process.env.PORT || 3000, () => {
    console.log("Server is running...");
});
