# Gunashree Digital — Full Platform Starter

Independent poster/design platform inspired by the workflow of popular template-design apps. It does not include copied proprietary code or assets.

## Included
- Flutter mobile app
- Next.js admin dashboard
- Express + TypeScript API
- PostgreSQL + Prisma
- JWT auth with ADMIN/USER roles
- Template/category APIs
- Media upload API
- User design save/read/update APIs
- Layer-based editor foundation
- Docker Compose for PostgreSQL + API

## Run API + DB
1. Install Docker Desktop.
2. Run `docker compose up --build` from this folder.
3. API: http://localhost:4000/api/health
4. Before production, set a strong JWT_SECRET and configure HTTPS/storage.

## Run Admin
`cd apps/admin && npm install && npm run dev`
Open http://localhost:3000.
Set `NEXT_PUBLIC_API_URL=http://localhost:4000` if needed.

## Run Flutter
`cd apps/mobile && flutter pub get && flutter run`
For Android emulator the API is configured as `10.0.2.2:4000`. For a physical phone replace `api` in `main.dart` with your computer's LAN IP.

## First admin user
For safety this starter does not hard-code an admin password. Create a user via `/api/auth/register`, then promote that user's role to ADMIN in PostgreSQL/Prisma before using admin-only endpoints.

## Production roadmap
- OTP login/SMS provider
- S3/Cloudflare R2 storage
- Real server-side PNG/JPG rendering (Sharp/Canvas)
- Drag/resize/rotate/snapping and layer locking
- Template field binding: {{NAME}}, {{PHOTO}}, {{LOGO}}, etc.
- Payments/subscriptions
- Push notifications
- WhatsApp sharing/deep links
- Audit logs, rate limiting, backups and monitoring

## Database setup

The Prisma schema is shared from `packages/database/prisma/schema.prisma`.
Use the explicit schema-aware scripts from `apps/api`:

```bash
npm --workspace apps/api run db:generate
npm --workspace apps/api run db:migrate
npm --workspace apps/api run seed:admin
npm --workspace apps/api run seed:demo
```

`seed:demo` creates three independent published starter templates with editable
fields for `NAME`, `BUSINESS_NAME`, `MOBILE`, `ADDRESS`, `PHOTO`, and `LOGO`.

## Replit
Use `replit.md` for the browser-based setup. After adding PostgreSQL Secrets, run:

```bash
npm install
npm run db:generate
npm run db:push
npm --workspace apps/api run seed:admin
npm run dev
```

Default admin credentials if you do not set secrets:
- Mobile: `9999999999`
- Password: `Gunashree@123`

Change them immediately for any real deployment.
