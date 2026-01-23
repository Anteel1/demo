import { Controller, Get, Inject, Query } from '@nestjs/common';
import { NoteModuleService } from './note-module.service';
import { MessagePattern } from '@nestjs/microservices';

@Controller()
export class NoteModuleController {
  constructor(private readonly appService: NoteModuleService) {}

  @MessagePattern({ cmd: 'insert_note' })
  insertNote(data : any ){
    const { title, tag, content, id} = data
    return this.appService.insertNote({ title  , tag : 'note', content : content, id})
  }

  @MessagePattern({ cmd: 'get_notes' })
  getNotes(){
    return this.appService.getNotes()
  }

  @MessagePattern({ cmd: 'get_note_by_title' })
  getNoteByTitle(data : any ){
    const { id } = data
    return this.appService.getNoteByID(id)
  }
}
