# Exercise Logging Module

This module provides comprehensive exercise logging and statistics functionality for the GymForge application. It tracks exercise performance, workout plan progress, and provides detailed analytics for gymers and coaches.

## Features

### 📊 Exercise Logging
- **Detailed Exercise Logs**: Log exercises with sets, reps, weight, and duration
- **Quick Logging**: Simplified logging interface for rapid exercise entry
- **Workout Plan Integration**: Link exercise logs to specific workout plans and days
- **Calorie Tracking**: Automatic calorie calculation based on exercise MET values

### 📈 Statistics & Analytics
- **Daily Statistics**: Complete breakdown of daily exercise performance
- **Weekly Statistics**: Weekly summaries with daily breakdowns
- **Monthly Statistics**: Monthly overviews with weekly trends
- **Exercise Performance**: Individual exercise progress tracking
- **Workout Streaks**: Current and longest workout streaks

### 🎯 Workout Plan Progress
- **Plan Progress Tracking**: Monitor completion percentage of workout plans
- **Day-by-Day Progress**: Track which days have been completed
- **Multiple Plan Support**: Handle progress for multiple active plans

## API Endpoints

### Exercise Logging
- `POST /exercise-logs` - Create detailed exercise log
- `POST /exercise-logs/quick-log` - Quick log exercise with sets
- `GET /exercise-logs/my-logs` - Get current user's exercise logs
- `GET /exercise-logs/user/:userId` - Get exercise logs for specific user
- `PATCH /exercise-logs/:id` - Update exercise log
- `DELETE /exercise-logs/:id` - Delete exercise log

### Statistics
- `GET /exercise-logs/stats/daily/my/:date` - Daily stats for current user
- `GET /exercise-logs/stats/weekly/my/:weekStart` - Weekly stats for current user
- `GET /exercise-logs/stats/monthly/my/:month` - Monthly stats for current user
- `GET /exercise-logs/stats/daily/:userId/:date` - Daily stats for specific user
- `GET /exercise-logs/stats/weekly/:userId/:weekStart` - Weekly stats for specific user
- `GET /exercise-logs/stats/monthly/:userId/:month` - Monthly stats for specific user

### Progress Tracking
- `GET /exercise-logs/workout-plan-progress/my/:workoutPlanId` - Current user's plan progress
- `GET /exercise-logs/workout-plans-progress/my` - All plans progress for current user
- `GET /exercise-logs/performance/my` - Exercise performance analytics for current user
- `GET /exercise-logs/streaks/my` - Workout streaks for current user

### Exercise Integration
- `GET /exercises/:id/performance/my` - Performance for specific exercise (current user)
- `GET /exercises/:id/performance/:userId` - Performance for specific exercise (specific user)

## Usage Examples

### Quick Log an Exercise
```typescript
POST /exercise-logs/quick-log
{
  "exerciseId": "uuid-here",
  "workoutPlanId": "plan-uuid", // optional
  "dayNumber": 1, // optional
  "sets": [
    { "reps": 12, "weight": 50.5 },
    { "reps": 10, "weight": 52.5 },
    { "reps": 8, "weight": 55.0 }
  ],
  "notes": "Felt strong today!"
}
```

### Get Daily Statistics
```typescript
GET /exercise-logs/stats/daily/my/2024-01-15
Response:
{
  "date": "2024-01-15",
  "totalExercises": 5,
  "totalSets": 15,
  "totalReps": 150,
  "totalCaloriesBurned": 450.5,
  "totalWorkoutTime": 90,
  "averageWeight": 45.5,
  "workoutPlansCompleted": ["Beginner Strength", "Core Workout"]
}
```

### Get Workout Plan Progress
```typescript
GET /exercise-logs/workout-plan-progress/my/plan-uuid
Response:
{
  "workoutPlanId": "plan-uuid",
  "planName": "Beginner Strength Training",
  "overallProgress": 75.5,
  "totalDays": 30,
  "daysCompleted": 22,
  "currentDay": 23,
  "startDate": "2024-01-01",
  "expectedCompletionDate": "2024-01-30",
  "dailyProgress": [...]
}
```

## Database Models Used

The module leverages existing Prisma models:
- **Log**: Main daily log entry
- **WorkoutExerciseLog**: Links exercises to workout plans
- **ExerciseLog**: Individual exercise session
- **SetsLog**: Individual set data (reps, weight, etc.)

## Security

All endpoints are protected with JWT authentication and role-based access control:
- **GYMER**: Can log and view their own exercise data
- **COACH**: Can log and view their own data + view client data
- **ADMIN**: Full access to all exercise logs and statistics

## Integration Points

This module integrates with:
- **Exercises Module**: Exercise library and performance tracking
- **Workout Plans Module**: Plan progress tracking
- **User Module**: User-specific logging and statistics
- **Auth Module**: Authentication and authorization
