import express, { type NextFunction, type Request, type Response } from 'express';
import cors from 'cors';
import path from 'path';
import fs from 'fs';
import { randomUUID } from 'crypto';
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import multer from 'multer';

const prisma = new PrismaClient();
const app = express();
const port = Number(process.env.PORT || 4000);
const secret = process.env.JWT_SECRET || 'dev-secret';
const maxUploadBytes = 15 * 1024 * 1024;
const editableFields = [
  'PHOTO',
  'LOGO',
  'NAME',
  'BUSINESS_NAME',
  'MOBILE',
  'ADDRESS',
  'CUSTOM_TEXT',
] as const;
const templateStatuses = ['DRAFT', 'PUBLISHED', 'ARCHIVED'] as const;

type EditableField = (typeof editableFields)[number];
type TemplateStatus = (typeof templateStatuses)[number];
type AuthUser = { id: string; role: 'ADMIN' | 'USER' };

declare global {
  namespace Express {
    interface Request {
      user?: AuthUser;
    }
  }
}

app.use(cors({ origin: true, credentials: true }));
app.use(express.json({ limit: '10mb' }));

const uploadDir = process.env.UPLOAD_DIR || path.join(process.cwd(), 'uploads');
fs.mkdirSync(uploadDir, { recursive: true });
app.use('/uploads', express.static(uploadDir));

const upload = multer({
  storage: multer.diskStorage({
    destination: uploadDir,
    filename: (_req, file, callback) => {
      const extension = path.extname(file.originalname).toLowerCase().slice(0, 10);
      callback(null, `${randomUUID()}${extension}`);
    },
  }),
  limits: { fileSize: maxUploadBytes },
  fileFilter: (_req, file, callback) => {
    callback(null, /^image\/(png|jpe?g|webp|gif)$/i.test(file.mimetype));
  },
});

function publicUser(user: { id: string; name: string; phone: string; role: string }) {
  return { id: user.id, name: user.name, phone: user.phone, role: user.role };
}

function createToken(user: { id: string; role: string }) {
  return jwt.sign({ id: user.id, role: user.role }, secret, { expiresIn: '7d' });
}

function readToken(req: Request): AuthUser | null {
  const header = req.headers.authorization || '';
  if (!header.startsWith('Bearer ')) return null;
  try {
    const payload = jwt.verify(header.slice('Bearer '.length), secret);
    if (typeof payload !== 'object' || !payload.id || !payload.role) return null;
    return { id: String(payload.id), role: payload.role === 'ADMIN' ? 'ADMIN' : 'USER' };
  } catch {
    return null;
  }
}

function auth(req: Request, res: Response, next: NextFunction) {
  const user = readToken(req);
  if (!user) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }
  req.user = user;
  next();
}

function adminOnly(req: Request, res: Response, next: NextFunction) {
  if (req.user?.role !== 'ADMIN') {
    res.status(403).json({ error: 'Admin access required' });
    return;
  }
  next();
}

