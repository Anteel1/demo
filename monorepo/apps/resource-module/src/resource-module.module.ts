import { Module } from '@nestjs/common';
import { ResourceModuleController } from './resource-module.controller';
import { ResourceModuleService } from './resource-module.service';

@Module({
  imports: [],
  controllers: [ResourceModuleController],
  providers: [ResourceModuleService],
})
export class ResourceModuleModule {}
