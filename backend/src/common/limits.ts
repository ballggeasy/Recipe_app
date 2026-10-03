/**
 * Upper bounds for user-supplied text, so one request can't store megabytes or burn CPU hashing
 * a huge "password". Generous for real use; only abuse hits them.
 */
export const LIMITS = {
  email: 254,
  password: 128,
  name: 100,
  shortText: 100,
  emoji: 16,
  url: 500,
  title: 200,
  line: 300,
  paragraph: 2000,
  longText: 5000,
  listItems: 100,
  imageUrls: 10,
  tags: 20,
} as const;
