// Runs before each e2e test file is loaded, so AppModule and AuthModule read these
// values instead of touching the developer's real ./data/app.sqlite.
process.env.DB_PATH = ':memory:';
process.env.JWT_SECRET = 'e2e-test-secret';