function slugify(value: string) {
  return value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function toPositiveInt(value: unknown, fallback: number) {
  const parsed = Number(value);
  return Number.isInteger(parsed) && parsed > 0 ? parsed : fallback;
}

function dimensionsForCanvas(value: unknown) {
  if (value === '1:1') return { width: 1080, height: 1080 };
  if (value === '4:5') return { width: 1080, height: 1350 };
  if (value === '9:16') return { width: 1080, height: 1920 };
  return null;
}

function cleanFields(value: unknown): EditableField[] {
  let values = value;
  if (typeof values === 'string') {
    try {
      values = JSON.parse(values);
    } catch {
      values = values.split(',');
    }
  }
  if (!Array.isArray(values)) return ['NAME', 'BUSINESS_NAME', 'MOBILE', 'ADDRESS', 'PHOTO', 'LOGO'];
  const result = values.filter((field): field is EditableField =>
    editableFields.includes(String(field) as EditableField),
  );
  return Array.from(new Set(result));
}

function parseJsonObject(value: unknown): Record<string, any> {
  if (typeof value === 'string') {
    try {
      value = JSON.parse(value);
    } catch {
      return {};
    }
  }
  return value && typeof value === 'object' && !Array.isArray(value)
    ? value as Record<string, any>
    : {};
}

function defaultLayers(fields: EditableField[], width: number, height: number) {
  const layers: Record<string, any>[] = [];
  const textFields = fields.filter((field) => !['PHOTO', 'LOGO'].includes(field));
  textFields.forEach((field, index) => {
    layers.push({
      id: field.toLowerCase(),
      type: 'text',
      field,
      text: `{{${field}}}`,
      x: 70,
      y: Math.min(80 + index * 110, Math.max(80, height - 120)),
      width: width - 140,
      height: 90,
      fontSize: field === 'CUSTOM_TEXT' ? 42 : 48,
      color: '#17132B',
    });
  });
  fields.filter((field) => field === 'PHOTO' || field === 'LOGO').forEach((field, index) => {
    layers.push({
      id: field.toLowerCase(),
      type: 'image',
      field,
      src: '',
      x: 90 + index * 40,
      y: Math.min(300 + index * 80, Math.max(120, height - 500)),
      width: Math.min(520, width - 180),
      height: field === 'LOGO' ? 180 : 420,
    });
  });
  return layers;
}

function buildTemplateSchema(body: Record<string, any>, width: number, height: number) {
  const fields = cleanFields(body.fields ?? parseJsonObject(body.schema).fields);
  const incoming = parseJsonObject(body.schema);
  const layers = Array.isArray(incoming.layers) && incoming.layers.length > 0
    ? incoming.layers
    : defaultLayers(fields, width, height);
  return {
    version: 1,
    ...incoming,
    fields,
    layers,
    background: typeof incoming.background === 'string' ? incoming.background : '#FFF8F1',
  };
}

function fileUrl(filename: string) {
  return `/uploads/${filename}`;
}

async function createMediaRecord(input: {
  filename: string;
  url: string;
  storagePath?: string | null;
  mimeType: string;
  size: number;
}) {
  return prisma.media.create({
    data: {
      filename: input.filename,
      url: input.url,
      storagePath: input.storagePath || null,
      mimeType: input.mimeType,
      size: input.size,
    },
  });
}

function privateObjectDir() {
  return (process.env.PRIVATE_OBJECT_DIR || '').replace(/\/+$/, '');
}

function objectPathToUrl(objectPath: string) {
  return `/api/storage/objects/${objectPath.replace(/^\/objects\//, '')}`;
}

function storageLocation(objectPath: string) {
  const dir = privateObjectDir();
  if (!dir || !objectPath.startsWith('/objects/')) return null;
  const parts = `${dir}${objectPath.slice('/objects'.length)}`.split('/').filter(Boolean);
  if (parts.length < 2) return null;
  return { bucketName: parts[0], objectName: parts.slice(1).join('/') };
}

async function signStorageUrl(
  objectPath: string,
  method: 'GET' | 'PUT',
) {
  const location = storageLocation(objectPath);
  if (!location) throw new Error('Object storage is not configured');
  const response = await fetch('http://127.0.0.1:1106/object-storage/signed-object-url', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      bucket_name: location.bucketName,
      object_name: location.objectName,
      method,
      expires_at: new Date(Date.now() + 15 * 60 * 1000).toISOString(),
    }),
  });
  if (!response.ok) throw new Error(`Unable to sign storage URL (${response.status})`);
  const data = await response.json() as { signed_url?: string };
  if (!data.signed_url) throw new Error('Storage signer returned no URL');
  return data.signed_url;
}

app.get('/api/health', (_req, res) => res.json({ ok: true, app: 'Gunashree Digital' }));

async function loginUser(req: Request, res: Response, adminRequired: boolean) {
  const { phone, password } = req.body || {};
  if (!phone || !password) {
    res.status(400).json({ error: 'Phone and password are required' });
    return;
  }
  const user = await prisma.user.findUnique({ where: { phone: String(phone).trim() } });
  if (!user?.passwordHash || !(await bcrypt.compare(String(password), user.passwordHash))) {
    res.status(401).json({ error: 'Invalid credentials' });
    return;
  }
  if (adminRequired && user.role !== 'ADMIN') {
    res.status(403).json({ error: 'Admin access required' });
    return;
  }
  res.json({ token: createToken(user), user: publicUser(user) });
}

app.post('/api/auth/register', async (req, res) => {
  try {
    const { name, phone, password, email } = req.body || {};
    if (!name || !phone || !password) {
      res.status(400).json({ error: 'Name, phone and password are required' });
      return;
    }
    const user = await prisma.user.create({
      data: {
        name: String(name).trim(),
        phone: String(phone).trim(),
        email: email ? String(email).trim() : undefined,
        passwordHash: await bcrypt.hash(String(password), 10),
      },
    });
    res.json({ token: createToken(user), user: publicUser(user) });
  } catch (error: any) {
    res.status(error?.code === 'P2002' ? 409 : 500).json({
      error: error?.code === 'P2002' ? 'Phone or email already registered' : 'Registration failed',
    });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    await loginUser(req, res, false);
  } catch {
    res.status(500).json({ error: 'Login failed' });
  }
});

