export type ApiError = {
    code : string | number,
    message : string
}

interface successResponse {
    statusCode : number,
    success : boolean,
    data : unknown
}

interface errorResponse {
    statusCode : number,
    success : boolean,
    error : ApiError
}

export type baseResponse =  successResponse | errorResponse