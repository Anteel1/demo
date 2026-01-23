import { Controller } from '@nestjs/common';
import { ResourceModuleService } from './resource-module.service';
import { MessagePattern } from '@nestjs/microservices';

@Controller()
export class ResourceModuleController {
  constructor(private readonly resourceModuleService: ResourceModuleService) {}

 @MessagePattern({ cmd: 'upload_file' })
  uploadFile(data : any ){
    const { file } = data
    console.log('comming file',file)
    return this.resourceModuleService.uploadFile(file)
  }

  @MessagePattern({ cmd: 'get_file' })
  getFile(data : any ){
    const { filePath } = data
    return this.resourceModuleService.getFile(filePath)
  }
}
