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
const clients = []
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
        if (serverrr) {
            serverrr.people++;
            if (serverrr.gameCode == code) {
                socket.emit('join-success')
            } else {
                socket.emit('join-error', "Bad code")
            }
        } else {
            socket.emit("join-error", "So uh there is no game")
        }

        // TODO: validate code matches serverrr.gameCode
        // TODO: add socket to clients array
        // TODO: emit 'join-success' or 'join-error'
    });

    // Client joystick movement
    socket.on('joystick', (data) => {
        // data: { x: -1 to 1, y: -1 to 1 }
        // TODO: forward to server display or update player state
    });

    // Client shoot button
    socket.on('shoot', (isPressed) => {
        // isPressed: true when pressed, false when released
        // TODO: handle shooting logic
    });

    socket.on('disconnect', () => {
        if (type == "server") {
            serverrr = null;
        } else {
            clients
        }
    })
});
server.listen(process.env.PORT || 3000, () => {
    console.log("Server is running...");
});
