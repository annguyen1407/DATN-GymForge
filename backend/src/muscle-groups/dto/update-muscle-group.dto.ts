import { PartialType } from '@nestjs/swagger';
import { CreateMuscleGroupDto } from './create-muscle-group.dto';

export class UpdateMuscleGroupDto extends PartialType(CreateMuscleGroupDto) {}
