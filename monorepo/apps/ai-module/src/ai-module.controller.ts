import { Controller, Get, Inject, Query } from '@nestjs/common';
import { AIModuleService } from './ai-module.service';
import { GrpcMethod, MessagePattern } from '@nestjs/microservices';
import { Observable } from 'rxjs';

@Controller()
export class AIModuleController {
  constructor(private readonly appService: AIModuleService) {}

  @GrpcMethod('ChatService', 'StreamChat')
  streamChat(data: { prompt: string }): Observable<any> {
    return new Observable((observer) => {
      (async () => {
        const generator = this.appService.chatStream(data.prompt);
        for await (const chunk of generator) {
          observer.next({ content: chunk }); // Gửi từng chunk qua gRPC stream
        }
        observer.complete();
      })();
    });
  }

}
