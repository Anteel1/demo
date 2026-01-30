import { Module } from '@nestjs/common';
import { ApiGatewayController } from './api-gateway.controller';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { APP_FILTER, APP_INTERCEPTOR } from '@nestjs/core';
import { LoggingIncomingInterceptor } from 'lib/logger.interceptor';
import { ErrorExceptionFilter } from 'lib/error.filter';
import { ServeStaticModule } from '@nestjs/serve-static';
import path, { join } from 'path';

@Module({
  imports: [
      ServeStaticModule.forRoot({
      rootPath: join(__dirname, '../../../', 'files'), 
    }),
     ClientsModule.register([
      {
        name: 'NOTE_SERVICE',
        transport: Transport.TCP,
        options: {
          host: 'note-module',
          port: 3001,
        },
      }]),
      ClientsModule.register([
      {
        name: 'RESOURCE_SERVICE',
        transport: Transport.TCP,
        options: {
          host: 'resource-module',
          port: 3002,
        },
      }]),
      ClientsModule.register([
      {
        name: 'AI_SERVICE', // Tên Token để Inject vào Controller
        transport: Transport.GRPC,
        options: {
          url: 'ai-module:3004', // Địa chỉ của AI Microservice
          package: 'chat',        // Phải khớp với 'package chat' trong file .proto
          protoPath: join(__dirname, './chat.proto'),
        },
      }])
  ],
  controllers: [ApiGatewayController],
  providers: [
    {
          provide: APP_INTERCEPTOR,
          useClass: LoggingIncomingInterceptor,
        },
        {
          provide: APP_FILTER,
          useClass: ErrorExceptionFilter,
        },
  ],
})
export class ApiGatewayModule {}
