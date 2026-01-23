import { Module } from '@nestjs/common';
import { NoteModuleController } from './note-module.controller';
import { NoteModuleService } from './note-module.service';
import { EventGateway } from './event.gateway';

@Module({
  imports: [],
  controllers: [NoteModuleController],
  providers: [
    EventGateway,
    NoteModuleService,
  ],
})
export class NoteModuleModule {}
