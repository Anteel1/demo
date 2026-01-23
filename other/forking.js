const http = require("http")
const port = parseInt(process.argv[2] || 4000)

const response = [
    "Hello, how can i help u !",
    "Hi, how are u today !",
    "Hi, i got some technical issue !",
    "Just say hi !"
]


const server = http.createServer((req,res) => {
    const randomIndex = Math.floor(Math.random() * response.length)
    const payload = JSON.stringify({
        port,
        processID : process.pid,
        response : response[randomIndex]
    })
    res.end(payload)
})

server.listen(port)