app.post('/api/admin/login', async (req, res) => {
  try {
    await loginUser(req, res, true);
  } catch {
    res.status(500).json({ error: 'Admin login failed' });
  }
});

app.get('/api/auth/me', auth, async (req, res) => {
  const user = await prisma.user.findUnique({
    where: { id: req.user!.id },
    select: { id: true, name: true, phone: true, role: true },
  });
  if (!user) {
    res.status(401).json({ error: 'Session expired' });
    return;
  }
  res.json({ user });
});

app.get('/api/categories', async (req, res) => {
  const all = req.query.all === '1' || req.query.includeInactive === 'true';
  if (all) {
    const user = readToken(req);
    if (user?.role !== 'ADMIN') {
      res.status(401).json({ error: 'Admin access required' });
      return;
    }
  }
  res.json(await prisma.category.findMany({
    where: all ? {} : { isActive: true },
    include: { _count: { select: { templates: true } } },
    orderBy: { name: 'asc' },
  }));
});

app.post('/api/categories', auth, adminOnly, async (req, res) => {
  const name = String(req.body?.name || '').trim();
  const slug = slugify(String(req.body?.slug || name));
  if (!name || !slug) {
    res.status(400).json({ error: 'Category name is required' });
    return;
  }
  try {
    const category = await prisma.category.create({
      data: { name, slug, coverUrl: req.body?.coverUrl || null, isActive: req.body?.isActive !== false },
      include: { _count: { select: { templates: true } } },
    });
    res.status(201).json(category);
  } catch (error: any) {
    res.status(error?.code === 'P2002' ? 409 : 500).json({
      error: error?.code === 'P2002' ? 'A category with this slug already exists' : 'Unable to create category',
    });
  }
});

app.patch('/api/categories/:id', auth, adminOnly, async (req, res) => {
  const data: Record<string, any> = {};
  if (req.body?.name !== undefined) {
    const name = String(req.body.name).trim();
    if (!name) {
      res.status(400).json({ error: 'Category name cannot be empty' });
      return;
    }
    data.name = name;
  }
  if (req.body?.slug !== undefined) data.slug = slugify(String(req.body.slug));
  if (req.body?.coverUrl !== undefined) data.coverUrl = req.body.coverUrl || null;
  if (req.body?.isActive !== undefined) data.isActive = Boolean(req.body.isActive);
  try {
    res.json(await prisma.category.update({
      where: { id: req.params.id },
      data,
      include: { _count: { select: { templates: true } } },
    }));
  } catch (error: any) {
    res.status(error?.code === 'P2025' ? 404 : error?.code === 'P2002' ? 409 : 500).json({
      error: error?.code === 'P2025' ? 'Category not found' : 'Unable to update category',
    });
  }
});

app.delete('/api/categories/:id', auth, adminOnly, async (req, res) => {
  try {
    await prisma.$transaction([
      prisma.template.updateMany({ where: { categoryId: req.params.id }, data: { categoryId: null } }),
      prisma.category.delete({ where: { id: req.params.id } }),
    ]);
    res.sendStatus(204);
  } catch (error: any) {
    res.status(error?.code === 'P2025' ? 404 : 500).json({ error: 'Unable to delete category' });
  }
});

app.get('/api/templates', async (req, res) => {
  const requested = String(req.query.status || 'PUBLISHED');
  if (requested === 'ALL') {
    const user = readToken(req);
    if (user?.role !== 'ADMIN') {
      res.status(401).json({ error: 'Admin access required' });
      return;
    }
  }
  const status = requested === 'ALL' ? undefined : templateStatuses.includes(requested as TemplateStatus)
    ? requested as TemplateStatus
    : 'PUBLISHED';
  res.json(await prisma.template.findMany({
    where: status ? { status } : {},
    include: { category: true },
    orderBy: { updatedAt: 'desc' },
  }));
});

const templateUpload = upload.fields([
  { name: 'template', maxCount: 1 },
  { name: 'preview', maxCount: 1 },
]);

