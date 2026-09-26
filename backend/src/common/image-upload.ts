import { BadRequestException } from '@nestjs/common';
import { MulterOptions } from '@nestjs/platform-express/multer/interfaces/multer-options.interface';
import { Request } from 'express';
import { mkdirSync } from 'fs';
import { unlink } from 'fs/promises';
import { diskStorage } from 'multer';
import { join, resolve, sep } from 'path';

/** Only raster formats we can safely serve back as static files (no SVG: it can carry script). */
const EXTENSION_BY_MIME: Record<string, string> = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
  'image/gif': '.gif',
};

export const MAX_IMAGE_BYTES = 5 * 1024 * 1024;

/** Folder served at `/uploads/` (see main.ts). Overridable so tests can use a temp dir. */
export function uploadsRoot(): string {
  return process.env.UPLOADS_DIR ?? join(process.cwd(), 'uploads');
}

/**
 * Multer options for a single image field saved under `uploads/<subdir>/`.
 * The stored name is `<prefix>-<timestamp><ext>`, where the extension comes from the
 * validated MIME type rather than the client's filename, so an upload can never be
 * served back as HTML or script.
 */
export function imageUploadOptions(subdir: string, filePrefix: (req: Request) => string): MulterOptions {
  return {
    storage: diskStorage({
      destination: (_req, _file, cb) => {
        const dir = join(uploadsRoot(), subdir);
        mkdirSync(dir, { recursive: true });
        cb(null, dir);
      },
      filename: (req, file, cb) => {
        // The prefix may come from a URL param, so strip anything that could form a path.
        const prefix = filePrefix(req).replace(/[^a-zA-Z0-9-]/g, '') || 'file';
        cb(null, `${prefix}-${Date.now()}${EXTENSION_BY_MIME[file.mimetype]}`);
      },
    }),
    fileFilter: (_req, file, cb) => {
      if (!EXTENSION_BY_MIME[file.mimetype]) {
        cb(new BadRequestException('ไฟล์ต้องเป็นรูปภาพ (JPG, PNG, WebP หรือ GIF) เท่านั้น'), false);
        return;
      }
      cb(null, true);
    },
    limits: { fileSize: MAX_IMAGE_BYTES },
  };
}

/** Public URL path for a file saved by {@link imageUploadOptions}. */
export function uploadedFileUrl(subdir: string, filename: string): string {
  return `/uploads/${subdir}/${filename}`;
}

/**
 * Best-effort delete of a previously uploaded file given its `/uploads/...` URL path.
 * The path may come from data a client once sent (e.g. `profileImageUrl` via PATCH /auth/profile),
 * so anything that resolves outside the uploads folder, like `/uploads/../data/app.sqlite`, is ignored.
 */
export function removeUploadedFile(urlPath: string): Promise<void> {
  if (!urlPath.startsWith('/uploads/')) return Promise.resolve();
  const root = resolve(uploadsRoot());
  const target = resolve(root, urlPath.slice('/uploads/'.length));
  if (!target.startsWith(root + sep)) return Promise.resolve();
  return unlink(target).catch(() => undefined);
}
