# API Segnalazioni — Castellazzo de' Stampi

**Base URL produzione:** `https://www.castellazzodestampi.org/api`
**Base URL sviluppo:** `http://localhost/www.castellazzodestampi.org/public/api`

---

## Autenticazione

Tutte le API (tranne `/api/login` e `/api/password-dimenticata`) richiedono l'header:

```
X-AUTH-TOKEN: <token>
```

Il token viene restituito dalla chiamata di login ed è una stringa esadecimale di 64 caratteri.
Il token resta valido fino al logout o fino a un nuovo login (che lo rigenera).

### Risposte di errore standard

```json
{
  "success": false,
  "message": "Descrizione dell'errore"
}
```

| HTTP Status | Significato |
|-------------|-------------|
| 400 | Parametri mancanti o non validi |
| 401 | Non autenticato (token mancante/invalido) o credenziali errate |
| 403 | Account non attivo |
| 404 | Risorsa non trovata |

---

## 1. LOGIN

```
POST /api/login
Content-Type: application/json
```

**Body:**

```json
{
  "email": "utente@example.com",
  "password": "la-password"
}
```

**Risposta successo (200):**

```json
{
  "success": true,
  "token": "a1b2c3d4e5f6...64_caratteri_hex",
  "user": {
    "id": "1",
    "email": "utente@example.com",
    "name": "Mario",
    "surname": "Rossi",
    "role": "ROLE_USER"
  }
}
```

**Errori:** `400` — email/password mancanti · `401` — credenziali errate · `403` — account non attivo

---

## 2. LOGOUT

```
POST /api/logout
X-AUTH-TOKEN: <token>
```

**Risposta successo (200):**

```json
{ "success": true, "message": "Logout effettuato." }
```

---

## 3. MODIFICA PASSWORD

```
POST /api/modifica-password
Content-Type: application/json
X-AUTH-TOKEN: <token>
```

**Body:**

```json
{
  "current_password": "password-attuale",
  "new_password": "nuova-password"
}
```

**Risposta successo (200):**

```json
{ "success": true, "message": "Password modificata con successo." }
```

**Errori:** `400` — password mancante · `400` — nuova password < 6 caratteri · `400` — password attuale errata

---

## 4. PASSWORD DIMENTICATA

```
POST /api/password-dimenticata
Content-Type: application/json
```

**Body:**

```json
{ "email": "utente@example.com" }
```

**Risposta successo (200):** — restituisce sempre successo per non rivelare se l'email esiste

```json
{ "success": true, "message": "Se l'indirizzo è registrato riceverai le istruzioni a breve." }
```

Il server genera una password temporanea di 8 caratteri, la salva (hashata) e la invia via email.

---

## 5. TIPI SEGNALAZIONE

Restituisce l'elenco dei tipi di segnalazione attivi, usato per il menu home con icone.

```
GET /api/tipi-segnalazione
X-AUTH-TOKEN: <token>
```

**Risposta successo (200):**

```json
{
  "success": true,
  "data": [
    {
      "id": "1",
      "name": "Buca stradale",
      "slug": "buca-stradale",
      "icon": "bi-exclamation-triangle",
      "icon_file": "https://www.castellazzodestampi.org/uploads/report_types/icon_abc.png"
    },
    {
      "id": "2",
      "name": "Illuminazione pubblica",
      "slug": "illuminazione-pubblica",
      "icon": "bi-lightbulb",
      "icon_file": null
    }
  ]
}
```

**Campi:**

| Campo | Tipo | Descrizione |
|-------|------|-------------|
| `id` | string | ID del tipo |
| `name` | string | Nome visualizzato |
| `slug` | string | Slug URL-friendly |
| `icon` | string\|null | Classe Bootstrap Icons (es. `bi-exclamation-triangle`) |
| `icon_file` | string\|null | **URL completo** immagine icona custom (es. `https://…/uploads/report_types/icon.png`), oppure `null` |

### Logica icone in Flutter (`lib/main.dart`)

La funzione `_iconFromType(iconClass, slug)` segue questa priorità:

