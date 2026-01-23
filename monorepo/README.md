
# NestJS Microservices Monorepo

A comprehensive NestJS-based microservices architecture featuring an API Gateway, Note Management, Resource Management, and Real-time WebSocket communication.

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Installation](#installation)
- [Running the Application](#running-the-application)
- [Services Documentation](#services-documentation)
  - [API Gateway](#1-api-gateway-port-3000)
  - [Note Module](#2-note-module-microservice-port-3001)
  - [Resource Module](#3-resource-module-microservice-port-3002)
  - [WebSocket Gateway](#4-websocket-gateway-port-3005)
- [API Endpoints](#api-endpoints)
- [WebSocket Events](#websocket-events)
- [Response Format](#response-format)
- [Shared Libraries](#shared-libraries)
- [Development](#development)

## 🏗️ Architecture Overview

This project implements a microservices architecture using NestJS with the following components:

```
┌─────────────────────────────────────────────────────────┐
│                    Client Applications                   │
│              (HTTP/WebSocket Connections)                │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│              API Gateway (Port 3000)                     │
│  • HTTP REST Endpoints                                   │
│  • Static File Serving                                   │
│  • CORS Enabled                                          │
│  • Global Logging & Error Handling                       │
└─────────────────────────────────────────────────────────┘
           │                              │
           │ TCP                          │ TCP
           ▼                              ▼
┌──────────────────────┐      ┌──────────────────────┐
│  Note Module         │      │  Resource Module     │
│  (Port 3001)         │      │  (Port 3002)         │
│  • Note Management   │      │  • File Uploads      │
│  • File-based Storage│      │  • Image/Text Files  │
│  • WebSocket Events  │      │  • UUID Generation   │
└──────────────────────┘      └──────────────────────┘
           │
           │
           ▼
┌──────────────────────┐
│  WebSocket Gateway   │
│  (Port 3005)         │
│  • Real-time Events  │
│  • User Notifications│
└──────────────────────┘
```

## 🛠️ Technology Stack

- **Framework**: NestJS 11.x
- **Runtime**: Node.js
- **Language**: TypeScript
- **Microservices**: TCP Transport
- **WebSockets**: Socket.IO
- **File Upload**: Multer
- **Static Files**: @nestjs/serve-static
- **Package Manager**: npm

## 📁 Project Structure

```
monorepo/
├── apps/
│   ├── api-gateway/          # Main HTTP gateway
│   │   └── src/
│   │       ├── main.ts
│   │       ├── api-gateway.module.ts
│   │       └── api-gateway.controller.ts
│   │
│   ├── note-module/          # Note management microservice
│   │   └── src/
│   │       ├── main.ts
│   │       ├── note-module.module.ts
│   │       ├── note-module.controller.ts
│   │       ├── note-module.service.ts
│   │       └── event.gateway.ts
│   │
│   └── resource-module/      # File management microservice
│       └── src/
│           ├── main.ts
│           ├── resource-module.module.ts
│           ├── resource-module.controller.ts
│           └── resource-module.service.ts
│
├── lib/                      # Shared libraries
│   ├── dto/
│   │   └── base.dto.ts      # Standard response DTOs
│   ├── logger.interceptor.ts
│   ├── error.filter.ts
│   └── block.middleware.ts
│
├── files/                    # File storage directory
├── package.json
└── nest-cli.json
```

## 📦 Installation

```bash
# Clone the repository
git clone <repository-url>
cd monorepo

# Install dependencies
npm install
```

## 🚀 Running the Application

### Start All Services in Development Mode

```bash
# Start API Gateway (Port 3000)
npm run start:dev api-gateway

# Start Note Module (Port 3001)
npm run start:dev note-module

# Start Resource Module (Port 3002)
npm run start:dev resource-module
```

### Production Mode

```bash
# Build all services
npm run build

# Start in production mode
npm run start:prod
```

### Individual Service Commands

```bash
# Start specific service
nest start <service-name> --watch

# Examples:
nest start api-gateway --watch
nest start note-module --watch
nest start resource-module --watch
```

## 📚 Services Documentation

### 1. API Gateway (Port 3000)

The main entry point for all client requests. Routes requests to appropriate microservices via TCP.

**Features:**
- ✅ HTTP REST API endpoints
- ✅ Static file serving from `/files` directory
- ✅ CORS enabled for all origins
- ✅ Global request logging
- ✅ Standardized error handling
- ✅ TCP clients for Note and Resource services

**Configuration:**
```typescript
// TCP Clients
NOTE_SERVICE: { host: '127.0.0.1', port: 3001 }
RESOURCE_SERVICE: { host: '127.0.0.1', port: 3002 }
```

### 2. Note Module (Microservice - Port 3001)

Manages notes with file-based JSON storage and real-time WebSocket notifications.

**Features:**
- ✅ Create/Update notes
- ✅ Retrieve all notes
- ✅ Retrieve note by ID
- ✅ File-based persistence (JSON files)
- ✅ WebSocket integration for real-time updates

**Message Patterns:**

| Pattern | Description | Input | Output |
|---------|-------------|-------|--------|
| `insert_note` | Create or update a note | `{title, tag, content, id}` | `{message, path}` |
| `get_notes` | Get all notes | `{}` | `Array<Note>` |
| `get_note_by_title` | Get note by ID | `{id}` | `Note` object |

**Note Data Structure:**
```typescript
{
  id: string,           // UUID
  title: string,        // Note title
  tag: string,          // Category tag (default: 'note')
  content: string,      // Note content
  updatedAt: string     // ISO timestamp
}
```

**Storage:**
- Notes stored as JSON files in `./files/{id}.json`
- Special characters in titles replaced with `-`
- Auto-generated UUID if ID not provided

### 3. Resource Module (Microservice - Port 3002)

Handles file uploads and retrieval for images and text files.

**Features:**
- ✅ File upload with multipart/form-data
- ✅ Support for PNG images and text files
- ✅ UUID-based unique filenames
- ✅ File retrieval by path

**Message Patterns:**

| Pattern | Description | Input | Output |
|---------|-------------|-------|--------|
| `upload_file` | Upload a file | `{file}` | `{url}` |
| `get_file` | Retrieve a file | `{filePath}` | File buffer |

**Supported File Types:**
- Images: `.png`
- Text: `.text`

**File Naming:**
```
{timestamp}-{uuid}.{extension}
Example: 1705152000000-a1b2c3d4-e5f6-7890-abcd-ef1234567890.png
```

**Returned URL Format:**
```
http://127.0.0.1:3000/{filename}
```

### 4. WebSocket Gateway (Port 3005)

Real-time bidirectional communication for live updates and notifications.

**Features:**
- ✅ Client connection/disconnection tracking
- ✅ Broadcast user join/leave events
- ✅ Event relay between clients
- ✅ CORS enabled

**Connection:**
```javascript
const socket = io('http://localhost:3005');
```

## 🔌 API Endpoints

### POST `/note`

Create, update, or retrieve notes.

**Query Parameters:**
- `note` (optional): Note title
- `id` (optional): Note ID

**Body Parameters:**
- `content` (optional): Note content

**Examples:**

```bash
# Get all notes
curl -X POST http://localhost:3000/note

# Get note by ID
curl -X POST "http://localhost:3000/note?id=123e4567-e89b-12d3-a456-426614174000"

# Create new note
curl -X POST "http://localhost:3000/note?note=My%20First%20Note" \
  -H "Content-Type: application/json" \
  -d '{"content": "This is my note content"}'

# Update existing note
curl -X POST "http://localhost:3000/note?note=My%20First%20Note&id=123e4567-e89b-12d3-a456-426614174000" \
  -H "Content-Type: application/json" \
  -d '{"content": "Updated content"}'
```

**Response:**
```json
{
  "statusCode": 200,
  "success": true,
  "data": {
    "message": "Đã lưu file: 123e4567-e89b-12d3-a456-426614174000.json",
    "path": "./files/123e4567-e89b-12d3-a456-426614174000.json"
  }
}
```

### POST `/upload`

Upload a file (image or text).

**Form Data:**
- `file`: File to upload (multipart/form-data)

**Examples:**

```bash
# Upload image
curl -X POST http://localhost:3000/upload \
  -F "file=@image.png"

# Upload text file
curl -X POST http://localhost:3000/upload \
  -F "file=@document.txt"
```

**Response:**
```json
{
  "statusCode": 200,
  "success": true,
  "data": {
    "url": "http://127.0.0.1:3000/1705152000000-a1b2c3d4-e5f6-7890-abcd-ef1234567890.png"
  }
}
```

### GET `/files/{filename}`

Retrieve uploaded files (served statically).

**Example:**
```bash
curl http://localhost:3000/1705152000000-a1b2c3d4-e5f6-7890-abcd-ef1234567890.png
```

## 🔄 WebSocket Events

### Client → Server

**`event`** - Send message to all connected clients
```javascript
socket.emit('event', {
  type: 'message',
  payload: 'Hello, everyone!'
});
```

### Server → Client

**`user-joined`** - Broadcast when a user connects
```javascript
socket.on('user-joined', (data) => {
  console.log(data.message);  // "User joined the chat: {clientId}"
  console.log(data.clientId);
});
```

**`user-left`** - Broadcast when a user disconnects
```javascript
socket.on('user-left', (data) => {
  console.log(data.message);  // "User left the chat: {clientId}"
  console.log(data.clientId);
});
```

**`event`** - Receive messages from other clients
```javascript
socket.on('event', (message) => {
  console.log('Received:', message);
});
```

### Complete WebSocket Example

```javascript
import io from 'socket.io-client';

const socket = io('http://localhost:3005');

// Listen for connection
socket.on('connect', () => {
  console.log('Connected:', socket.id);
});

// Listen for user events
socket.on('user-joined', (data) => {
  console.log(data.message);
});

socket.on('user-left', (data) => {
  console.log(data.message);
});

// Listen for messages
socket.on('event', (message) => {
  console.log('Message:', message);
});

// Send message
socket.emit('event', {
  type: 'chat',
  message: 'Hello, World!'
});
```

## 📄 Response Format

All API responses follow a standardized format using `baseResponse` DTO.

### Success Response

```typescript
{
  statusCode: 200,
  success: true,
  data: any  // Response payload
}
```

**Example:**
```json
{
  "statusCode": 200,
  "success": true,
  "data": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "title": "My Note",
    "tag": "note",
    "content": "Note content",
    "updatedAt": "2026-01-13T10:30:00.000Z"
  }
}
```

### Error Response

```typescript
{
  statusCode: number,  // HTTP status code
  success: false,
  error: {
    code: number | string,
    message: string
  }
}
```

**Example:**
```json
{
  "statusCode": 404,
  "success": false,
  "error": {
    "code": 404,
    "message": "Note not found"
  }
}
```

## 🔧 Shared Libraries

### LoggingIncomingInterceptor

Global interceptor that logs all incoming requests and standardizes responses.

**Logged Information:**
- Timestamp
- Request URL
- Query parameters
- Route parameters
- Request body

**Example Log:**
```
[2026-01-13T10:30:00.000Z] {
  url: '/note',
  query: { note: 'My Note', id: '123' },
  param: null,
  body: { content: 'Note content' }
}
```

### ErrorExceptionFilter

Global exception filter that catches all errors and returns standardized error responses.

**Features:**
- Catches both HTTP and unexpected exceptions
- Returns consistent error format
- Preserves HTTP status codes
- Extracts error messages

### BlockMiddleware

Middleware for request validation (currently commented out).

**Purpose:**
- Query parameter validation
- Request filtering
- Custom validation logic

### Base DTO Types

```typescript
type ApiError = {
  code: string | number,
  message: string
}

type baseResponse = {
  statusCode: number,
  success: boolean,
  data?: unknown,
  error?: ApiError
}
```

## 💻 Development

### Project Scripts

```bash
# Format code
npm run format

# Lint code
npm run lint

# Run tests
npm run test

# Run tests in watch mode
npm run test:watch

# Generate test coverage
npm run test:cov

# Run e2e tests
npm run test:e2e

# Debug mode
npm run start:debug
```

### Adding a New Microservice

1. Generate new application:
```bash
nest generate app <service-name>
```

2. Update `nest-cli.json` with service configuration

3. Register TCP client in API Gateway (if needed)

4. Implement message patterns in controller

### File Storage

All uploaded files and note JSON files are stored in `./files` directory:

```
files/
├── {uuid}.json                    # Note files
├── {timestamp}-{uuid}.png         # Image files
└── {timestamp}-{uuid}.text        # Text files
```

**Important:** Ensure `./files` directory exists before running the application.

## 🔐 Environment Variables

```bash
# API Gateway
PORT=3000

# Note Module
NOTE_SERVICE_HOST=127.0.0.1
NOTE_SERVICE_PORT=3001

# Resource Module
RESOURCE_SERVICE_HOST=127.0.0.1
RESOURCE_SERVICE_PORT=3002

# WebSocket Gateway
WEBSOCKET_PORT=3005
```

## 📝 Notes

- All services must be running for full functionality
- Static files are served from API Gateway (port 3000)
- Note IDs are auto-generated UUIDs if not provided
- File uploads are stored with unique timestamped filenames
- WebSocket connections automatically broadcast join/leave events

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is [UNLICENSED](LICENSE).

## 👥 Authors

- Development Team

## 🆘 Support

For questions and support, please open an issue in the repository.

---

**Built with ❤️ using NestJS**
