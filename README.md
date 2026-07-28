# GLAM Rider Onboarding System

Ye project ek internal backend system hai jo GLAM company ke delivery riders ke onboarding process ko manage karta hai. Iska kaam ye hai ki jab koi naya rider join karta hai, toh uska poora process track ho sake, documents verify ho sake, background check ho sake, aur finally wo live ho sake. Abhi is project mein sirf backend API aur admin dashboard hai, rider ke liye koi mobile app ya website nahi bani hai. Toh rider ka kaam ke saare steps admin ke through ya directly API se test ho sakte hain.

---

## Project Structure

```
glam-backend/
├── server.js              - App ka entry point, Express server yahan start hota hai
├── schema.sql             - Database ka poora structure, tables aur seed data
├── .env                   - Sensitive config jo git mein nahi jaati
├── .env.example           - .env ka template, isme dummy values hain copy krke fill karo
├── uploads/               - Dev mode mein documents yahan local disk pr save hote hain
├── logs/                  - HTTP request logs Morgan se auto-save hote hain
├── scripts/               - Utility scripts (admin banana, etc.)
├── samples/               - Sample CSV files bulk upload test karne ke liye
├── glam-admin/            - React Admin Dashboard (Frontend)
│   └── src/
│       ├── pages/         - Dashboard, Riders, BgvQueue, BulkUpload, Clients, Payouts
│       ├── components/    - Sidebar, Header, Loader, Toast reusable components
│       ├── api/           - Backend se baat karne wale axios functions
│       └── context/       - AuthContext (login state), ToastContext (notifications)
└── src/                   - Backend core code
    ├── config/db.js       - MySQL connection pool
    ├── routes/            - URL paths aur unka controller se mapping
    ├── controllers/       - Request handle karte hain, response bhejte hain
    ├── services/          - Business logic yahan rehti hai
    ├── repositories/      - Database queries sirf yahan hoti hain
    ├── models/            - Joi validation schemas for request body
    ├── middleware/        - auth.js, upload.js, rateLimiter.js, errorHandler.js
    └── utils/             - ApiError, ApiResponse, Logger helpers
```

---

## Database Tables

### tb_admins

Ye table admin users ke liye hai jo dashboard use karte hain.

| Column | Type | Description |
|--------|------|-------------|
| id | INT AUTO_INCREMENT | Primary key |
| name | VARCHAR(100) | Admin ka naam |
| email | VARCHAR(150) | Login email, unique |
| password_hash | VARCHAR(255) | bcrypt se encrypted password |
| role | ENUM | super_admin, ops, retention |
| is_active | TINYINT(1) | 1 = active, 0 = deactivated |
| created_at | TIMESTAMP | Account creation time |
| updated_at | TIMESTAMP | Last update time |

Role permissions:
- super_admin: sab kuch dekh aur kar sakta hai
- ops: riders, BGV, documents sab manage kar sakta hai
- retention: sirf read-only, riders dekh sakta hai

---

### tb_clients

Ye table partner companies ke liye hai jahan riders deliver karte hain. Seed data already insert hai.

| Column | Type | Description |
|--------|------|-------------|
| id | INT AUTO_INCREMENT | Primary key |
| name | VARCHAR(100) | Company name, jaise Flipkart Minutes |
| code | VARCHAR(20) | Short identifier, jaise FKM, ZEPTO, BLINKIT |
| description | TEXT | Company ka description |
| rate_per_order | DECIMAL(8,2) | Ek delivery par kitna milega |
| avg_daily_earning | DECIMAL(8,2) | Average daily earning estimate |
| payout_cycle | ENUM | weekly ya fortnightly |
| bgv_owner | ENUM | glam ya client, kaun BGV karta hai |
| is_active | TINYINT(1) | Active client hai ya nahi |

Already 3 clients hain: Flipkart Minutes (FKM), Zepto (ZEPTO), Blinkit (BLINKIT).

---

### tb_riders

Ye is poore project ki main table hai. Har ek rider ka record yahan hai.

