import { PartialType } from '@nestjs/swagger';
import { CreateExerciseLogDto } from './create-exercise-log.dto';

export class UpdateExerciseLogDto extends PartialType(CreateExerciseLogDto) {}
