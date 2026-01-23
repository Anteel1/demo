import { Injectable, InternalServerErrorException } from '@nestjs/common';
import path from 'path';
import * as fs from 'fs'
export class NoteModuleService {
  getHello(): string {
    return 'Hello World!';
  }
  getHealthCheck(serverName : string | null) : boolean {
    if(serverName) return true
    return false
  }

   async insertNote(data: { title: string; tag?: string; content: string, id : string }) {
    try {
      const { title, tag, content } = data;

      // 1. Tạo tên file theo format: Title.json (loại bỏ ký tự đặc biệt để tránh lỗi file hệ thống)
      const id = data.id ? data.id : crypto.randomUUID()
      console.log('checking id ', id)
      const safeTitle = title.replace(/[/\\?%*:|"<>]/g, '-');
      const fileName = `${id}.json`;
      const filePath = path.join('./files', fileName);
      // 2. Chuẩn bị nội dung JSON
      const fileContent = {
        id : id,
        title : safeTitle,
        tag: tag || 'general',
        content : content,
        updatedAt: new Date().toISOString(),
      };

      await fs.writeFile(filePath,JSON.stringify(fileContent, null, 2), (res)=>{
        console.log(res)
      })

      return {
        message: `Đã lưu file: ${fileName}`,
        path: filePath
      };
    } catch (error) {
      throw new InternalServerErrorException('Lỗi khi ghi file ghi chú');
    }
  }

  async getNotes(){
    const filePath = path.join('./files');
    const files = await fs.readdirSync(filePath)
    return  files.filter(fileName => fileName.split('.')[1] != 'png').map(item => { 
      const fileName = item;
      const filePath = path.join('./files', fileName);
      const fileData = JSON.parse(fs.readFileSync(filePath).toString()) 
      return { ...fileData}
    } )
  }

  async getNoteByID(id : string){
    console.log('checking note', id)
    const fileName = `${id}.json`;
    const filePath = path.join('./files', fileName);
    const fileData = JSON.parse(fs.readFileSync(filePath).toString()) 
    console.log('[file data]',fileData)
    return fileData
  }
}
