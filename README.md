# 📋 Task Manager

A full-stack task management application with **Flutter** frontend, **NestJS** backend, **MongoDB** database, and **Docker** containerization.

## 🏗️ Architecture

```
task_manager/
├── backend/          # NestJS API Server
├── frontend/         # Flutter Application
├── docker-compose.yml
└── mongo-init.js
```

## 🚀 Getting Started

### Prerequisites
- Docker & Docker Compose
- Flutter SDK (>=3.0)
- Node.js (>=18)

### 1. Start Backend (Docker)

```bash
# Start MongoDB + Backend
docker-compose up -d

# Or for development (MongoDB only)
docker-compose up -d mongodb
cd backend
npm run start:dev
```

### 2. Run Flutter App

```bash
cd frontend
flutter pub get
flutter run
```

## 🔗 API Documentation

Swagger docs available at: `http://localhost:3000/api/docs`

## 📱 Features

- ✅ User Authentication (JWT)
- ✅ Project Management (CRUD)
- ✅ Task Management (CRUD, Status, Priority)
- ✅ Dashboard Statistics
- ✅ Comments System
- ✅ Dark Theme UI
- ✅ Responsive Design

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter + Riverpod |
| Backend | NestJS + TypeScript |
| Database | MongoDB + Mongoose |
| Auth | JWT (Access + Refresh) |
| Container | Docker + Docker Compose |
| API Docs | Swagger |
