import { CallHandler, ExecutionContext, HttpException, Injectable, NestInterceptor, NestMiddleware } from "@nestjs/common";

@Injectable()
export class BlockMiddleware implements NestMiddleware {
    use(req: any, res: any, next: (error?: any) => void) {
        // if(!req.query || Object.entries(req.query).length == 0) throw new HttpException("No query found !",400)
        next()
    }
}