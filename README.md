IZ • Panel (Flutter) – Architecture & Context
1. Projenin Amacı

Bu proje, kafe/restoran işletmeleri için geliştirilen çok katmanlı bir dijital yönetim panelidir.

Ana hedef:

Menü oluşturma ve düzenleme

Ürün / içerik / bileşen hiyerarşisi yönetimi

Kampanya (event) ve paket (combo) tanımlama

Anlık sipariş ve analiz altyapısına veri hazırlama

İleride ML tabanlı öneri ve optimizasyon sistemine zemin hazırlama

Bu panel, çok kiracılı (multi-tenant) bir Supabase backend’e bağlıdır.
Her işletme kendi business_id’sine sahiptir ve tüm veri izolasyonu buna göre yapılır.

2. Genel Mimari Yaklaşım

Flutter tarafında:

Pattern: MVVM (Model – View – ViewModel)

State yönetimi: Provider

Backend: Supabase RPC-first yaklaşım

Veri yazımı: “Anında kaydet” (instant save)

Büyük JSON tree gönderme YOK

Her entity tek tek create/update/delete edilir

Önemli Karar

Başlangıçta tüm menü ağacını toplu kaydetme düşünülüyordu.
Bu terk edildi.

Yeni yaklaşım:

İlk girişte: fetch_menu_full (tek sefer)

Sonrasında:

Category kaydet → RPC

Product kaydet → RPC

Ingredient ekle → RPC

Combo kaydet → RPC

Event kaydet → RPC

Her entity kendi yaşam döngüsünü yönetir.

3. Veri Modeli (Frontend)
   Hiyerarşi

Menu
└── Categories
└── Products
├── ProductIngredients (ingredient_library reference)
└── Extras
└── IngredientLibrary
└── Combos
└── Events

Önemli Model Kuralları

ID'ler uuid veya tmp_* olabilir.

tmp_* id’ler backend tarafında uuid’ye map edilir.

Backend her save işleminde id_map dönebilir.

ViewModel id_map’i uygulamalıdır.

4. Flutter Katmanları
   4.1 Models

Pure data classes.
No business logic inside.

Örnek:

MenuModel

CategoryModel

ProductModel

IngredientLibraryItemModel

ProductIngredientModel

ComboModel

EventModel

Models immutable olmalı.
copyWith desteklemeli.

4.2 Services Layer

MenuService:

RPC çağrılarını içerir.

Supabase.instance.client.rpc(...)

JSON serialization/deserialization burada yapılır.

UI logic içermez.

State tutmaz.

Örnek metodlar:

fetchMenuFull

upsertMenu

upsertCategory

upsertProduct

deleteProduct

upsertCombo

upsertEvent

deleteX

Service sadece network katmanıdır.

4.3 ViewModel Layer

MenuViewModel:

Uygulamanın in-memory state’ini tutar.

Menü ağacını memory’de saklar.

UI ile Service arasında köprüdür.

Optimistic update yapılabilir.

RPC sonrası id_map uygular.

Hata durumunda rollback stratejisi olabilir.

ViewModel sorumlulukları:

Yeni kategori oluştur

Ürün ekle

Ürün düzenle

Ingredient ekle

Combo kaydet

Event kaydet

4.4 View Layer

Stateless mümkün olan yerde.

ViewModel provider üzerinden alınır.

UI doğrudan Supabase çağırmaz.

Modal sheet → result döner → ViewModel.saveX()

5. Kimlik & Yetki Modeli

Flutter tarafında:

auth state Supabase üzerinden alınır.

business_id session üzerinden belirlenir.

Tüm RPC çağrıları business_id ile yapılır.

Client tarafında yetki kontrolü yapılmaz (UI seviyesinde sadece görünürlük).

Gerçek güvenlik backend’dedir.

6. Instant Save Stratejisi
   Neden toplu kaydetme yok?

Büyük JSON payload maliyetli.

Conflict yönetimi zor.

Partial failure riski yüksek.

UX gecikmesi fazla.

Yeni Model

Her entity:

Oluştur → RPC

Düzenle → RPC

Sil → RPC

Product save:

Product upsert

Ingredients replace

Hepsi tek RPC transaction içinde.

7. ID Stratejisi

Frontend:

Yeni entity oluşturulunca:
tmp_1234 gibi id üretilebilir.

Save sonrası:
Backend id_map dönebilir.

ViewModel:
tmp id → gerçek uuid replace eder.

Bu sayede optimistic UI mümkün.

8. Hata Yönetimi

ViewModel:

try/catch

UI loading state

error snackbar

rollback gerekiyorsa eski state restore

RPC error string parse edilmez.
Sadece exception gösterilir.

9. Performans Prensipleri

Full menu fetch sadece ilk load.

Sonraki işlemler granular.

Gereksiz refetch yok.

Pagination ileride eklenebilir.

Local cache opsiyonel.

10. Gelecek Aşamalar

Planlanan gelişmeler:

Stok yönetimi (ingredient bazlı)

Analytics integration

ML-based öneri

Order realtime akışı

Offline-first cache

11. Kod Standartları

Null-safe

Strict typing

No dynamic map propagation

All JSON parsing centralized

ViewModel içinde network çağrısı yok (Service üzerinden)

12. GPT Codex'ten Beklenenler

Bu projede kod üretirken:

Mevcut mimariyi bozma.

MVVM’i koru.

Service katmanını atlama.

RPC-first yaklaşımı sürdür.

Model yapısını değiştirme.

UI → ViewModel → Service → RPC zincirini koru.

tmp id → id_map mekanizmasını dikkate al.

Cross-tenant mantığı backend’de; frontend sade kalmalı.

13. Özet

Bu proje:

Multi-tenant

RPC-driven

Instant save

MVVM Flutter

Güvenlik backend’de

Minimal refetch

Ölçeklenebilir menü sistemi

Frontend tarafı:

Basit, deterministik, state merkezli.

Backend:

Güvenlik ve veri bütünlüğü merkezli.