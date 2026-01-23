// Singleton 

class logger {
    constructor(){
        if (logger.instance) {
            return logger.instance;
        }
        this.logs = []; 
        logger.instance = this;
    }

    get count(){
        return this.log.length  
    }

    log(message){
        const timeStamp = new Date().toString()
        const logMessage = `[${timeStamp}] ${message}`
        this.logs.push(logMessage)
        return logMessage
    }
    
    clone(){ // Prototype
        const proto = Object.getPrototypeOf(this)
        const clone = Object.create(proto)
        clone.logs = this.logs
    }
}

const instance = new logger();

module.exports = instance;

class notification {
    constructor(){
        if(message.instance) return message.instance
        this.message = ''
        this.type = 'default'
        message.instance = this
    }

    get getMessage(){
        return this.message
    }

    setMessage(message, type = 'default'){
        if(type != 'default') this.type = type
        this.message = message
        return true
    }
}

// Factory

const functionFactory = (message, type) =>{
    switch (type) {
        case 'log':
            const logInstance = new logger()
            logInstance.log(message) // writing logs
            return logInstance
        default:
            const notificationInstance = new notification()
            notificationInstance.setMessage(message,type) // writing notification messaage
            return notificationInstance
    }
}

// Builder

class NoteDocument {
    constructor (builder){
        this.content = builder.content || ""
        this.tags = builder.tags || ["note"]
        this.title = builder.title || ""
    }

    get instance(){
        return this
    }
}

class NoteBuilder {
    constructor(){

    }

    addTitle(title) {
        this.title = title
        return this
    }

    addTags(tags) {
        this.tags = tags
        return this
    }

    addContent(content){
        this.content = content
        return this
    }

    execute(){
        const newNoteInstance = new NoteDocument(this)
        console.log('comming to execute')
        console.log(newNoteInstance.instance)
        return newNoteInstance
    }
}

const testBuilder = new NoteBuilder()
                    .addTitle('New title')
                    .addTags(['note','test'])
                    .addContent('here is some content')
                    .execute()
