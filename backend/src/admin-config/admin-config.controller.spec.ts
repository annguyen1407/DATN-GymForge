import { Test, TestingModule } from '@nestjs/testing';
import { AdminConfigController } from './admin-config.controller';
import { AdminConfigService } from './admin-config.service';

describe('AdminConfigController', () => {
  let controller: AdminConfigController;
  const service = {
    get: jest.fn(),
    update: jest.fn(),
  } as unknown as AdminConfigService;

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      controllers: [AdminConfigController],
      providers: [{ provide: AdminConfigService, useValue: service }],
    }).compile();

    controller = module.get(AdminConfigController);
  });

  it('get(): returns config from service', async () => {
    const cfg = { basePriceX: 10 } as any;
    (service.get as any).mockResolvedValueOnce(cfg);
    await expect(controller.get()).resolves.toBe(cfg);
    expect(service.get).toHaveBeenCalled();
  });

  it('update(): forwards body to service and returns result', async () => {
    const body = { basePriceX: 12 } as any;
    const updated = { id: 'singleton', basePriceX: 12 } as any;
    (service.update as any).mockResolvedValueOnce(updated);
    await expect(controller.update(body)).resolves.toBe(updated);
    expect(service.update).toHaveBeenCalledWith(body);
  });
});

