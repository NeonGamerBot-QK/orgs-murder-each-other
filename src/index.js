require("dotenv").config();

const express = require("express");
const app = express();
const server = require("http").createServer(app);
const helmet = require("helmet");
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

io.on("connection", (socket) => {
  console.log(`Meow`);
});
server.listen(process.env.PORT || 3000, () => {
  console.log("Server is running...");
});
