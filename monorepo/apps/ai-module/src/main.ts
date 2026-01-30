import { NestFactory } from '@nestjs/core';
import { AIModuleModule } from './ai-module.module';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { join } from 'path';


async function bootstrap() {
  const app = await NestFactory.createMicroservice<MicroserviceOptions>(AIModuleModule, {
    transport: Transport.GRPC,
    options: {
        package:'chat',
        protoPath: join(__dirname, './chat.proto'),
        url : '0.0.0.0:50051'
    },
  });
  await app.listen();
}
bootstrap();
