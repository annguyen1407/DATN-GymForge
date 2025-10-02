import { ApiProperty } from '@nestjs/swagger';
import { UserRole, Gender, FitnessGoal } from '@prisma/client';

enum AvailableTimeDto {
  MORNING = 'MORNING',
  AFTERNOON = 'AFTERNOON',
  EVENING = 'EVENING',
}

export class UserProfileDto {
  @ApiProperty({ 
    description: 'User unique identifier',
    example: '123e4567-e89b-12d3-a456-426614174000'
  })
  id: string;

  @ApiProperty({ 
    description: 'User full name',
    example: 'John Doe',
    nullable: true
  })
  name: string | null;

  @ApiProperty({ 
    description: 'User email address',
    example: 'john.doe@example.com',
    nullable: true
  })
  email: string | null;

  @ApiProperty({ 
    description: 'User username',
    example: 'john_doe',
    nullable: true
  })
  username: string | null;

  @ApiProperty({ 
    description: 'User role in the system',
    enum: UserRole,
    example: UserRole.GYMER,
    nullable: true
  })
  role: UserRole | null;

  @ApiProperty({ 
    description: 'User phone number',
    example: '+1234567890',
    nullable: true
  })
  phoneNumber: string | null;

  @ApiProperty({ 
    description: 'User date of birth',
    example: '1990-01-01T00:00:00.000Z',
    nullable: true
  })
  dateOfBirth: Date | null;

  @ApiProperty({ 
    description: 'User gender',
    enum: Gender,
    example: Gender.MALE,
    nullable: true
  })
  sex: Gender | null;

  @ApiProperty({ 
    description: 'User address',
    example: '123 Main St, City, Country',
    nullable: true
  })
  address: string | null;

  @ApiProperty({ 
    description: 'User weight in kilograms',
    example: 70.5,
    nullable: true
  })
  weight: number | null;

  @ApiProperty({ 
    description: 'User height in centimeters',
    example: 175.0,
    nullable: true
  })
  height: number | null;

  @ApiProperty({ 
    description: 'User fitness goal',
    enum: FitnessGoal,
    example: FitnessGoal.BUILD_MUSCLE,
    nullable: true
  })
  goal: FitnessGoal | null;

  @ApiProperty({ 
    description: 'User experience type/level',
    example: 'Beginner',
    nullable: true
  })
  expType: string | null;

  @ApiProperty({ 
    description: 'User biography/description',
    example: 'Fitness enthusiast with 5 years of experience',
    nullable: true
  })
  biography: string | null;

  @ApiProperty({ 
    description: 'User profile picture URL',
    example: 'https://example.com/profile-picture.jpg',
    nullable: true
  })
  profilePicture: string | null;

  @ApiProperty({
    description: 'User premium status',
    example: false,
    nullable: true
  })
  premiumStatus: boolean | null;

  // Recommendation preferences
  @ApiProperty({ description: 'Preferred coach gender', enum: Gender, nullable: true })
  preferredCoachGender: Gender | null;

  @ApiProperty({ description: 'Budget per session', example: 200000, nullable: true })
  trainingBudget: number | null;

  @ApiProperty({ description: 'Preferred training time of day', enum: AvailableTimeDto, nullable: true })
  availableTime: AvailableTimeDto | null;

  @ApiProperty({
    description: 'Email verification status',
    example: true,
    nullable: true
  })
  isEmailVerified: boolean | null;

  @ApiProperty({
    description: 'Account creation timestamp',
    example: '2024-01-01T00:00:00.000Z'
  })
  createdAt: Date;

  @ApiProperty({
    description: 'Last update timestamp',
    example: '2024-01-01T00:00:00.000Z'
  })
  updatedAt: Date;
}
