import { ArgumentsHost, BadRequestException, ForbiddenException, Logger } from '@nestjs/common';
import { AllExceptionsFilter } from '../src/common/all-exceptions.filter';

function buildHost() {
  const json = jest.fn();
  const res = { locals: { requestId: 'req-1' }, status: jest.fn().mockReturnThis(), json };
  const req = { method: 'GET', originalUrl: '/recipes/1?token=secret' };
  const host = { switchToHttp: () => ({ getResponse: () => res, getRequest: () => req }) } as unknown as ArgumentsHost;
  return { host, res, json };
}

describe('AllExceptionsFilter', () => {
  let errorSpy: jest.SpyInstance;

  beforeEach(() => {
    errorSpy = jest.spyOn(Logger.prototype, 'error').mockImplementation(() => undefined);
  });
  afterEach(() => jest.restoreAllMocks());

  it('keeps status and message of HTTP exceptions and strips the query string from the path', () => {
    const { host, res, json } = buildHost();

    new AllExceptionsFilter().catch(new ForbiddenException('ลบได้เฉพาะสูตรที่คุณอัปโหลดเอง'), host);

    expect(res.status).toHaveBeenCalledWith(403);
    expect(json.mock.calls[0][0]).toMatchObject({
      statusCode: 403,
      error: 'Forbidden',
      message: 'ลบได้เฉพาะสูตรที่คุณอัปโหลดเอง',
      requestId: 'req-1',
      path: '/recipes/1',
    });
    expect(errorSpy).not.toHaveBeenCalled();
  });

  it('passes validation message lists through', () => {
    const { host, json } = buildHost();

    new AllExceptionsFilter().catch(new BadRequestException(['name must be a string', 'email must be an email']), host);

    expect(json.mock.calls[0][0].message).toEqual(['name must be a string', 'email must be an email']);
  });

  it('hides the details of unexpected errors from the client but logs them with the request id', () => {
    const { host, res, json } = buildHost();
    const secretFailure = new Error('SQLITE_ERROR: no such table: users (password=hunter2)');

    new AllExceptionsFilter().catch(secretFailure, host);

    expect(res.status).toHaveBeenCalledWith(500);
    const body = json.mock.calls[0][0];
    expect(body).toMatchObject({ statusCode: 500, error: 'Internal Server Error', message: 'Internal server error' });
    expect(JSON.stringify(body)).not.toContain('SQLITE');
    expect(JSON.stringify(body)).not.toContain('hunter2');
    expect(errorSpy).toHaveBeenCalledTimes(1);
    expect(errorSpy.mock.calls[0][0]).toContain('requestId=req-1');
    expect(errorSpy.mock.calls[0][1]).toContain('SQLITE_ERROR');
  });
});
