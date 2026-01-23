const { fork } = require('child_process')

const processes = [
    fork('./forking.js',[3002]),
    fork('./forking.js',[3003]),
    fork('./forking.js',[3004])
] 