# New-company payroll setup

This source template includes the Flutter frontend, Node.js API, and PostgreSQL schema. Start with a dedicated, empty PostgreSQL 16+ database. The first API start creates the administrator from the credentials you supply. Employee, branch, attendance, and payroll records can be imported later.

## Set company identity

Install Python 3 and Pillow (`python -m pip install Pillow`). Edit `setup/company.json`, place your logo in the setup folder, and run this command from the project root.

```sh
python setup/configure.py setup/company.json
```

The script applies one company profile to source labels and shared logo files. Rebuild the frontend and restart or redeploy the backend after applying it. Keep a fresh copy of the template for another company or branding change. Native application identifiers and the layout of legacy workbooks are inherited from the source.

## Set up PostgreSQL and the API

1. Create a dedicated database with a role that owns the database and can provision the API's PostgreSQL roles. Run the following once against that empty database. On Windows, use PowerShell and quote the connection string.

   ```sh
   psql "<new database connection string>" -f setup/bootstrap.sql
   ```

2. Copy `backend/.env.example` to `backend/.env`. Set `DATABASE_URL` to the new database connection string, `PORT=5000`, `FRONTEND_URL=http://localhost:3000`, a unique random `JWT_SECRET`, `ADMIN_EMAIL`, and `ADMIN_PASSWORD` (at least 12 characters). Keep the environment file private.
3. From the repository root, use Node.js 22.12+ or 24 and run:

   ```sh
   cd backend
   npm ci
   npm run db:generate
   npm start
   ```

   Startup applies the API migrations and creates the administrator. Sign in using the configured email and password.

## Run or deploy the frontend

Install Flutter and Chrome, then run from the repository root.

```sh
flutter pub get
flutter run -d chrome --web-port=3000 --dart-define=API_BASE_URL=http://localhost:5000
```

For deployment, set `FRONTEND_URL` to the deployed web origin, configure email delivery in the backend environment, and build the frontend with `flutter build web --release --dart-define=API_BASE_URL=https://your-api.example.com`. Host the resulting `build/web` folder.

For push notifications, register the new company’s app with Firebase, generate its own `lib/firebase_options.dart`, and install its web messaging service worker or native configuration. Set the matching backend `FIREBASE_PROJECT_ID` and service account, supply the web VAPID key where applicable, and build with `--dart-define=ENABLE_FIREBASE=true`. The backend notification inbox uses PostgreSQL.

## Import data later

Create or import branches first, then employees and salary defaults, then dependent records such as attendance and historical payroll. Use the new company’s identifiers and valid foreign-key references. Set up accounts and passwords for your imported users separately. Test imports in a staging database before loading live payroll.

The base schema comes from the repository’s schema-only test fixture, with the payroll lock trigger and startup migrations applied on top. Legacy salary export layouts and original branch conventions still need validation with your branch names. Flutter and a live database startup were unavailable for verification in this workspace.
