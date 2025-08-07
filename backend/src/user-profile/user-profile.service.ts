import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUserProfileDto } from './dto/create-user-profile.dto';
import { UpdateUserProfileDto } from './dto/update-user-profile.dto';
import { UserProfileDto } from './dto/user-profile.dto';
import { DeleteProfileResponseDto } from './dto/delete-profile-response.dto';

@Injectable()
export class UserProfileService {
  constructor(private prisma: PrismaService) {}

  async createProfile(userId: string, createUserProfileDto: CreateUserProfileDto): Promise<UserProfileDto> {
    // Check if user exists
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Update user with profile information
    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: {
        phoneNumber: createUserProfileDto.phoneNumber,
        dateOfBirth: createUserProfileDto.dateOfBirth ? new Date(createUserProfileDto.dateOfBirth) : null,
        sex: createUserProfileDto.sex,
        address: createUserProfileDto.address,
        weight: createUserProfileDto.weight,
        height: createUserProfileDto.height,
        goal: createUserProfileDto.goal,
        expType: createUserProfileDto.expType,
        biography: createUserProfileDto.biography,
        profilePicture: createUserProfileDto.profilePicture,
      },
      select: {
        id: true,
        name: true,
        email: true,
        username: true,
        role: true,
        phoneNumber: true,
        dateOfBirth: true,
        sex: true,
        address: true,
        weight: true,
        height: true,
        goal: true,
        expType: true,
        biography: true,
        profilePicture: true,
        premiumStatus: true,
        isEmailVerified: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    return updatedUser;
  }

  async updateProfile(userId: string, currentUserId: string, updateUserProfileDto: UpdateUserProfileDto): Promise<UserProfileDto> {
    // Check if user is updating their own profile
    if (userId !== currentUserId) {
      throw new ForbiddenException('You can only update your own profile');
    }

    // Check if user exists
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Update user with profile information
    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: {
        ...(updateUserProfileDto.phoneNumber !== undefined && { phoneNumber: updateUserProfileDto.phoneNumber }),
        ...(updateUserProfileDto.dateOfBirth !== undefined && { 
          dateOfBirth: updateUserProfileDto.dateOfBirth ? new Date(updateUserProfileDto.dateOfBirth) : null 
        }),
        ...(updateUserProfileDto.sex !== undefined && { sex: updateUserProfileDto.sex }),
        ...(updateUserProfileDto.address !== undefined && { address: updateUserProfileDto.address }),
        ...(updateUserProfileDto.weight !== undefined && { weight: updateUserProfileDto.weight }),
        ...(updateUserProfileDto.height !== undefined && { height: updateUserProfileDto.height }),
        ...(updateUserProfileDto.goal !== undefined && { goal: updateUserProfileDto.goal }),
        ...(updateUserProfileDto.expType !== undefined && { expType: updateUserProfileDto.expType }),
        ...(updateUserProfileDto.biography !== undefined && { biography: updateUserProfileDto.biography }),
        ...(updateUserProfileDto.profilePicture !== undefined && { profilePicture: updateUserProfileDto.profilePicture }),
      },
      select: {
        id: true,
        name: true,
        email: true,
        username: true,
        role: true,
        phoneNumber: true,
        dateOfBirth: true,
        sex: true,
        address: true,
        weight: true,
        height: true,
        goal: true,
        expType: true,
        biography: true,
        profilePicture: true,
        premiumStatus: true,
        isEmailVerified: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    return updatedUser;
  }

  async getProfile(userId: string): Promise<UserProfileDto> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        email: true,
        username: true,
        role: true,
        phoneNumber: true,
        dateOfBirth: true,
        sex: true,
        address: true,
        weight: true,
        height: true,
        goal: true,
        expType: true,
        biography: true,
        profilePicture: true,
        premiumStatus: true,
        isEmailVerified: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  async deleteProfile(userId: string): Promise<DeleteProfileResponseDto> {
    // Check if user exists
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Clear profile data while keeping the basic user account intact
    await this.prisma.user.update({
      where: { id: userId },
      data: {
        phoneNumber: null,
        dateOfBirth: null,
        sex: null,
        address: null,
        weight: null,
        height: null,
        goal: null,
        expType: null,
        biography: null,
        profilePicture: null,
      },
    });

    return { message: 'User profile deleted successfully' };
  }
}
