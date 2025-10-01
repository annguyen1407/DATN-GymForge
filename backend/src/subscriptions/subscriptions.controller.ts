import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { SubscriptionsService } from './subscriptions.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UserRole } from '@prisma/client';
import { PurchaseSubscriptionDto } from './dto/purchase-subscription.dto';
import { CreateSubscriptionPlanDto } from './dto/create-subscription-plan.dto';
import { UpdateSubscriptionPlanDto } from './dto/update-subscription-plan.dto';

@ApiTags('subscriptions')
@Controller('subscriptions')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class SubscriptionsController {
  constructor(private readonly subscriptionsService: SubscriptionsService) {}

  @Get('plans')
  @ApiOperation({ summary: 'List active subscription plans' })
  listPlans() {
    return this.subscriptionsService.listPlans();
  }

  @Get('status')
  @ApiOperation({ summary: 'Get current user premium status' })
  getStatus(@CurrentUser() user: any) {
    return this.subscriptionsService.getStatus(user.id);
  }

  @Post('purchase')
  @ApiOperation({ summary: 'Purchase a subscription plan' })
  purchase(@Body() dto: PurchaseSubscriptionDto, @CurrentUser() user: any) {
    return this.subscriptionsService.purchase(user.id, dto.planId, dto.method, dto.providerToken);
  }

  // Admin-only endpoints for configuring plans
  @Post('plans')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Create a subscription plan (ADMIN)' })
  createPlan(@Body() dto: CreateSubscriptionPlanDto) {
    return this.subscriptionsService.createPlan(dto);
  }

  @Post('plans/update')
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Update a subscription plan (ADMIN)' })
  updatePlan(@Body() body: { id: string } & UpdateSubscriptionPlanDto) {
    const { id, ...data } = body;
    return this.subscriptionsService.updatePlan(id, data);
  }
}

