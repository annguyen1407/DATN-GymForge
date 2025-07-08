import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
  ParseUUIDPipe,
  Query,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { TrainingRequestsService } from './training-requests.service';
import { CreateTrainingRequestDto } from './dto/create-training-request.dto';
import { UpdateTrainingRequestDto } from './dto/update-training-request.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserRole, TrainingRequestStatus } from '@prisma/client';

@ApiTags('training-requests')
@Controller('training-requests')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class TrainingRequestsController {
  constructor(private readonly trainingRequestsService: TrainingRequestsService) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(UserRole.COACH, UserRole.GYMER)
  @ApiOperation({ summary: 'Create a new training request' })
  @ApiResponse({ status: 201, description: 'Training request created successfully' })
  @ApiResponse({ status: 400, description: 'Bad request' })
  @ApiResponse({ status: 409, description: 'Training request already exists' })
  create(@Body() createTrainingRequestDto: CreateTrainingRequestDto) {
    return this.trainingRequestsService.create(createTrainingRequestDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all training requests' })
  @ApiResponse({ status: 200, description: 'List of all training requests' })
  @ApiQuery({ name: 'gymerId', required: false, description: 'Filter by gymer ID' })
  @ApiQuery({ name: 'coachId', required: false, description: 'Filter by coach ID' })
  @ApiQuery({ name: 'status', required: false, enum: TrainingRequestStatus, description: 'Filter by status' })
  findAll(
    @Query('gymerId') gymerId?: string,
    @Query('coachId') coachId?: string,
    @Query('status') status?: TrainingRequestStatus,
  ) {
    return this.trainingRequestsService.findAll(gymerId, coachId, status);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a training request by ID' })
  @ApiResponse({ status: 200, description: 'Training request details' })
  @ApiResponse({ status: 404, description: 'Training request not found' })
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.trainingRequestsService.findOne(id);
  }

  @Patch(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.COACH, UserRole.GYMER)
  @ApiOperation({ summary: 'Update a training request' })
  @ApiResponse({ status: 200, description: 'Training request updated successfully' })
  @ApiResponse({ status: 404, description: 'Training request not found' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateTrainingRequestDto: UpdateTrainingRequestDto,
    @CurrentUser() user: any,
  ) {
    return this.trainingRequestsService.update(id, updateTrainingRequestDto, user.id);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.COACH, UserRole.GYMER)
  @ApiOperation({ summary: 'Delete a training request' })
  @ApiResponse({ status: 200, description: 'Training request deleted successfully' })
  @ApiResponse({ status: 404, description: 'Training request not found' })
  remove(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: any) {
    return this.trainingRequestsService.remove(id, user.id);
  }

  @Post(':id/accept')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.COACH)
  @ApiOperation({ summary: 'Accept a training request' })
  @ApiResponse({ status: 200, description: 'Training request accepted successfully' })
  @ApiResponse({ status: 404, description: 'Training request not found' })
  @ApiResponse({ status: 409, description: 'Request cannot be accepted' })
  accept(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: any) {
    return this.trainingRequestsService.accept(id, user.id);
  }

  @Post(':id/reject')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.COACH)
  @ApiOperation({ summary: 'Reject a training request' })
  @ApiResponse({ status: 200, description: 'Training request rejected successfully' })
  @ApiResponse({ status: 404, description: 'Training request not found' })
  @ApiResponse({ status: 409, description: 'Request cannot be rejected' })
  reject(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: any) {
    return this.trainingRequestsService.reject(id, user.id);
  }
}
