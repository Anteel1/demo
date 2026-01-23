import { CallHandler, ExecutionContext, HttpException, HttpStatus, Injectable, NestInterceptor } from "@nestjs/common";
import { catchError, map, Observable, tap, throwError } from "rxjs";
import { baseResponse } from "./dto/base.dto";

@Injectable()
export class LoggingIncomingInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any>  {
    const req = context.switchToHttp().getRequest();
    const logTime = new Date
        console.log(`[${logTime}]`, {
            url: req.url,
            query : req.query || null,
            param : req.params || null,
            body : req.body || null
        })
    return next.handle().pipe(
        map(
            (response) : baseResponse => {
               return {
                    statusCode : 200,
                    success : true,
                    data : response
                }
            }
        ),
       
    );
  }
}