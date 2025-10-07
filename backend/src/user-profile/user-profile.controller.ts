import { Controller, Post, Patch, Get, Delete, Body, Param, UseGuards, ParseUUIDPipe } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiBody } from '@nestjs/swagger';
import { UserProfileService } from './user-profile.service';
import { CreateUserProfileDto } from './dto/create-user-profile.dto';
import { UpdateUserProfileDto } from './dto/update-user-profile.dto';
import { UserProfileDto } from './dto/user-profile.dto';
import { DeleteProfileResponseDto } from './dto/delete-profile-response.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { User, UserRole } from '@prisma/client';

@ApiTags('User Profile')
@Controller('profile')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class UserProfileController {
  constructor(private readonly userProfileService: UserProfileService) {}

  @Post()
  @ApiOperation({ summary: 'Create or complete user profile' })
  @ApiResponse({ status: 201, description: 'Profile created successfully', type: UserProfileDto })
  @ApiResponse({ status: 404, description: 'User not found' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async createProfile(
    @CurrentUser() user: User,
    @Body() createUserProfileDto: CreateUserProfileDto,
  ): Promise<UserProfileDto> {
    return this.userProfileService.createProfile(user.id, createUserProfileDto);
  }

  @Patch()
  @ApiOperation({ summary: 'Update user profile' })
  @ApiResponse({ status: 200, description: 'Profile updated successfully', type: UserProfileDto })
  @ApiResponse({ status: 404, description: 'User not found' })
  @ApiResponse({ status: 403, description: 'Forbidden - can only update own profile' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiBody({
    description: 'Any subset of profile fields to update',
    schema: {
      type: 'object',
      properties: {
        name: { type: 'string', example: 'John Nguyen' },
        phoneNumber: { type: 'string', example: '+1234567890' },
        dateOfBirth: { type: 'string', format: 'date', example: '1990-01-01' },
        sex: { type: 'string', example: 'MALE' },
        address: { type: 'string', example: '123 Main St, City, Country' },
        weight: { type: 'number', example: 70.5 },
        height: { type: 'number', example: 175 },
        oneRm: { type: 'number', example: 120.0, description: 'Estimated 1RM (kg)' },
        goal: { type: 'string', example: 'LOSE_WEIGHT' },
        expType: { type: 'string', example: 'Beginner' },
        biography: { type: 'string', example: 'Fitness enthusiast with 5 years of experience' },
        profilePicture: { type: 'string', format: 'uri', example: 'https://example.com/profile-picture.jpg' },
        preferredCoachGender: { type: 'string', example: 'MALE' },
        trainingBudget: { type: 'number', example: 200000 },
        availableTime: { type: 'string', example: 'MORNING' },
      },
    },
  })
  async updateProfile(
    @CurrentUser() user: User,
    @Body() updateUserProfileDto: UpdateUserProfileDto,
  ): Promise<UserProfileDto> {
    return this.userProfileService.updateProfile(user.id, user.id, updateUserProfileDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get current user profile' })
  @ApiResponse({ status: 200, description: 'Profile retrieved successfully', type: UserProfileDto })
  @ApiResponse({ status: 404, description: 'User not found' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async getProfile(@CurrentUser() user: User): Promise<UserProfileDto> {
    return this.userProfileService.getProfile(user.id);
  }

  @Delete(':userId')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Delete user profile (Admin only)' })
  @ApiResponse({ status: 200, description: 'Profile deleted successfully', type: DeleteProfileResponseDto })
  @ApiResponse({ status: 404, description: 'User not found' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - Admin access required' })
  async deleteProfile(@Param('userId', ParseUUIDPipe) userId: string): Promise<DeleteProfileResponseDto> {
    return this.userProfileService.deleteProfile(userId);
  }
}
