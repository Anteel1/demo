import { NestFactory } from '@nestjs/core';
import { ResourceModuleModule } from './resource-module.module';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';

async function bootstrap() {
   const app = await NestFactory.createMicroservice<MicroserviceOptions>(ResourceModuleModule, {
    transport: Transport.TCP,
    options: {
      host: '0.0.0.0',
      port: 3002,
    },
  });
  await app.listen();
}
bootstrap();