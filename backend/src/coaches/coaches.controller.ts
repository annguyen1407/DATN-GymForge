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
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { CoachesService } from './coaches.service';
import { CreateCoachDto } from './dto/create-coach.dto';
import { UpdateCoachDto } from './dto/update-coach.dto';
import { UpdateOpenToTrainingDto } from './dto/update-open-to-training.dto';
import { ListCoachesQueryDto } from './dto/list-coaches.query';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '@prisma/client';

@ApiTags('coaches')
@Controller('coaches')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class CoachesController {
  constructor(private readonly coachesService: CoachesService) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Create a new coach profile' })
  @ApiResponse({ status: 201, description: 'Coach profile created successfully' })
  @ApiResponse({ status: 400, description: 'Bad request' })
  @ApiResponse({ status: 409, description: 'Coach profile already exists' })
  create(@Body() createCoachDto: CreateCoachDto) {
    return this.coachesService.create(createCoachDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all coaches (with sort/filter)' })
  @ApiResponse({ status: 200, description: 'List of coaches' })
  findAll(@Query() query: ListCoachesQueryDto) {
    return this.coachesService.findAll(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a coach by ID' })
  @ApiResponse({ status: 200, description: 'Coach details' })
  @ApiResponse({ status: 404, description: 'Coach not found' })
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.coachesService.findOne(id);
  }

  @Get('user/:userId')
  @ApiOperation({ summary: 'Get coach by user ID' })
  @ApiResponse({ status: 200, description: 'Coach details' })
  @ApiResponse({ status: 404, description: 'Coach not found' })
  findByUserId(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.coachesService.findByUserId(userId);
  }

  @Patch(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.COACH)
  @ApiOperation({ summary: 'Update a coach profile' })
  @ApiResponse({ status: 200, description: 'Coach profile updated successfully' })
  @ApiResponse({ status: 404, description: 'Coach not found' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateCoachDto: UpdateCoachDto,
  ) {
    return this.coachesService.update(id, updateCoachDto);
  }

  @Patch('me/open-to-training')
  @UseGuards(RolesGuard)
  @Roles(UserRole.COACH)
  @ApiOperation({ summary: 'Toggle coach open-to-training status (self)' })
  @ApiResponse({ status: 200, description: 'Coach readiness updated' })
  updateOpenToTraining(@Body() dto: UpdateOpenToTrainingDto, @CurrentUser() user: any) {
    return this.coachesService.updateOpenToTraining(user.id, dto.isOpenToTraining);
  }

  @Patch(':id/approve')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Approve a coach profile and grant premium' })
  @ApiResponse({ status: 200, description: 'Coach approved' })
  approve(@Param('id', ParseUUIDPipe) id: string) {
    return this.coachesService.approve(id);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Delete a coach profile' })
  @ApiResponse({ status: 200, description: 'Coach profile deleted successfully' })
  @ApiResponse({ status: 404, description: 'Coach not found' })
  remove(@Param('id', ParseUUIDPipe) id: string) {
    return this.coachesService.remove(id);
  }
}
