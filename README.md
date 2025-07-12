# 🌌 Alderaan - AI Chat & Speech Platform

Welcome to **Alderaan**! 🚀  
A full-stack Spring Boot + Python project for AI chat, speech synthesis, and speech recognition.

## Features ✨

- 🤖 AI-powered chat (text & voice)
- 🗣️ Speech-to-text (STT) and text-to-speech (TTS) using Python (Flask, TTS, Whisper)
- 🔒 JWT-based authentication
- 🗃️ PostgreSQL database for chat history
- 🧑‍💻 REST API for easy integration

## Getting Started 🏁

### Prerequisites

- Java 21+
- Python 3.11
- Maven
- PostgreSQL

### Backend Setup

1. **Clone the repo**  
   `git clone <your-repo-url> && cd Alderaan`

2. **Configure database**  
   Edit `src/main/resources/application.properties` with your DB credentials.

3. **Start the backend**  
   `./mvnw spring-boot:run`

### Speech Service (Python) 🐍

1. `cd Speech`
2. (Recommended) Create a virtual environment:  
   `python -m venv .venv && source .venv/bin/activate`
3. Install dependencies:  
   `pip install -r requirements.txt`
4. Run the Flask app:  
   `python app.py`

### Testing 🧪

Run the test script:  
`bash test.sh`

## API Endpoints 📚

- `/api/auth/*` - Authentication (register, login, validate)
- `/api/chat/*` - Chat sessions & messages
- `/api/ai/chat` - AI chat (text)
- `/api/ai/chat/speech` - AI chat (speech)
- `/api/ai/chat/voice` - Voice-to-voice chat
- `/api/speech/synthesize` - Text-to-speech
- `/api/speech/recognize` - Speech-to-text

## License 📄

MIT

---

Made with ❤️ by Uday