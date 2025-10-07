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
        name: createUserProfileDto.name ?? user.name,
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
        oneRm: (createUserProfileDto as any).oneRm,
        // preferences
        preferredCoachGender: (createUserProfileDto as any).preferredCoachGender,
        trainingBudget: (createUserProfileDto as any).trainingBudget,
        availableTime: (createUserProfileDto as any).availableTime as any,
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
        oneRm: true,
        premiumStatus: true,
        isEmailVerified: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    return {
      ...updatedUser,
      // Include preference fields even if not selected (pre-migration safety)
      preferredCoachGender: (updatedUser as any)?.preferredCoachGender ?? null,
      trainingBudget: (updatedUser as any)?.trainingBudget ?? null,
      availableTime: (updatedUser as any)?.availableTime ?? null,
    } as any;
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
        ...(updateUserProfileDto.name !== undefined && { name: updateUserProfileDto.name }),
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
        ...((updateUserProfileDto as any).oneRm !== undefined && { oneRm: (updateUserProfileDto as any).oneRm }),
        // preferences
        ...((updateUserProfileDto as any).preferredCoachGender !== undefined && { preferredCoachGender: (updateUserProfileDto as any).preferredCoachGender }),
        ...((updateUserProfileDto as any).trainingBudget !== undefined && { trainingBudget: (updateUserProfileDto as any).trainingBudget }),
        ...((updateUserProfileDto as any).availableTime !== undefined && { availableTime: (updateUserProfileDto as any).availableTime as any }),
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
        oneRm: true,
        premiumStatus: true,
        isEmailVerified: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    return {
      ...updatedUser,
      preferredCoachGender: (updatedUser as any)?.preferredCoachGender ?? null,
      trainingBudget: (updatedUser as any)?.trainingBudget ?? null,
      availableTime: (updatedUser as any)?.availableTime ?? null,
    } as any;
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
        oneRm: true,
        premiumStatus: true,
        isEmailVerified: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return {
      ...user,
      preferredCoachGender: (user as any)?.preferredCoachGender ?? null,
      trainingBudget: (user as any)?.trainingBudget ?? null,
      availableTime: (user as any)?.availableTime ?? null,
    } as any;
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
