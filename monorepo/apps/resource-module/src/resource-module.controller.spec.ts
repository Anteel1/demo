import { Test, TestingModule } from '@nestjs/testing';
import { ResourceModuleController } from './resource-module.controller';
import { ResourceModuleService } from './resource-module.service';

describe('ResourceModuleController', () => {
  let resourceModuleController: ResourceModuleController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [ResourceModuleController],
      providers: [ResourceModuleService],
    }).compile();

    resourceModuleController = app.get<ResourceModuleController>(ResourceModuleController);
  });

  describe('root', () => {
    it('should return "Hello World!"', () => {
      expect(resourceModuleController.getHello()).toBe('Hello World!');
    });
  });
});
