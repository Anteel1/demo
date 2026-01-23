import { Body, Controller, Get, Inject, Param, Post, Query, UploadedFile, UseInterceptors } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { FileInterceptor } from '@nestjs/platform-express';

@Controller()
export class ApiGatewayController {
  constructor(
    @Inject('NOTE_SERVICE') private noteClient: ClientProxy,
    @Inject('RESOURCE_SERVICE') private resourceClient: ClientProxy
  ) { }

  @Post('note')
  insertNote(@Query("note") note: string, @Query("id") id: string, @Body("content") content: string) {
    if (!note && !id) return this.noteClient.send({ cmd: 'get_notes' }, {});
    if (id && !note) return this.noteClient.send({ cmd: 'get_note_by_title' }, { id: id });
    console.log('comming to insert note :',id)
    return this.noteClient.send({ cmd: 'insert_note' }, { title: note, tag: 'note', content: content, id });
  }

  @Post('upload')
  @UseInterceptors(FileInterceptor('file'))
  uploadFile(@UploadedFile() file: Express.Multer.File) {
    if (file) return this.resourceClient.send({ cmd: 'upload_file' }, { file })
  }

}
