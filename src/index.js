require("dotenv").config();

const express = require("express");
const app = express();
const server = require("http").createServer(app);
const helmet = require("helmet");
const QRCode = require('qrcode')
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
app.use(express.static(__dirname + "/public"));
app.set("view engine", "ejs");
app.set("views", __dirname + "/views");
app.get("/", (req, res) => {
    res.render("index");
});
let serverr = "";
app.get('/game-qr', (req, res) => {
    const code = req.query.code.slice(0, 6)
    const url = `http://${process.env.BASE_URL || "localhost:3000"}/game?code=${code}`
    if (process.env.PRINT_QR_CODES) {
        console.debug(`qr for game #${code}`)
        QRCode.toString(url, function (e, qr) {
            console.debug(qr)
        })
    }
    QRCode.toBuffer(url, (e, c) => {
        res.set({ "Content-Type": "image/png" })
        res.end(c)
    })
})
io.on("connection", (socket) => {
    let type = null;
    console.log(`Meow`);
    socket.on('type', t => {
        type = t;
        switch (t) {
            case "server":

                break;
        }
    })

});
server.listen(process.env.PORT || 3000, () => {
    console.log("Server is running...");
});
