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
import { GymersService } from './gymers.service';
import { CreateGymerDto } from './dto/create-gymer.dto';
import { UpdateGymerDto } from './dto/update-gymer.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '@prisma/client';

@ApiTags('gymers')
@Controller('gymers')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class GymersController {
  constructor(private readonly gymersService: GymersService) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Create a new gymer profile' })
  @ApiResponse({ status: 201, description: 'Gymer profile created successfully' })
  @ApiResponse({ status: 400, description: 'Bad request' })
  @ApiResponse({ status: 409, description: 'Gymer profile already exists' })
  create(@Body() createGymerDto: CreateGymerDto) {
    return this.gymersService.create(createGymerDto);
  }

  @Get()
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.COACH)
  @ApiOperation({ summary: 'Get all gymers' })
  @ApiResponse({ status: 200, description: 'List of all gymers' })
  findAll() {
    return this.gymersService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a gymer by ID' })
  @ApiResponse({ status: 200, description: 'Gymer details' })
  @ApiResponse({ status: 404, description: 'Gymer not found' })
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.gymersService.findOne(id);
  }

  @Get('user/:userId')
  @ApiOperation({ summary: 'Get gymer by user ID' })
  @ApiResponse({ status: 200, description: 'Gymer details' })
  @ApiResponse({ status: 404, description: 'Gymer not found' })
  findByUserId(@Param('userId', ParseUUIDPipe) userId: string) {
    return this.gymersService.findByUserId(userId);
  }

  @Patch(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.GYMER)
  @ApiOperation({ summary: 'Update a gymer profile' })
  @ApiResponse({ status: 200, description: 'Gymer profile updated successfully' })
  @ApiResponse({ status: 404, description: 'Gymer not found' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateGymerDto: UpdateGymerDto,
  ) {
    return this.gymersService.update(id, updateGymerDto);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Delete a gymer profile' })
  @ApiResponse({ status: 200, description: 'Gymer profile deleted successfully' })
  @ApiResponse({ status: 404, description: 'Gymer not found' })
  remove(@Param('id', ParseUUIDPipe) id: string) {
    return this.gymersService.remove(id);
  }
}
