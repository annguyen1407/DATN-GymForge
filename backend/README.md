# GymForge Backend API

A comprehensive gym management system backend built with NestJS, Prisma, and PostgreSQL.

## 🚀 Features

- **User Management**: Support for multiple user roles (Admin, Coach, Gymer)
- **Authentication & Authorization**: JWT-based authentication with role-based access control
- **Workout Management**: Create and manage workout plans and exercises
- **Appointment System**: Schedule and manage training appointments
- **Training Requests**: Handle training requests between coaches and gymers
- **Feedback System**: Rating and feedback system for coaches
- **Equipment Management**: Manage gym equipment inventory
- **Muscle Groups**: Exercise categorization by muscle groups
- **Real-time Communication**: Message system between coaches and gymers
- **Payment Processing**: Handle gym membership and service payments
- **Progress Tracking**: Log workouts and track fitness progress

## 🛠️ Tech Stack

- **Framework**: NestJS (Node.js)
- **Database**: PostgreSQL with Prisma ORM
- **Authentication**: JWT with Passport.js + OAuth (Google)
- **Email Service**: Nodemailer with Handlebars templates
- **Validation**: class-validator & class-transformer
- **API Documentation**: Swagger/OpenAPI
- **Testing**: Jest
- **Code Quality**: ESLint + Prettier

## 📋 Prerequisites

- Node.js (v18 or higher)
- PostgreSQL database
- npm or yarn package manager

## 🔧 Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Environment Setup**
   Create a `.env` file in the root directory:
   ```env
   # Database
   DATABASE_URL="postgresql://username:password@localhost:5432/gymforge_db"

   # JWT
   JWT_SECRET="your-jwt-secret-key"
   JWT_EXPIRES_IN="24h"

   # Application
   PORT=3000
   NODE_ENV=development
   CORS_ORIGIN="http://localhost:3000"
   FRONTEND_URL="http://localhost:3000"

   # Email Configuration (SMTP)
   MAIL_HOST="smtp.gmail.com"
   MAIL_PORT=587
   MAIL_SECURE=false
   MAIL_USER="your-email@gmail.com"
   MAIL_PASS="your-app-password"
   MAIL_FROM_NAME="GymForge"
   MAIL_FROM_ADDRESS="noreply@gymforge.com"
   SUPPORT_EMAIL="support@gymforge.com"

   # Google OAuth
   GOOGLE_CLIENT_ID="your-google-client-id"
   GOOGLE_CLIENT_SECRET="your-google-client-secret"
   GOOGLE_CALLBACK_URL="http://localhost:3000/auth/google/callback"
   ```

4. **Database Setup**
   ```bash
   # Generate Prisma client
   npx prisma generate
   
   # Run database migrations
   npx prisma migrate dev
   
   # (Optional) Seed the database
   npx prisma db seed
   ```

## 🚀 Running the Application

### Development Mode
```bash
npm run start:dev
```

### Production Mode
```bash
npm run build
npm run start:prod
```

### Debug Mode
```bash
npm run start:debug
```

## 📚 API Documentation

Once the application is running, you can access:

- **API Documentation**: http://localhost:3000/api
- **Application**: http://localhost:3000

The Swagger UI provides interactive documentation for all available endpoints.

## 📄 License

This project is licensed under the UNLICENSED License.

## 🆘 Support

For support and questions, please contact the development team or create an issue in the repository.
