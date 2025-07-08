import { PartialType } from '@nestjs/swagger';
import { CreateGymerDto } from './create-gymer.dto';

export class UpdateGymerDto extends PartialType(CreateGymerDto) {}