app.post('/api/templates', auth, adminOnly, templateUpload, async (req, res) => {
  const body = req.body as Record<string, any>;
  const title = String(body.title || '').trim();
  const slug = slugify(String(body.slug || title));
  if (!title || !slug) {
    res.status(400).json({ error: 'Template title and slug are required' });
    return;
  }
  const dimensions = dimensionsForCanvas(body.canvasSize);
  const width = dimensions?.width || toPositiveInt(body.width, 1080);
  const height = dimensions?.height || toPositiveInt(body.height, 1350);
  const fields = cleanFields(body.fields);
  const status = templateStatuses.includes(body.status as TemplateStatus)
    ? body.status as TemplateStatus
    : 'DRAFT';
  const files = (req.files || {}) as { [fieldname: string]: Express.Multer.File[] };
  const templateFile = files.template?.[0];
  const previewFile = files.preview?.[0];
  try {
    const templateMedia = templateFile
      ? await createMediaRecord({
          filename: templateFile.originalname,
          url: fileUrl(templateFile.filename),
          mimeType: templateFile.mimetype,
          size: templateFile.size,
        })
      : null;
    const previewMedia = previewFile
      ? await createMediaRecord({
          filename: previewFile.originalname,
          url: fileUrl(previewFile.filename),
          mimeType: previewFile.mimetype,
          size: previewFile.size,
        })
      : null;
    const schema = buildTemplateSchema({ ...body, fields }, width, height);
    const template = await prisma.template.create({
      data: {
        title,
        slug,
        thumbnailUrl: body.thumbnailUrl || previewMedia?.url || null,
        backgroundUrl: body.backgroundUrl || templateMedia?.url || null,
        width,
        height,
        status,
        categoryId: body.categoryId || null,
        schema,
      },
      include: { category: true },
    });
    res.status(201).json(template);
  } catch (error: any) {
    res.status(error?.code === 'P2002' ? 409 : 500).json({
      error: error?.code === 'P2002' ? 'A template with this slug already exists' : 'Unable to create template',
    });
  }
});

app.patch('/api/templates/:id', auth, adminOnly, templateUpload, async (req, res) => {
  const body = req.body as Record<string, any>;
  const dimensions = dimensionsForCanvas(body.canvasSize);
  const data: Record<string, any> = {};
  if (body.title !== undefined) data.title = String(body.title).trim();
  if (body.slug !== undefined) data.slug = slugify(String(body.slug));
  if (body.categoryId !== undefined) data.categoryId = body.categoryId || null;
  if (body.status !== undefined && templateStatuses.includes(body.status as TemplateStatus)) data.status = body.status;
  if (dimensions) {
    data.width = dimensions.width;
    data.height = dimensions.height;
  } else {
    if (body.width !== undefined) data.width = toPositiveInt(body.width, 1080);
    if (body.height !== undefined) data.height = toPositiveInt(body.height, 1350);
  }
  if (body.fields !== undefined || body.schema !== undefined) {
    const width = data.width || 1080;
    const height = data.height || 1350;
    data.schema = buildTemplateSchema({ ...body, fields: body.fields ?? parseJsonObject(body.schema).fields }, width, height);
  }
  const files = (req.files || {}) as { [fieldname: string]: Express.Multer.File[] };
  const templateFile = files.template?.[0];
  const previewFile = files.preview?.[0];
  try {
    if (templateFile) {
      const media = await createMediaRecord({
        filename: templateFile.originalname,
        url: fileUrl(templateFile.filename),
        mimeType: templateFile.mimetype,
        size: templateFile.size,
      });
      data.backgroundUrl = media.url;
    } else if (body.backgroundUrl !== undefined) data.backgroundUrl = body.backgroundUrl || null;
    if (previewFile) {
      const media = await createMediaRecord({
        filename: previewFile.originalname,
        url: fileUrl(previewFile.filename),
        mimeType: previewFile.mimetype,
        size: previewFile.size,
      });
      data.thumbnailUrl = media.url;
    } else if (body.thumbnailUrl !== undefined) data.thumbnailUrl = body.thumbnailUrl || null;
    res.json(await prisma.template.update({
      where: { id: req.params.id },
      data,
      include: { category: true },
    }));
  } catch (error: any) {
    res.status(error?.code === 'P2025' ? 404 : error?.code === 'P2002' ? 409 : 500).json({
      error: error?.code === 'P2025' ? 'Template not found' : 'Unable to update template',
    });
  }
});

app.delete('/api/templates/:id', auth, adminOnly, async (req, res) => {
  try {
    await prisma.template.delete({ where: { id: req.params.id } });
    res.sendStatus(204);
  } catch (error: any) {
    res.status(error?.code === 'P2025' ? 404 : 500).json({ error: 'Unable to delete template' });
  }
});