| Column | Type | Description |
|--------|------|-------------|
| id | VARCHAR(36) | UUID primary key, auto generate hota hai |
| full_name | VARCHAR(150) | Rider ka poora naam |
| phone_number | VARCHAR(15) | Login ke liye unique phone number |
| gender | ENUM | male, female, other |
| city | VARCHAR(100) | Rider ki city |
| preferred_language | ENUM | hindi, english, tamil, telugu, kannada, bengali, marathi |
| selected_client_id | INT | Konsa client select kiya, foreign key tb_clients |
| glam_worker_code | VARCHAR(50) | BGV clear hone ke baad auto-generate hota hai, GLAM-WRK-XXXXXX format |
| assigned_hub_name | VARCHAR(150) | Admin ya CSV se assign hota hai |
| assigned_tl_name | VARCHAR(150) | Team Leader ka naam |
| assigned_tl_phone | VARCHAR(15) | TL ka phone number |
| onboarding_stage | ENUM | Rider ka current step in the lifecycle |
| bgv_status | ENUM | not_started, triggered, in_progress, cleared, rejected |
| is_live | TINYINT(1) | 1 agar rider live hai |

onboarding_stage ke possible values aur sequence:

```
registered -> documents_pending -> documents_submitted -> bgv_pending -> bgv_cleared -> onboarded -> live
```

Ye column kab kab change hota hai:

- registered: jab rider pehli baar register karta hai phone number se
- documents_pending: jab rider client select karta hai (ya CSV se import karte hain client ke saath)
- documents_submitted: jab rider ne saare 6 documents upload kar diye
- bgv_cleared: jab admin BGV clear karta hai par abhi koi document pending hai
- onboarded: jab BGV clear ho aur saare 6 documents approved ho jaye, is point par worker code milta hai
- live: manually admin set karta hai jab rider actually delivery shuru karta hai

---

### tb_documents

Har rider ke uploaded documents yahan store hote hain.

| Column | Type | Description |
|--------|------|-------------|
| id | VARCHAR(36) | UUID primary key |
| rider_id | VARCHAR(36) | Kis rider ka document hai, foreign key tb_riders |
| document_type | ENUM | aadhaar, pan, vehicle_rc, driving_licence, bank_passbook, selfie |
| file_path | VARCHAR(500) | Dev mein local path, production mein Cloudinary URL |
| file_name | VARCHAR(255) | Original file naam |
| mime_type | VARCHAR(100) | image/jpeg, application/pdf, etc. |
| status | ENUM | pending, local_check_passed, verifying, approved, rejected |
| rejection_reason | VARCHAR(500) | Agar reject kiya toh kyun |
| document_number | VARCHAR(50) | Aadhaar number ya PAN number admin note kar sakta hai |
| uploaded_at | TIMESTAMP | Upload ka time |
| verified_at | TIMESTAMP | Admin ne kab verify kiya |

Saare 6 documents required hain: aadhaar, pan, vehicle_rc, driving_licence, bank_passbook, selfie. Jab tak sab upload nahi hote, stage documents_submitted nahi hogi. Ek rider ek type ka ek document rakh sakta hai.

---

### tb_bgv

Background Verification ke records yahan hain.

| Column | Type | Description |
|--------|------|-------------|
| id | INT AUTO_INCREMENT | Primary key |
| rider_id | VARCHAR(36) | Kis rider ka BGV hai |
| client_id | INT | Konse client ke liye BGV hai |
| bgv_owner | ENUM | glam ya client, depends on tb_clients.bgv_owner |
| status | ENUM | triggered, in_progress, cleared, rejected |
| triggered_at | TIMESTAMP | BGV kab shuru hua |
| cleared_at | TIMESTAMP | BGV kab clear hua |
| verified_at | TIMESTAMP | Verification timestamp |
| rejection_reason | TEXT | Reject kyun kiya |
| remarks | TEXT | Admin ka optional note |

Jab rider client select karta hai, ek BGV record automatically create ho jata hai triggered status ke saath. Admin BGV Queue mein sirf wahi records dikhte hain jinmein bgv_owner = 'glam' hai aur status triggered ya in_progress hai.

---

### tb_notifications

Riders ko bheje gaye notifications yahan log hote hain.

| Column | Type | Description |
|--------|------|-------------|
| id | INT AUTO_INCREMENT | Primary key |
| rider_id | VARCHAR(36) | Kis rider ko notification |
| type | ENUM | bgv_started, bgv_cleared, onboarding_complete, document_rejected, etc. |
| channel | ENUM | push, whatsapp, sms |
| status | ENUM | pending, sent, failed, delivered |
| title | VARCHAR(255) | Notification heading |
| body | TEXT | Notification content |
| payload | JSON | Extra data, jaise worker_code |
| sent_at | TIMESTAMP | Kab bheja |

Abhi notification ek log table hai. Actually WhatsApp ya SMS bhejne ka integration alag se add karna hoga.

---

## Rider Onboarding Flow

Ye poora process kaise chalta hai step by step:

Pehla step: Rider phone number se register karta hai. Ye API call hai POST /api/auth/register, jisme name, phone, gender, city bhejte hain. Register hone ke baad ek JWT token milta hai aur stage "registered" hoti hai.

Doosra step: Rider client select karta hai. POST /api/riders/select-client mein client_id bhejo. Ye karne ke baad stage "documents_pending" ho jati hai aur ek BGV record create ho jata hai "triggered" status ke saath.

Teesra step: Rider 6 documents upload karta hai. POST /api/documents/upload mein ek ek karke documents upload karte hain (multipart/form-data). Allowed types hain JPG, PNG, PDF aur max size 5MB hai. Jab saare 6 unique types upload ho jate hain, stage automatically "documents_submitted" ho jati hai.

Chautha step: Admin Dashboard ke BGV Queue mein ye rider dikhta hai. Admin uski details dekh sakta hai aur "Clear" ya "Reject" kar sakta hai.

Paanchwa step: Admin BGV Clear karta hai.
- Agar saare 6 documents already approved hain: stage seedha "onboarded" ho jati hai aur ek worker code generate hota hai (GLAM-WRK-XXXXXX format).
- Agar documents baaki hain: stage "bgv_cleared" hoti hai aur documents approve hone ka wait karta hai.

Chhaatha step: Admin Riders page se documents modal kholke ek ek document approve ya reject karta hai. Jab saare 6 approved ho jaate hain aur BGV bhi cleared hai, stage "onboarded" ho jati hai.

Saatwa step: Admin manually rider ko "live" stage mein daal sakta hai jab wo actually delivery shuru kare.

---

## Admin Dashboard Pages

Dashboard: Onboarding funnel ka snapshot dikhta hai, jisme registered se leke live tak kitne riders hain. Ye cumulative count hai, matlab "registered" mein total sab riders hain, aur "live" mein sirf live wale.

Riders: Poori rider list paginated format mein milti hai. Stage filter aur city search hai. Har rider ke liye Hub, TL Name, Worker Code edit kar sakte ho. "Docs" button se document verification modal khulta hai jisme ek ek document approve ya reject kar sakte ho.

BGV Queue: Sirf wahi riders dikhte hain jinki BGV "glam" ke paas pending hai (triggered ya in_progress). Yahan se admin Clear ya Reject kar sakta hai. Reject mein reason mandatory hai.

Bulk Upload: CSV file upload karo aur ek saath bohot saare riders import karo. CSV format mein full_name, phone_number, gender, city, preferred_language, client_code, hub_name, tl_name, tl_phone columns support hote hain. Agar rider already hai toh update hoga, naya ho toh insert hoga.

Clients: Active clients ki list dikhti hai.

Payouts: Abhi sirf Coming Soon placeholder hai.

---

## Setup Kaise Karein

### Prerequisites

- Node.js v18 ya usse upar
- MySQL 8.x running
- npm installed hona chahiye

### Step 1: Environment Variables Setup

```bash
cd /home/sarthak-shishodia/demoProj/glam-backend
cp .env.example .env
```

.env file open karo aur ye values fill karo:

```
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=apna_mysql_password_yahan_dalo
DB_NAME=glam_onboarding
JWT_SECRET=koi_bhi_random_string_dalo_yahan
NODE_ENV=development
```

Cloudinary wale variables optional hain. Agar nahi daloge toh files local disk pr save hongi jo development ke liye theek hai.

### Step 2: Database Initialize Karein

```bash
mysql -u root -p < schema.sql
```

Ye command database create karega, saari tables banayega aur 3 clients (Flipkart Minutes, Zepto, Blinkit) ka seed data daal dega.

### Step 3: Dependencies Install Karein

```bash
npm install
```

### Step 4: Backend Start Karein

```bash
npm run dev
```

Server http://localhost:5000 par run hoga. Ek test kar sakte ho:

```bash
curl http://localhost:5000/health
```

Response aana chahiye: `{"status":"ok","service":"GLAM API"}`

### Step 5: Admin Account Banana

Abhi admin account manually MySQL mein insert karna padta hai kyunki koi signup page nahi hai (security ke liye intentionally nahi banaya). Pehle ek bcrypt hash generate karo, phir insert karo.

Ye Node.js script run karo terminal mein:

```bash
node -e "const b = require('bcryptjs'); b.hash('apna_password_yahan', 12).then(h => console.log(h))"
```

Jo hash aaye wo copy karo, phir MySQL mein ye run karo:

```sql
USE glam_onboarding;

INSERT INTO tb_admins (name, email, password_hash, role)
VALUES ('Sarthak', 'admin@glam.in', 'YAHAN_HASH_PASTE_KARO', 'super_admin');
```

Ab iss email aur password se dashboard login kar sakte ho.

### Step 6: Admin Dashboard Start Karein

```bash
cd glam-admin
npm install
npm start
```

Dashboard http://localhost:3000 par open hoga. Login karo admin email aur password se.

---

## Rider App Nahi Hai Toh Kya Karein

Rider ka mobile app ya website abhi nahi bani hai. Toh rider ke actions test karne ke liye seedha API call karna padega. Ye karne ke do tarike hain:

Postman use karo: Postman install karo, ek naya collection banao, aur neeche diye endpoints call karo. Har authenticated endpoint mein Authorization: Bearer <token> header dalna hoga.

Curl use karo terminal se: Commands neeche diye hain.

Rider Register karna:

```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "Rahul Kumar",
    "phone_number": "9876543210",
    "gender": "male",
    "city": "Delhi",
    "preferred_language": "hindi"
  }'
```

Response mein ek token milega, use copy kar lo.

Client Select karna (clients ka id pata karne ke liye pehle GET /api/clients call karo):

```bash
curl -X POST http://localhost:5000/api/riders/select-client \
  -H "Authorization: Bearer TOKEN_YAHAN" \
  -H "Content-Type: application/json" \
  -d '{"client_id": 1}'
```

Document Upload karna:

```bash
curl -X POST http://localhost:5000/api/documents/upload \
  -H "Authorization: Bearer TOKEN_YAHAN" \
  -F "file=@/path/to/aadhaar.jpg" \
  -F "document_type=aadhaar"
```

Saare 6 types ke liye alag alag call karo: aadhaar, pan, vehicle_rc, driving_licence, bank_passbook, selfie.

BGV Queue Admin se: Dashboard kholo, BGV Queue mein rider dikhega, "Clear" karo.

Ya directly API se:

```bash
# Pehle admin login karo
curl -X POST http://localhost:5000/api/auth/login/admin \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@glam.in", "password": "apna_password"}'

# BGV queue dekho
curl http://localhost:5000/api/bgv/admin/queue \
  -H "Authorization: Bearer ADMIN_TOKEN"

# BGV update karo (bgv_id queue response se milega)
curl -X POST http://localhost:5000/api/bgv/admin/BGV_ID/update \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status": "cleared", "remarks": "All good"}'
```

---

## Bulk CSV Upload Format

Agar ek saath bohot saare riders import karne hain toh CSV file banao is format mein:

```
full_name,phone_number,gender,city,preferred_language,client_code,hub_name,tl_name,tl_phone
Rahul Kumar,9876543210,male,Delhi,hindi,FKM,Connaught Place Hub,Ajay Singh,9812345678
Priya Sharma,9876543211,female,Mumbai,hindi,ZEPTO,Andheri Hub,Raj Kumar,9823456789
```

Supported client_codes: FKM, ZEPTO, BLINKIT

File size limit 10MB hai. Dashboard ke Bulk Upload section se ya seedha API se upload kar sakte ho:

```bash
curl -X POST http://localhost:5000/api/riders/admin/bulk-upload/riders \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -F "csv_file=@riders.csv"
```

---

## API Rate Limits

- General API: 100 requests per 15 minutes per IP
- Auth endpoints (register, login): 10 requests per 15 minutes per IP (successful requests count nahi hote)
- Document upload: 20 requests per 15 minutes per user

---

## File Storage

Development mode mein (jab .env mein CLOUDINARY variables nahi hain) saare documents local "uploads/" folder mein save hote hain. Production mein Cloudinary credentials set karo, files automatically cloud par jayengi.

Dev mein uploaded files access: http://localhost:5000/uploads/aadhaar/filename.jpg

---

## Logs

HTTP request logs "logs/" folder mein daily rotate hote hain Morgan se. Console mein bhi structured logs dikhte hain har operation ke liye, format hai [STEP][MODULE] message.

---

## Known Limitations

Ye system abhi production ready nahi hai. Kuch cheezein baaki hain. Rider ke liye koi frontend app nahi hai, seedha API call karni padti hai. Notifications abhi sirf database mein log hoti hain, actual WhatsApp ya SMS nahi jati. Payouts module complete nahi hua hai. Admin account manually SQL se banana padta hai. Document number validation (Aadhaar format check, PAN format check) nahi hai, sirf optional field hai.
