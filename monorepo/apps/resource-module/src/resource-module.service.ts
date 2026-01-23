import { Injectable } from '@nestjs/common';
import path from 'path';
import * as fs from "fs"

@Injectable()
export class ResourceModuleService {
  async uploadFile(file : any): Promise<any> {
    const fileDir = `./files`
    const type = file.mimetype == 'image/png' ? '.png' : '.text'
    const ramdonString = crypto.randomUUID()
    const fileName = `${Date.now()}-${ramdonString}${type}`;
    const fullPath = path.join(fileDir, fileName);
    try {
      // 2. Write the buffer to the /tmp directory
      const bufferData = Buffer.from(file.buffer.data);
      await fs.writeFile(fullPath, bufferData, (err) =>{ console.log(err)});
      
      console.log(`File written successfully to: ${fullPath}`);
      const returnUrl  = fileName
      return {
        url: `http://127.0.0.1:3000/${returnUrl}` ,
      };
    } catch (error) {
      console.error('Error writing file:', error);
    }
  }
  async getFile(filePath : string ): Promise<any> {
    const fileDir = `./files/`
    const fileData =fs.readFileSync(path.join(fileDir, filePath))
    return fileData
  }
}
