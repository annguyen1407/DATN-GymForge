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
import { FeedbacksService } from './feedbacks.service';
import { CreateFeedbackDto } from './dto/create-feedback.dto';
import { UpdateFeedbackDto } from './dto/update-feedback.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserRole } from '@prisma/client';

@ApiTags('feedbacks')
@Controller('feedbacks')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class FeedbacksController {
  constructor(private readonly feedbacksService: FeedbacksService) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(UserRole.GYMER)
  @ApiOperation({ summary: 'Create a new feedback' })
  @ApiResponse({ status: 201, description: 'Feedback created successfully' })
  @ApiResponse({ status: 400, description: 'Bad request' })
  @ApiResponse({ status: 409, description: 'Feedback already exists' })
  create(@Body() createFeedbackDto: CreateFeedbackDto) {
    return this.feedbacksService.create(createFeedbackDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all feedbacks' })
  @ApiResponse({ status: 200, description: 'List of all feedbacks' })
  @ApiQuery({ name: 'gymerId', required: false, description: 'Filter by gymer ID' })
  @ApiQuery({ name: 'coachId', required: false, description: 'Filter by coach ID' })
  findAll(
    @Query('gymerId') gymerId?: string,
    @Query('coachId') coachId?: string,
  ) {
    return this.feedbacksService.findAll(gymerId, coachId);
  }

  @Get('coach/:coachId')
  @ApiOperation({ summary: 'Get feedbacks for a specific coach' })
  @ApiResponse({ status: 200, description: 'Coach feedbacks' })
  findByCoach(@Param('coachId', ParseUUIDPipe) coachId: string) {
    return this.feedbacksService.findByCoach(coachId);
  }

  @Get('coach/:coachId/stats')
  @ApiOperation({ summary: 'Get feedback statistics for a coach' })
  @ApiResponse({ status: 200, description: 'Coach feedback statistics' })
  getCoachStats(@Param('coachId', ParseUUIDPipe) coachId: string) {
    return this.feedbacksService.getCoachStats(coachId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a feedback by ID' })
  @ApiResponse({ status: 200, description: 'Feedback details' })
  @ApiResponse({ status: 404, description: 'Feedback not found' })
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.feedbacksService.findOne(id);
  }

  @Patch(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.GYMER)
  @ApiOperation({ summary: 'Update a feedback' })
  @ApiResponse({ status: 200, description: 'Feedback updated successfully' })
  @ApiResponse({ status: 404, description: 'Feedback not found' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateFeedbackDto: UpdateFeedbackDto,
    @CurrentUser() user: any,
  ) {
    return this.feedbacksService.update(id, updateFeedbackDto, user.id);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.GYMER)
  @ApiOperation({ summary: 'Delete a feedback' })
  @ApiResponse({ status: 200, description: 'Feedback deleted successfully' })
  @ApiResponse({ status: 404, description: 'Feedback not found' })
  remove(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: any) {
    return this.feedbacksService.remove(id, user.id);
  }
}
