import { Controller, Get, Query, Param, ParseUUIDPipe, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { SalariesService } from './salaries.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserRole } from '@prisma/client';

@ApiTags('salaries')
@Controller('salaries')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class SalariesController {
  constructor(private readonly service: SalariesService) {}

  @Get('my-earnings')
  @Roles(UserRole.COACH, UserRole.ADMIN)
  @ApiOperation({ summary: 'List my earnings (coach) or by coachId (admin)' })
  @ApiQuery({ name: 'coachId', required: false })
  @ApiQuery({ name: 'year', required: false, type: Number })
  @ApiQuery({ name: 'month', required: false, type: Number })
  listMyEarnings(
    @CurrentUser() user: any,
    @Query('coachId') coachId?: string,
    @Query('year') year?: string,
    @Query('month') month?: string,
  ) {
    const y = year ? parseInt(year, 10) : undefined;
    const m = month ? parseInt(month, 10) : undefined;
    return this.service.listEarningsForCoach(user.id, coachId, y, m);
  }

  @Get('monthly')
  @Roles(UserRole.COACH, UserRole.ADMIN)
  @ApiOperation({ summary: 'Get or compute current month salary for a coach' })
  @ApiQuery({ name: 'coachId', required: false })
  @ApiQuery({ name: 'year', required: false, type: Number })
  @ApiQuery({ name: 'month', required: false, type: Number })
  monthly(
    @CurrentUser() user: any,
    @Query('coachId') coachId?: string,
    @Query('year') year?: string,
    @Query('month') month?: string,
  ) {
    const y = year ? parseInt(year, 10) : undefined;
    const m = month ? parseInt(month, 10) : undefined;
    return this.service.getOrComputeMonthlySalary(user.id, coachId, y, m);
  }

  @Post(':salaryId/mark-paid')
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Mark a coach salary as PAID (mock payout)' })
  markPaid(@CurrentUser() user: any, @Param('salaryId', ParseUUIDPipe) salaryId: string) {
    return this.service.markPaid(user.id, salaryId);
  }
}

