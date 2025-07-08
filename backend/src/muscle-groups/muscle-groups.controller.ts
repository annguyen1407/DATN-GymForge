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
import { MuscleGroupsService } from './muscle-groups.service';
import { CreateMuscleGroupDto } from './dto/create-muscle-group.dto';
import { UpdateMuscleGroupDto } from './dto/update-muscle-group.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '@prisma/client';

@ApiTags('muscle-groups')
@Controller('muscle-groups')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class MuscleGroupsController {
  constructor(private readonly muscleGroupsService: MuscleGroupsService) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Create a new muscle group' })
  @ApiResponse({ status: 201, description: 'Muscle group created successfully' })
  @ApiResponse({ status: 400, description: 'Bad request' })
  @ApiResponse({ status: 409, description: 'Muscle group already exists' })
  create(@Body() createMuscleGroupDto: CreateMuscleGroupDto) {
    return this.muscleGroupsService.create(createMuscleGroupDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all muscle groups' })
  @ApiResponse({ status: 200, description: 'List of all muscle groups' })
  @ApiQuery({ name: 'search', required: false, description: 'Search muscle groups' })
  findAll(@Query('search') search?: string) {
    if (search) {
      return this.muscleGroupsService.search(search);
    }
    return this.muscleGroupsService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a muscle group by ID' })
  @ApiResponse({ status: 200, description: 'Muscle group details' })
  @ApiResponse({ status: 404, description: 'Muscle group not found' })
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.muscleGroupsService.findOne(id);
  }

  @Patch(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Update a muscle group' })
  @ApiResponse({ status: 200, description: 'Muscle group updated successfully' })
  @ApiResponse({ status: 404, description: 'Muscle group not found' })
  @ApiResponse({ status: 409, description: 'Muscle group name already exists' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateMuscleGroupDto: UpdateMuscleGroupDto,
  ) {
    return this.muscleGroupsService.update(id, updateMuscleGroupDto);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Delete a muscle group' })
  @ApiResponse({ status: 200, description: 'Muscle group deleted successfully' })
  @ApiResponse({ status: 404, description: 'Muscle group not found' })
  @ApiResponse({ status: 409, description: 'Muscle group is being used by exercises' })
  remove(@Param('id', ParseUUIDPipe) id: string) {
    return this.muscleGroupsService.remove(id);
  }
}