app.post('/api/storage/uploads/request-url', auth, adminOnly, async (req, res) => {
  const size = Number(req.body?.size);
  const name = String(req.body?.name || '').trim();
  const contentType = String(req.body?.contentType || '').toLowerCase();
  if (!name || !Number.isInteger(size) || size < 1 || size > maxUploadBytes || !contentType.startsWith('image/')) {
    res.status(400).json({ error: 'Only image files up to 15 MB are supported' });
    return;
  }
  try {
    const objectPath = `/objects/uploads/${randomUUID()}`;
    const uploadURL = await signStorageUrl(objectPath, 'PUT');
    res.json({
      uploadURL,
      objectPath,
      url: objectPathToUrl(objectPath),
      metadata: { name, size, contentType },
    });
  } catch {
    res.status(503).json({ error: 'Persistent object storage is unavailable' });
  }
});

app.use('/api/storage/objects', async (req, res, next) => {
  if (req.method !== 'GET') {
    next();
    return;
  }
  const relativePath = req.path.replace(/^\/+/, '');
  if (!relativePath) {
    res.sendStatus(404);
    return;
  }
  try {
    const upstream = await fetch(await signStorageUrl(`/objects/${relativePath}`, 'GET'));
    const contentType = upstream.headers.get('content-type') || 'application/octet-stream';
    const body = Buffer.from(await upstream.arrayBuffer());
    res.status(upstream.status).set({
      'Content-Type': contentType,
      'Cache-Control': 'public, max-age=3600',
    }).send(body);
  } catch {
    res.status(404).json({ error: 'Object not found' });
  }
});

app.post('/api/media', auth, adminOnly, upload.single('file'), async (req, res) => {
  try {
    if (req.file) {
      res.status(201).json(await createMediaRecord({
        filename: req.file.originalname,
        url: fileUrl(req.file.filename),
        mimeType: req.file.mimetype,
        size: req.file.size,
      }));
      return;
    }
    const { filename, url, storagePath, mimeType, size } = req.body || {};
    if (!filename || !url || !mimeType || !Number(size)) {
      res.status(400).json({ error: 'filename, url, mimeType and size are required' });
      return;
    }
    res.status(201).json(await createMediaRecord({
      filename: String(filename),
      url: String(url),
      storagePath: storagePath ? String(storagePath) : null,
      mimeType: String(mimeType),
      size: Number(size),
    }));
  } catch {
    res.status(500).json({ error: 'Unable to store media' });
  }
});

app.get('/api/media', auth, adminOnly, async (_req, res) => {
  res.json(await prisma.media.findMany({ orderBy: { createdAt: 'desc' } }));
});

app.post('/api/designs', auth, async (req, res) => {
  const design = await prisma.design.create({
    data: {
      name: req.body?.name || 'Untitled Design',
      data: req.body?.data || {},
      templateId: req.body?.templateId || null,
      userId: req.user!.id,
    },
  });
  res.status(201).json(design);
});

app.get('/api/designs', auth, async (req, res) => {
  const where = req.user!.role === 'ADMIN' && req.query.all ? {} : { userId: req.user!.id };
  res.json(await prisma.design.findMany({
    where,
    include: { template: true, user: { select: { name: true, phone: true } } },
    orderBy: { updatedAt: 'desc' },
  }));
});

app.patch('/api/designs/:id', auth, async (req, res) => {
  const design = await prisma.design.findUnique({ where: { id: req.params.id } });
  if (!design || (req.user!.role !== 'ADMIN' && design.userId !== req.user!.id)) {
    res.status(403).json({ error: 'Forbidden' });
    return;
  }
  res.json(await prisma.design.update({
    where: { id: design.id },
    data: { name: req.body?.name, data: req.body?.data, outputUrl: req.body?.outputUrl },
  }));
});

app.get('/api/admin/stats', auth, adminOnly, async (_req, res) => {
  const [users, templates, publishedTemplates, draftTemplates, designs, media, activeCategories, recentTemplates] =
    await Promise.all([
      prisma.user.count(),
      prisma.template.count(),
      prisma.template.count({ where: { status: 'PUBLISHED' } }),
      prisma.template.count({ where: { status: 'DRAFT' } }),
      prisma.design.count(),
      prisma.media.count(),
      prisma.category.count({ where: { isActive: true } }),
      prisma.template.findMany({
        take: 5,
        orderBy: { updatedAt: 'desc' },
        select: { id: true, title: true, status: true, updatedAt: true },
      }),
    ]);
  res.json({
    users,
    templates,
    publishedTemplates,
    draftTemplates,
    designs,
    media,
    activeCategories,
    recentTemplates,
  });
});

app.listen(port, () => console.log(`Gunashree Digital API running on :${port}`));