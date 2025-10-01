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
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { CoachesService } from './coaches.service';
import { CreateCoachDto } from './dto/create-coach.dto';
import { UpdateCoachDto } from './dto/update-coach.dto';
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
  @ApiOperation({ summary: 'Get all coaches' })
  @ApiResponse({ status: 200, description: 'List of all coaches' })
  findAll() {
    return this.coachesService.findAll();
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
