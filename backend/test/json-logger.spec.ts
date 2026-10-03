import { JsonLogger } from '../src/common/json-logger';

describe('JsonLogger', () => {
  let stdout: jest.SpyInstance;
  let stderr: jest.SpyInstance;
  const lastLine = (spy: jest.SpyInstance) => JSON.parse(String(spy.mock.calls.at(-1)?.[0]));

  beforeEach(() => {
    stdout = jest.spyOn(process.stdout, 'write').mockReturnValue(true);
    stderr = jest.spyOn(process.stderr, 'write').mockReturnValue(true);
  });
  afterEach(() => jest.restoreAllMocks());

  it('writes one JSON object per line with level and context', () => {
    new JsonLogger().log('Backend listening', 'Bootstrap');

    expect(String(stdout.mock.calls[0][0]).endsWith('\n')).toBe(true);
    expect(lastLine(stdout)).toMatchObject({ level: 'log', context: 'Bootstrap', message: 'Backend listening' });
  });

  it('turns a structured message into top-level fields', () => {
    new JsonLogger().log({ requestId: 'r1', status: 200 }, 'HTTP');

    expect(lastLine(stdout)).toMatchObject({ context: 'HTTP', requestId: 'r1', status: 200 });
    expect(lastLine(stdout)).not.toHaveProperty('message');
  });

  it('sends errors to stderr and keeps the stack as detail', () => {
    new JsonLogger().error('failed', 'Error: boom\n    at x', 'Exceptions');

    expect(stdout).not.toHaveBeenCalled();
    expect(lastLine(stderr)).toMatchObject({
      level: 'error',
      context: 'Exceptions',
      message: 'failed',
      detail: ['Error: boom\n    at x'],
    });
  });
});
