import { Controller, Get, Put, Body, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AdminConfigService } from './admin-config.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '@prisma/client';

@ApiTags('admin-config')
@Controller('admin-config')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class AdminConfigController {
  constructor(private readonly service: AdminConfigService) {}

  @Get()
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Get pricing and policy configuration' })
  get() {
    return this.service.get();
  }

  @Put()
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Update pricing and policy configuration' })
  update(@Body() body: Partial<{ basePriceX: number; ratingMultiplier: number; commissionRate: number; coachCancelLockDays: number }>) {
    return this.service.update(body);
  }
}

