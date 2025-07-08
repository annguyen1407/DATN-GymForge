import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Query, ParseUUIDPipe } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { EquipmentService } from './equipment.service';
import { CreateEquipmentDto } from './dto/create-equipment.dto';
import { UpdateEquipmentDto } from './dto/update-equipment.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '@prisma/client';

@ApiTags('equipment')
@Controller('equipment')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class EquipmentController {
  constructor(private readonly equipmentService: EquipmentService) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Add new equipment' })
  @ApiResponse({ status: 201, description: 'Equipment added successfully' })
  create(@Body() createEquipmentDto: CreateEquipmentDto) {
    return this.equipmentService.create(createEquipmentDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all equipment' })
  @ApiResponse({ status: 200, description: 'Equipment retrieved successfully' })
  @ApiQuery({ name: 'search', required: false, description: 'Search equipment by name' })
  findAll(@Query('search') search?: string) {
    if (search) {
      return this.equipmentService.search(search);
    }
    return this.equipmentService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get equipment by ID' })
  @ApiResponse({ status: 200, description: 'Equipment details' })
  @ApiResponse({ status: 404, description: 'Equipment not found' })
  findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.equipmentService.findOne(id);
  }

  @Patch(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Update equipment' })
  @ApiResponse({ status: 200, description: 'Equipment updated successfully' })
  @ApiResponse({ status: 404, description: 'Equipment not found' })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() updateEquipmentDto: UpdateEquipmentDto,
  ) {
    return this.equipmentService.update(id, updateEquipmentDto);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Delete equipment' })
  @ApiResponse({ status: 200, description: 'Equipment deleted successfully' })
  @ApiResponse({ status: 404, description: 'Equipment not found' })
  remove(@Param('id', ParseUUIDPipe) id: string) {
    return this.equipmentService.remove(id);
  }
}
