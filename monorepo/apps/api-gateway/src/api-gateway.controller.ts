import { Body, Controller, Get, Inject, Param, Post, Query, Sse, UploadedFile, UseInterceptors } from '@nestjs/common';
import {ClientProxy } from '@nestjs/microservices';
import type { ClientGrpc } from '@nestjs/microservices'; 
import { FileInterceptor } from '@nestjs/platform-express';
import { map, Observable } from 'rxjs';

@Controller()
export class ApiGatewayController {
  private AIService: any;
  constructor(
    @Inject('NOTE_SERVICE') private noteClient: ClientProxy,
    @Inject('RESOURCE_SERVICE') private resourceClient: ClientProxy,
    @Inject('AI_SERVICE') private client: ClientGrpc
  ) { }

  onModuleInit() {
    this.AIService = this.client.getService<any>('ChatService');
  }

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

  @Sse('ask')
  @Get('ask')
  ask(@Query('prompt') prompt: string): Observable<MessageEvent> {
    // Gọi stream từ microservice
    const grpcStream = this.AIService.streamChat({ prompt });
    return grpcStream.pipe(
      map((res: any) => ({ data: res.content } as MessageEvent)),
    );
  }
}
