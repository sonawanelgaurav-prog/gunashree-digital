# Gunashree Digital — Replit Setup

## Run
1. Create a Replit Node.js workspace.
2. Upload/import this ZIP.
3. Add a PostgreSQL database in Replit and copy its `DATABASE_URL` into Secrets.
4. Add `JWT_SECRET` in Secrets.
5. Run `npm install`.
6. Run `npm run db:generate` and `npm run db:push`.
7. Run `npm run dev`.
8. Open port 3000 for the Admin Dashboard.

The API runs on port 4000 and the Next.js dashboard is configured to proxy `/api/*` and `/uploads/*` to it.

## Important
The Flutter Android app is under `apps/mobile`. Replit is used here for the web/admin/backend side. To generate the final Android APK, use Flutter tooling or a cloud Android build service after the mobile app is finalized.
