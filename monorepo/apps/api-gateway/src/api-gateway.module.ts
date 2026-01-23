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
          host: '127.0.0.1',
          port: 3001,
        },
      }]),
      ClientsModule.register([
      {
        name: 'RESOURCE_SERVICE',
        transport: Transport.TCP,
        options: {
          host: '127.0.0.1',
          port: 3002,
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
