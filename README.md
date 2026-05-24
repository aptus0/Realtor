# Realtor Stays — Salesforce + Next.js Emlak Platformu

Realtor Stays; Salesforce CRM'i kayıt sistemi (system of record) olarak kullanan, Next.js (App Router) tabanlı bir gayrimenkul ilan ve randevu platformudur. Tüm ilanlar, lokasyonlar, alıcılar, randevular ve emlakçı atamaları Salesforce'ta yönetilir; halka açık web sitesi ilanları **Apex REST API** üzerinden çeker, ziyaretçilerin gönderdiği randevu taleplerini aynı API üzerinden Salesforce'a yazar. Yönetici tarafında ise **Lightning Web Component (LWC)** tabanlı bir dashboard, **trigger**'lar, **validation rule**'lar, **schedulable job** ve **permission set** ile uçtan uca bir iş akışı kurulmuştur.

---

## İçindekiler

1. [Mimari Genel Bakış](#mimari-genel-bakış)
2. [Salesforce Tarafı](#salesforce-tarafı)
   - [Veri Modeli (Custom Object'lar)](#veri-modeli-custom-objectlar)
   - [Validation Rule'lar](#validation-rulelar)
   - [Apex Trigger'lar ve Handler'lar](#apex-triggerlar-ve-handlerlar)
   - [Apex Servis Katmanı](#apex-servis-katmanı)
   - [Schedulable Job (Batch / Cron)](#schedulable-job-batch--cron)
   - [Apex REST API (Public Integration)](#apex-rest-api-public-integration)
   - [Lightning Web Component — Admin Dashboard](#lightning-web-component--admin-dashboard)
   - [Permission Set, App, Tabs](#permission-set-app-tabs)
3. [Next.js Frontend & Entegrasyon](#nextjs-frontend--entegrasyon)
4. [Karşılaşılan Sorunlar ve Çözümleri](#karşılaşılan-sorunlar-ve-çözümleri)
5. [Kurulum](#kurulum)
6. [Proje Yapısı](#proje-yapısı)

---

## Mimari Genel Bakış

```text
┌──────────────────────────┐         OAuth2 / REST          ┌──────────────────────────────┐
│  Next.js 14 (App Router) │ ─────────────────────────────► │  Salesforce Apex REST        │
│  - SSR property listesi  │  /services/apexrest/realtor/v1 │  RealtorPublicApi.cls        │
│  - /api/bookings route   │ ◄───────────────────────────── │  (GET properties, POST book) │
└──────────────────────────┘                                └──────────────┬───────────────┘
        │                                                                  │
        │  fallback (env yoksa demo data)                                  ▼
        ▼                                                  ┌──────────────────────────────┐
   lib/salesforce.ts                                       │  Custom Object'lar           │
                                                           │  Property__c, Buyer__c, ...  │
                                                           └──────────────┬───────────────┘
                                                                          │
                                                           ┌──────────────▼───────────────┐
                                                           │  Trigger + Handler katmanı   │
                                                           │  - mail bildirimi            │
                                                           │  - prereq doğrulaması        │
                                                           │  - silinen kayıt log'u       │
                                                           └──────────────┬───────────────┘
                                                                          │
                                                           ┌──────────────▼───────────────┐
                                                           │  Schedulable Cron Job        │
                                                           │  Manager'lara günlük digest  │
                                                           └──────────────────────────────┘
```

İki ayrı çalışan parça vardır:

- **`force-app/`** — Salesforce DX kaynak ağacı (objeler, Apex sınıfları, trigger'lar, LWC, validation rule'lar, permission set, app, tab, flexipage).
- **`web/`** — Next.js 14 + TypeScript uygulaması (App Router, sunucu bileşenleri, REST entegrasyonu).

Ortak nokta: Next.js tarafındaki [web/lib/salesforce.ts](web/lib/salesforce.ts) modülü OAuth2 Username-Password akışıyla `access_token` alır ve Apex REST endpoint'ini çağırır.

---

## Salesforce Tarafı

### Veri Modeli (Custom Object'lar)

| Obje | Amaç | Önemli Alanlar |
| --- | --- | --- |
| `Property__c` | İlan ana kaydı. AutoNumber `PROP-{00000}` format'ında. | `Name__c`, `Status__c` (Prepared/In Progress), `Property_Type__c` (Rent/Sell/Daily Rent), `Price__c`, `Bedrooms__c`, `Bathrooms__c`, `Area_Sq_Ft__c`, `Start_Date_Time__c`, `End_Date_Time__c`, `Public_Listing__c`, `Location_Verified__c`, `Prerequisites__c`, `Recurring__c`, `Frequency__c`, `Image_URL__c`, `Description__c`, `Manager__c` (lookup), `Location__c` (lookup) |
| `Buyer__c` | Web'den gelen ya da CRM'de açılan alıcı. | `Email__c`, `Phone__c`, `Company_Name__c`, `Location__c` |
| `Property_Buyer__c` | Alıcı ↔ İlan junction'ı (randevu kaydı). | `Property__c`, `Buyer__c`, `Appointment_Date_Time__c`, `Status__c`, `Notes__c` |
| `Property_Realtor__c` | Emlakçı ↔ İlan junction'ı. | `Property__c`, `Realtor__c` |
| `Realtor__c` | Emlakçı kartı. | `Email__c`, `Phone__c`, `Field_of_Duty__c`, `Photo_URL__c` |
| `Manager__c` | İlanın bağlı olduğu yönetici. | `Email__c`, `Alternative_Email__c`, `Phone__c`, `Location__c` |
| `Location__c` | Adres kaydı. | `Street__c`, `City__c`, `State__c`, `Country__c`, `Postal_Code__c`, `Land_Mark__c`, `Verified__c` |
| `Error_Log__c` | Trigger ve servis hatalarının ve silme işlemlerinin yazıldığı log. | `Process_Name__c`, `Apex_Class_Name__c`, `Log_Date_Time__c`, `Log_Details__c` |

`Property__c` üzerinde `enableHistory`, `enableFeeds`, `enableBulkApi` açık; paylaşım modeli `ControlledByParent`.

### Validation Rule'lar

Veri bütünlüğü deklaratif olarak korunur — Apex'e gerek kalmadan kullanıcı UI'dan yanlış kayıt atamaz:

- **[Prerequisites_Required](force-app/main/default/objects/Property__c/validationRules/Prerequisites_Required.validationRule-meta.xml)** — `Prerequisites__c` işaretlenmeden ilan kaydedilemez.
- **[End_After_Start](force-app/main/default/objects/Property__c/validationRules/End_After_Start.validationRule-meta.xml)** — `End_Date_Time__c`, `Start_Date_Time__c`'den en az 1 gün sonra olmalı.
- **[Recurring_Frequency_Required](force-app/main/default/objects/Property__c/validationRules/Recurring_Frequency_Required.validationRule-meta.xml)** — `Recurring__c` ile `Frequency__c` tutarlı olmak zorunda (biri varsa diğeri de olmalı).
- **[Sell_Requires_Location](force-app/main/default/objects/Property__c/validationRules/Sell_Requires_Location.validationRule-meta.xml)** — Satılık ilanların `Location__c`'si boş bırakılamaz.
- **[Appointment_Not_In_Past](force-app/main/default/objects/Property_Buyer__c/validationRules/Appointment_Not_In_Past.validationRule-meta.xml)** — Randevu tarihi geçmişte olamaz.

### Apex Trigger'lar ve Handler'lar

Trigger framework deseni uygulandı: **trigger ince, handler kalın**. Trigger'lar sadece dispatcher; iş mantığı handler sınıflarında.

#### 1. [PropertyBuyerTrigger](force-app/main/default/triggers/PropertyBuyerTrigger.trigger) — `after insert`

Web/CRM üzerinden bir randevu kaydı (`Property_Buyer__c`) açıldığında alıcıya **otomatik e-posta** gönderir.

- Handler: [PropertyBuyerTriggerHandler.cls](force-app/main/default/classes/PropertyBuyerTriggerHandler.cls)
- Bulkify edilmiş tek bir SOQL ile tüm yeni kayıtları parent ilişkileriyle (Buyer, Property, Location) çeker, `Messaging.SingleEmailMessage` listesi hazırlar.
- Hata olursa `RealtorLog.error(...)` çağrısıyla `Error_Log__c`'ye yazar; trigger transaction'ını kırmaz.

#### 2. [PropertyRealtorTrigger](force-app/main/default/triggers/PropertyRealtorTrigger.trigger) — `before insert, before update`

Bir emlakçının ilana atanabilmesi için ilanın **prerequisites onaylı** ve **end date'i gelecekte** olması zorunludur.

- Handler: [PropertyRealtorTriggerHandler.cls](force-app/main/default/classes/PropertyRealtorTriggerHandler.cls)
- Atanan ilanların `Id`'si tek bir SOQL'de getirilir, koşul sağlanmazsa `record.addError(...)` ile kayıt durdurulur.
- Bu mantık validation rule ile yazılamadı çünkü kontrol **junction çocuktan parent'a** bakıyor — Apex gerekiyor.

#### 3. [PropertyDeleteTrigger](force-app/main/default/triggers/PropertyDeleteTrigger.trigger) — `after delete`

Silinen her `Property__c` için `Error_Log__c` üzerine audit kaydı atar; bu kayıtlar gün sonu digest e-postasının kaynağı olur.

- Handler: [PropertyDeleteTriggerHandler.cls](force-app/main/default/classes/PropertyDeleteTriggerHandler.cls)

### Apex Servis Katmanı

| Sınıf | Sorumluluk |
| --- | --- |
| [RealtorLog.cls](force-app/main/default/classes/RealtorLog.cls) | Merkezi loglayıcı. `error(process, class, exception)` ve `write(...)` ile `Error_Log__c`'ye yazar. Yutucu `catch (Exception ignored)` — log yazımı asla çağıran transaction'ı kırmaz. |
| [AddressVerificationService.cls](force-app/main/default/classes/AddressVerificationService.cls) | `@AuraEnabled` metot ile LWC'den çağrılır. Adres tamlığını doğrular ve `Location__c.Verified__c`'yi günceller. SmartyStreets gibi gerçek bir API'ye **Named Credential** üzerinden takılmak için yorum satırı olarak yer bırakıldı. |
| [RealtorAdminDashboardController.cls](force-app/main/default/classes/RealtorAdminDashboardController.cls) | LWC dashboard'unun `@AuraEnabled(cacheable=true)` veri sağlayıcısı: ilan/buyer/randevu sayıları + son 6 ilan. |

### Schedulable Job (Batch / Cron)

[PropertyDeletionDigestJob.cls](force-app/main/default/classes/PropertyDeletionDigestJob.cls) — `Schedulable` interface'ini implemente eder. Bugün silinmiş tüm property log'larını toplar ve `Manager__c`'lerin e-postalarına **günlük digest** gönderir.

Tipik zamanlama (Developer Console / `System.schedule`):

```apex
System.schedule(
    'Realtor Daily Delete Digest',
    '0 0 22 * * ?',                       // her gün 22:00
    new PropertyDeletionDigestJob()
);
```

### Apex REST API (Public Integration)

[RealtorPublicApi.cls](force-app/main/default/classes/RealtorPublicApi.cls) — `@RestResource(urlMapping='/realtor/v1/*')` ile Next.js tarafının dış kapısı:

| Method | URL | Açıklama |
| --- | --- | --- |
| `GET` | `/services/apexrest/realtor/v1/properties` | Public listede yayınlanan tüm ilanları (`Public_Listing__c = true`, `Status__c IN ('Prepared','In Progress')`) DTO olarak döner. |
| `GET` | `/services/apexrest/realtor/v1/properties/{id}` | Tek bir ilan detayı. |
| `POST` | `/services/apexrest/realtor/v1/bookings` | Randevu yaratır. Aynı `email + phone` ile mevcut `Buyer__c` varsa **idempotent upsert** yapar, yoksa açar; ardından `Property_Buyer__c` insert eder. |

POST tarafı `Database.setSavepoint()` + `Database.rollback(sp)` ile **transactional**; hata `RealtorLog.error`'a düşer, çağırana 500 + güvenli mesaj döner. Salesforce iç şema field API isimleri (`Name__c`, `Status__c`, ...) dışarıya `PropertyDto`/`BookingResponse` ile soyutlanmış halde sunulur — internal değişiklik dış sözleşmeyi bozmaz.

### Lightning Web Component — Admin Dashboard

[force-app/main/default/lwc/realtorAdminDashboard/](force-app/main/default/lwc/realtorAdminDashboard/)

- `@wire(getSummary)` ile Apex controller'a bağlanır.
- `lightning-datatable` ile son 6 ilanı listeler, kart sayaçları (toplam ilan, buyer, randevu, public liste) gösterir.
- Cacheable Apex sayesinde aynı kullanıcı için tekrar fetch yapılmaz; record değiştiğinde refresh hook'u eklenebilir.

### Permission Set, App, Tabs

- [Realtor_Admin.permissionset-meta.xml](force-app/main/default/permissionsets/Realtor_Admin.permissionset-meta.xml) — uygulama yöneticileri için object/field/page erişimleri.
- [Realtor_App.app-meta.xml](force-app/main/default/applications/Realtor_App.app-meta.xml) — Lightning App.
- `tabs/` dizininde her custom object için Lightning tab; navigation menüsünden direkt erişim.

---

## Next.js Frontend & Entegrasyon

[web/lib/salesforce.ts](web/lib/salesforce.ts) entegrasyonun kalbidir:

1. **OAuth2 Username-Password Flow** ile `/services/oauth2/token` endpoint'ine `POST` atar (`client_id`, `client_secret`, `username`, `password + security_token`).
2. Dönen `access_token` + `instance_url` ile Apex REST endpoint'lerine `Authorization: Bearer ...` ekleyerek çağrı yapar.
3. **Graceful fallback**: ortam değişkenleri tanımsızsa demo veriyle UI'ı bozmadan çalışır → geliştirme deneyimini hızlandırır, demo sunumları kırılmaz.

Sayfa yapısı:

- [app/page.tsx](web/app/page.tsx) — anasayfa; sunucu bileşeni olarak `fetchProperties()` çağırır, ilan kartlarını render eder.
- [app/properties/[id]/page.tsx](web/app/properties/[id]/page.tsx) — ilan detayı + sağda randevu formu. Form `action="/api/bookings"` POST eder.
- [app/api/bookings/route.ts](web/app/api/bookings/route.ts) — Form verisini parse edip `createBooking()` ile Apex REST'e iletir.
- [app/api/properties/route.ts](web/app/api/properties/route.ts) — JSON proxy (mobil/3rd party için).

Önemli detay: server component'lerde `cache: 'no-store'` kullanılarak Salesforce'taki güncel state her istekte taze çekilir; access token cache'lenmez (kısa süreli).

---

## Karşılaşılan Sorunlar ve Çözümleri

| # | Sorun | Çözüm |
| --- | --- | --- |
| 1 | **Trigger'da SOQL/DML limit'leri.** İlk `PropertyBuyerTrigger` versiyonu her kayıt için ayrı SOQL atıyor, bulk insert'te `Too many SOQL queries: 101` veriyordu. | Handler tek bir SOQL ile tüm `bookingIds` için parent verileri çekiyor, e-postalar tek listede toplanıp `Messaging.sendEmail` ile tek seferde gönderiliyor — **bulkification deseni**. |
| 2 | **Validation rule junction'dan parent'a bakamıyor.** Bir emlakçı atamasının prereq'siz/expired ilana yapılmasını formula ile engelleyemedik. | `PropertyRealtorTriggerHandler.beforeSave` içinde tek SOQL ile parent `Property__c` çekip `record.addError(...)` ile durduran trigger yazıldı. |
| 3 | **Aynı alıcı tekrar tekrar açılıyor.** Public booking API her POST'ta yeni `Buyer__c` üretiyordu — dashboard'ta gereksiz duplicate kayıt. | `RealtorPublicApi.createBooking` `email + phone` üzerinden SOQL ile mevcut buyer'ı arayıp **idempotent upsert** yapıyor. Ek olarak duplicate rule framework hazır. |
| 4 | **Booking POST hata aldığında yarım kayıt.** Buyer insert olup booking insert hata verdiğinde "orphan buyer" oluşuyordu. | `Database.setSavepoint()` + `catch` içinde `Database.rollback(sp)` ile transactional davranış; hata loglanıp 500 dönüyor. |
| 5 | **Log yazımı transaction'ı kırıyordu.** `Error_Log__c` insert'i de Apex limit'lerine sayıyor ve patladığında orijinal hata maskeleniyordu. | `RealtorLog.write` içinde `try { ... } catch (Exception ignored) {}` — log yazımı en kötü ihtimalle sessiz başarısız olur, asıl iş akışını etkilemez. |
| 6 | **Next.js dev'de Salesforce credential olmadan çalışmıyordu.** Her geliştiricinin org bağlaması gerekiyordu. | `lib/salesforce.ts` `getAccessToken()` env yoksa `null` döner ve `fallbackProperties` ile demo veri kullanılır. Real org bağlanınca otomatik gerçek veriye geçer. |
| 7 | **Cron job manager e-postasız hata fırlatıyordu.** Yeni org'da hiç `Manager__c` yokken `Messaging.sendEmail` boş `toAddresses` ile patladı. | `PropertyDeletionDigestJob`'a guard eklendi: log veya manager listesi boşsa erken `return`. |
| 8 | **REST endpoint Salesforce internal field adlarını dışarı sızdırıyordu.** Frontend `Name__c`, `Property_Type__c` gibi alanlarla başetmek zorundaydı. | `PropertyDto` / `BookingResponse` DTO'ları + `toDto` mapper ile public sözleşme stabilize edildi; iç şema değiştiğinde frontend kırılmaz. |
| 9 | **Property üzerine yanlış kombinasyonla kayıt geliyordu** (örn. `Recurring` işaretli ama `Frequency` boş, ya da Sell tipinde lokasyonsuz). | Beş ayrı **validation rule** ile UI seviyesinde engellenip kullanıcıya net hata mesajı gösteriliyor. |
| 10 | **Silinen ilanların izi kayboluyordu.** Audit yokken yanlışlıkla silinen kayıt geri gelmiyor, kimin sildiği belirsizdi. | `PropertyDeleteTrigger` her silmede `Error_Log__c`'ye snapshot atıyor; `PropertyDeletionDigestJob` gün sonu manager'lara digest e-posta atıyor. |

---

## Kurulum

### Önkoşullar

- Salesforce CLI (`sf`) ya da `sfdx`
- Node.js 18+
- Bir Salesforce Dev/Scratch org

### Salesforce metadata'yı deploy etmek

```bash
sf org login web -a realtor-dev
sf project deploy start -d force-app -o realtor-dev
sf org assign permset -n Realtor_Admin -o realtor-dev
sf apex run --file scripts/apex/seed-realtor.apex -o realtor-dev   # opsiyonel: demo veri
```

### Cron job'ı schedule etmek

Developer Console > Execute Anonymous:

```apex
System.schedule('Realtor Daily Delete Digest', '0 0 22 * * ?', new PropertyDeletionDigestJob());
```

### Connected App + Next.js

1. Setup → App Manager → **New Connected App** oluştur, OAuth aktif et, scope: `api`, `refresh_token`.
2. `web/.env.local` dosyasını [.env.example](web/.env.example) referans alarak doldur (`SALESFORCE_LOGIN_URL`, `SALESFORCE_CLIENT_ID`, `SALESFORCE_CLIENT_SECRET`, `SALESFORCE_USERNAME`, `SALESFORCE_PASSWORD`, `SALESFORCE_SECURITY_TOKEN`).
3. Çalıştır:

```bash
cd web
npm install
npm run dev
```

Credential vermeden de site `fallbackProperties` ile açılır.

---

## Proje Yapısı

```text
Realtor/
├── force-app/main/default/
│   ├── applications/                 # Lightning App tanımı
│   ├── aura/
│   ├── classes/                      # Apex sınıfları (API, handlers, services, jobs)
│   │   ├── RealtorPublicApi.cls      # Public REST endpoint
│   │   ├── PropertyBuyerTriggerHandler.cls
│   │   ├── PropertyRealtorTriggerHandler.cls
│   │   ├── PropertyDeleteTriggerHandler.cls
│   │   ├── AddressVerificationService.cls
│   │   ├── PropertyDeletionDigestJob.cls
│   │   ├── RealtorAdminDashboardController.cls
│   │   └── RealtorLog.cls
│   ├── triggers/                     # Apex Trigger'lar (ince dispatcher)
│   ├── objects/                      # Custom object + field + validation rule
│   ├── lwc/realtorAdminDashboard/    # Lightning Web Component (admin dashboard)
│   ├── permissionsets/               # Realtor_Admin
│   ├── tabs/                         # Object tab'ları
│   ├── flexipages/                   # Sayfa tasarımları
│   ├── layouts/                      # Page layout'lar
│   ├── duplicateRules/ matchingRules/ # Buyer duplicate önleme
│   └── staticresources/ contentassets/
├── web/                              # Next.js 14 App Router
│   ├── app/
│   │   ├── page.tsx                  # İlan listesi (SSR)
│   │   ├── properties/[id]/page.tsx  # İlan detay + booking form
│   │   ├── realtors/[id]/page.tsx
│   │   └── api/
│   │       ├── properties/route.ts
│   │       └── bookings/route.ts
│   └── lib/salesforce.ts             # OAuth2 + REST entegrasyonu
├── scripts/
│   ├── apex/seed-realtor.apex        # Demo data
│   └── soql/account.soql
├── config/project-scratch-def.json
├── sfdx-project.json
└── package.json
```

---

## Production'a Geçerken Dikkat

Bu proje eğitim/demo amaçlıdır. Production'a taşırken **mutlaka** yapılması gerekenler:

- OAuth Username-Password Flow yerine **JWT Bearer Flow** veya **Client Credentials Flow** kullanın.
- `AddressVerificationService` içindeki optimistic check'i **Named Credential** üzerinden gerçek bir adres doğrulama API'sine (SmartyStreets, Google Address Validation) bağlayın.
- `Public_Listing__c = true` üzerinden yayınlanan kayıtlar için Salesforce **Sites** / **Experience Cloud** üzerinde guest user profiline minimum yetkiyi verin.
- Apex unit test coverage'ı %75 üzerine çıkarın (`RealtorPublicApiTest`, `*TriggerHandlerTest` sınıflarını ekleyin).
