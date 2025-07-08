import { Injectable, NotFoundException } from '@nestjs/common';
import { Equipment } from '@prisma/client';
import { CreateEquipmentDto } from './dto/create-equipment.dto';
import { UpdateEquipmentDto } from './dto/update-equipment.dto';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class EquipmentService {
  constructor(private prisma: PrismaService) {}

  async create(createEquipmentDto: CreateEquipmentDto): Promise<Equipment> {
    return this.prisma.equipment.create({
      data: createEquipmentDto
    });
  }

  async findAll(): Promise<Equipment[]> {
    return this.prisma.equipment.findMany({
      orderBy: { name: 'asc' },
    });
  }

  async findOne(id: string): Promise<Equipment> {
    const equipment = await this.prisma.equipment.findUnique({
      where: { id },
    });

    if (!equipment) {
      throw new NotFoundException('Equipment not found');
    }

    return equipment;
  }

  async update(id: string, updateEquipmentDto: UpdateEquipmentDto): Promise<Equipment> {
    await this.findOne(id);

    return this.prisma.equipment.update({
      where: { id },
      data: updateEquipmentDto,
    });
  }

  async remove(id: string): Promise<Equipment> {
    const equipment = await this.findOne(id);

    return this.prisma.equipment.delete({
      where: { id: equipment.id }
    });
  }

  async search(query: string): Promise<Equipment[]> {
    return this.prisma.equipment.findMany({
      where: {
        name: {
          contains: query,
          mode: 'insensitive',
        },
      },
      orderBy: { name: 'asc' },
    });
  }
}