1. **`icon_file` non null** → `Image.network(icon_file)` (immagine PNG/JPG caricata dall'admin)
2. **`icon` = `bi-xxx`** → `BootstrapIcons.xxx` dal pacchetto `bootstrap_icons` (font, zero richieste rete)
   - Es: `bi-lightbulb` → `BootstrapIcons.lightbulb`
   - Es: `bi-exclamation-triangle` → `BootstrapIcons.exclamation_triangle`
   - I trattini vengono convertiti in underscore
3. **Fallback** → icona Material mappata dallo `slug`

---

## 6. SEGNALAZIONI — LISTA

```
GET /api/segnalazioni
X-AUTH-TOKEN: <token>
```

Restituisce tutte le segnalazioni dell'utente autenticato, ordinate per data decrescente.
Ogni segnalazione include già `attachments[]`.

**Risposta successo (200):**

```json
{
  "success": true,
  "data": [
    {
      "id": "15",
      "type": {
        "id": "1",
        "name": "Buca stradale",
        "slug": "buca-stradale"
      },
      "datetime": "2026-04-16 10:30:00",
      "latitude": "45.4536700",
      "longitude": "9.0027400",
      "address": "Via Roma 15, Castellazzo de' Stampi",
      "priority": 0,
      "details": "Buca profonda circa 20cm sulla carreggiata...",
      "status": "pending",
      "status_label": "In attesa",
      "attachments": [
        {
          "file_name": "foto.jpg",
          "file_path": "/uploads/reports/15/foto.jpg",
          "file_type": "image/jpg",
          "uploaded_at": "2026-04-16 10:00:00"
        }
      ]
    }
  ]
}
```

**Valori `status`:**

| status | status_label |
|--------|-------------|
| `pending` | In attesa |
| `in_progress` | In lavorazione |
| `resolved` | Risolta |
| `rejected` | Rifiutata |
| `merged` | Accorpata |

---

## 7. SEGNALAZIONI — DETTAGLIO

```
GET /api/segnalazioni/{id}
X-AUTH-TOKEN: <token>
```

Stessa struttura della lista. L'utente può vedere solo le proprie segnalazioni.

**Errori:** `404` — segnalazione non trovata o non appartenente all'utente

---

## 8. SEGNALAZIONI — CREA

```
POST /api/segnalazioni
Content-Type: multipart/form-data
X-AUTH-TOKEN: <token>
```

**Parametri form-data:**

| Campo | Obbligatorio | Descrizione |
|-------|:------------:|-------------|
| `type_id` | Sì | ID tipo segnalazione |
| `details` | No | Descrizione |
| `latitude` | No | Es: `45.4536700` |
| `longitude` | No | Es: `9.0027400` |
| `address` | No | Indirizzo testuale |
| `attachments[]` | No | Uno o più file (ripetere il campo per più file) |

**Risposta successo (201):** struttura segnalazione completa con `"status": "pending"`

**Errori:** `400` — `type_id` mancante o non valido

---

## 9. SEGNALAZIONI — MODIFICA

Solo le segnalazioni con `status = pending` possono essere modificate.

```
POST /api/segnalazioni/{id}
Content-Type: multipart/form-data
X-AUTH-TOKEN: <token>
```

Tutti i campi sono opzionali. I nuovi allegati vengono **aggiunti** (non sostituiscono i precedenti).

**Risposta successo (200):** struttura segnalazione aggiornata

**Errori:** `400` — status non pending · `404` — non trovata

---

## 10. SEGNALAZIONI — ELIMINA

Solo le segnalazioni con `status = pending` possono essere eliminate.

```
POST /api/segnalazioni/{id}/elimina
X-AUTH-TOKEN: <token>
```

Elimina la segnalazione e **tutti i file** nella cartella `/uploads/reports/{id}/`.

**Risposta successo (200):**

```json
{ "success": true, "message": "Segnalazione eliminata." }
```

**Errori:** `400` — status non pending · `404` — non trovata

---

## Allegati (foto)

Gli allegati sono gestiti via **filesystem** (cartella `/uploads/reports/{id}/`), non via database.

```json
"attachments": [
  {
    "file_name": "foto.jpg",
    "file_path": "/uploads/reports/42/foto.jpg",
    "file_type": "image/jpg",
    "uploaded_at": "2026-04-16 10:00:00"
  }
]
```

**URL completo foto:** `https://www.castellazzodestampi.org` + `file_path`

Esempio: `https://www.castellazzodestampi.org/uploads/reports/42/foto.jpg`

`attachments` è presente sia nella lista che nel dettaglio; array vuoto `[]` se non ci sono file.

---

## 11. GEOCODING — AUTOCOMPLETE INDIRIZZO

```
GET /api/autocomplete-indirizzo?q=via+roma
X-AUTH-TOKEN: <token>
```

Richiede almeno 3 caratteri. Usa Nominatim (OpenStreetMap), filtrato su Italia.

**Risposta successo (200):**

```json
{
  "success": true,
  "data": [
    {
      "display_name": "Via Roma, Castellazzo de' Stampi, ...",
      "lat": "45.4536700",
      "lon": "9.0027400"
    }
  ]
}
```

---

## 12. GEOCODING — REVERSE GEOCODE

```
GET /api/reverse-geocode?lat=45.4&lon=9.1
X-AUTH-TOKEN: <token>
```

**Risposta successo (200):**

```json
{
  "success": true,
  "data": {
    "address": "Via Roma, 15, Castellazzo de' Stampi"
  }
}
```

---

## Riepilogo endpoint

| Metodo | Endpoint | Auth | Descrizione |
|--------|----------|:----:|-------------|
| POST | `/api/login` | No | Login |
| POST | `/api/logout` | Sì | Logout |
| POST | `/api/modifica-password` | Sì | Cambio password |
| POST | `/api/password-dimenticata` | No | Recupero password via email |
| GET | `/api/tipi-segnalazione` | Sì | Lista tipi segnalazione con icone |
| GET | `/api/segnalazioni` | Sì | Lista segnalazioni dell'utente |
| GET | `/api/segnalazioni/{id}` | Sì | Dettaglio segnalazione |
| POST | `/api/segnalazioni` | Sì | Crea segnalazione |
| POST | `/api/segnalazioni/{id}` | Sì | Modifica segnalazione (solo pending) |
| POST | `/api/segnalazioni/{id}/elimina` | Sì | Elimina segnalazione (solo pending) |
| GET | `/api/autocomplete-indirizzo` | Sì | Autocomplete indirizzo |
| GET | `/api/reverse-geocode` | Sì | Reverse geocoding coordinate → indirizzo |
