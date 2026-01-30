import { Injectable } from '@nestjs/common';
import { Ollama } from 'ollama';

@Injectable()
export class AIModuleService {
    private ollama: Ollama;

    constructor() {
    this.ollama = new Ollama({
      host: 'https://ollama.com',
      headers: {
        Authorization: `Bearer ${process.env.OLLAMA_API_KEY}`,
      },
    });
  }

  async *chatStream(content: string) {
    const response = await this.ollama.chat({
      model: 'luonglkvn100/mika',
      messages: [{ role: 'user', content }],
      stream: true,
    });

    for await (const part of response) {
      yield part.message.content;
    }
  }
}
