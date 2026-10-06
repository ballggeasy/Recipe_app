import { BadRequestException } from '@nestjs/common';
import { MulterOptions } from '@nestjs/platform-express/multer/interfaces/multer-options.interface';
import { Request } from 'express';
import { mkdirSync } from 'fs';
import { unlink } from 'fs/promises';
import { diskStorage } from 'multer';
import { join, resolve, sep } from 'path';

/**
 * Only raster formats we can safely serve back as static files (no SVG: it can carry script).
 * A Map, not an object literal: a lookup like `obj['constructor']` would find Object's own
 * properties, so a client sending `Content-Type: constructor` used to pass the filter.
 */
const EXTENSION_BY_MIME = new Map<string, string>([
  ['image/jpeg', '.jpg'],
  ['image/png', '.png'],
  ['image/webp', '.webp'],
  ['image/gif', '.gif'],
]);

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
        cb(null, `${prefix}-${Date.now()}${EXTENSION_BY_MIME.get(file.mimetype)}`);
      },
    }),
    fileFilter: (_req, file, cb) => {
      if (!EXTENSION_BY_MIME.has(file.mimetype)) {
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
 * Disk path of a file saved under the uploads folder, given its `/uploads/...` URL path, or null.
 * The path may come from data a client once sent (e.g. `profileImageUrl` via PATCH /auth/profile),
 * so anything that resolves outside the uploads folder, like `/uploads/../data/app.sqlite`, is null.
 */
export function uploadedFilePath(urlPath: string): string | null {
  if (!urlPath.startsWith('/uploads/')) return null;
  const root = resolve(uploadsRoot());
  const target = resolve(root, urlPath.slice('/uploads/'.length));
  return target.startsWith(root + sep) ? target : null;
}

/** Best-effort delete of a previously uploaded file given its `/uploads/...` URL path (see {@link uploadedFilePath}). */
export function removeUploadedFile(urlPath: string): Promise<void> {
  const target = uploadedFilePath(urlPath);
  if (!target) return Promise.resolve();
  return unlink(target).catch(() => undefined);
}
