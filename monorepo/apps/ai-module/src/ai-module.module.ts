import { Module } from '@nestjs/common';
import { AIModuleService } from './ai-module.service';
import { AIModuleController } from './ai-module.controller';
@Module({
  imports: [],
  controllers: [AIModuleController],
  providers: [
    AIModuleService
  ],
})
export class AIModuleModule {}
