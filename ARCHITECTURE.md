# QR Panel — Mimari Sözleşme (View / ViewModel / Session / Service / Model)

Bu doküman, QR Panel projesinin **tek resmi mimari sözleşmesidir**.  
Yeni sohbete geçtiğimde bu dosyayı yükleyip, aynı kurallarla devam ederim.

---

## 0) En Önemli 3 Kural (Kırmızı Çizgi)

1) **VIEW’da KESİNLİKLE sunucu hatası gösterilmez.**
    - UI sadece “kibar ve genel” mesaj gösterir:
        - “Bir şeyler ters gitti.”
        - “İşlem başarısız. Tekrar deneyin.”
    - **Detaylar sadece loglarda** (debug modda).

2) **Service ve Session ASLA aynı class içinde olmayacak.**
    - Service = Supabase/IO (network/storage/rpc)
    - Session = RAM cache/state
    - **İkisi sadece ViewModel içinde birleşir** (orkestrasyon).

3) **Her önemli işlem detaylı loglanır ama loglar yönetilebilir olmalı.**
    - Her class’ta `debugEnabled` (bool) ile aç/kapat.
    - Prod’da log = temiz/az, debug’da log = tam teşhis.

---

## 1) Katmanlar (5’li yapı)

### 1. View (UI / Widget)
**Sorumluluk:**
- Sadece UI çizer.
- Kullanıcı etkileşimlerini alır (tıklama, input).
- ViewModel çağırır (örn: `vm.addProduct(...)`, `vm.saveAllChanges()`).

**Yasaklar:**
- ❌ Supabase çağrısı yok
- ❌ Service çağrısı yok
- ❌ Sunucu hatası (exception, stack, rpc mesajı, DB hata kodu) gösterimi yok

**UI Error Policy (Zorunlu):**
- View’da gösterilecek hata sadece “genel” olmalı.  
  Örn:
    - “İşlem başarısız. Lütfen tekrar deneyin.”
    - “Kaydedilemedi.”

---

### 2. ViewModel (UI State + Orkestrasyon)
**Sorumluluk:**
- UI state tutar: `isLoading`, `isSaving`, `errorUi`, `activeMenuId`, `editedMenu` vb.
- Service çağırır, Session’a yazar.
- “Dirty (değişti mi?)” mantığını yönetir.
- Hata yönetimi + log standardı burada çalışır.

**Kural:**
- ViewModel = **use-case orchestrator (iş akışı orkestratörü)**
- Akış: UI event → VM → Service → Session update → UI update

---

### 3. Session (Cache / In-memory state)
**Sorumluluk:**
- Supabase’den çekilmiş verinin uygulama içindeki RAM cache hali.
- Hızlı erişim sağlar.
- Source of truth değildir.

**Kural:**
- Session **Supabase bilmez**.
- Session **fetch etmez**, sadece “set/get + notify” yapar.

**Örnek Session içerikleri:**
- `UserSession` = user + memberships + active business
- `MenuSession` = menus light + active menu full tree + edited menu tree (opsiyonel)

---

### 4. Service (Supabase bağlantı katmanı)
**Sorumluluk:**
- Supabase’e giden tüm IO burada:
    - `select/insert/update`
    - `rpc(...)`
    - `storage.upload`
- Stateless olmalı (state/cache tutmaz).

**Kural:**
- Uygulamanın başka hiçbir yerinde Supabase erişimi yok.
- Supabase client tek instance: `Supabase.instance.client` (veya DI ile tek client).

---

### 5. Models (Data Model / DTO)
**Sorumluluk:**
- Veri şekli: Menu, Category, Product, Ingredient...
- `toJson/fromJson` içerir.
- Stabil hash/canonical için gereken alanlar buradan gelir.

**Kural:**
- Model = veri
- ViewModel = davranış + UI state yönetimi

---

## 2) Veri Akışı (Standard Use Cases)

### A) Login → Bootstrap → Dashboard
1. View: Login butonu → `LoginViewModel.signInAndBootstrap()`
2. VM:
    - AuthService ile login
    - BusinessService ile memberships fetch
    - sonuç başarılıysa → Session’a yaz: `appSession.setUserSession(...)`
3. NextStep:
    - hiç business yok → create business
    - 1 business → dashboard
    - çok business → pick business

---

### B) Business seçildi → Menu ekranı hazırlanır
1. VM (veya BusinessSelect VM) aktif business seçer.
2. Session: `activeBusinessId` güncellenir.
3. Shell / Menu VM:
    - `fetchMenusLight(businessId)`
    - default active menu belirlenir
    - `fetchMenuFull(businessId, menuId)`
    - session’a yazılır (baseline + edited)

---

### C) Menüde edit → “Kaydet” aktif olsun (Dirty Detection)
**Mantık:**
- `baselineMenu` = server snapshot
- `editedMenu` = UI edit snapshot
- dirty = `baselineHash != editedHash`

**Stabil Hash için:**
- Canonical JSON: listeleri id’ye göre sort et
- Hash: `jsonEncode(canonical)` → stable string → stable hash

**Hash’e dahil olmayanlar:**
- `imagePath` (lokal) gibi sadece client’a özel alanlar.

---

### D) Kaydet (Tek RPC)
1. UI: “Kaydet” → `vm.saveAllChanges()`
2. VM:
    - `if (!dirty) return;`
    - image normalize:
        - `imagePath` varsa storage upload
        - `imageUrl` set
        - `imagePath` clear
    - payload: `menu.toJson(light:false)`
    - Service: `saveMenuTreeRPC(payload)`
3. Success:
    - baseline = normalized
    - edited = deep copy(baseline)
    - dirty false

---

---

## 4) Hata Politikası (UI vs Log)

### UI’da gösterilecek (Client-safe)
- “İşlem başarısız.”
- “Kaydedilemedi. Tekrar deneyin.”
- “Bağlantı sorunu olabilir.”

### UI’da ASLA gösterilmeyecek (Sensitive)
- Supabase RPC error message
- SQL hata detayı
- stacktrace
- endpoint, schema, tablo adları
- auth / permission hata içerikleri (RLS vb.)

**Kural:**
- Sunucu ile istemci arasında “ne olduğunu” UI asla anlatmaz.
- Detay = log (debug).

---

## 5) Loglama Standardı (Yönetilebilir ve Temiz)

### 5.1 Debug Toggle (Zorunlu)
Her Service ve VM içinde **tek bir toggle** olmalı:

- `final bool debugEnabled;` (constructor param)
- veya global: `AppLogConfig.debugEnabled`

**Kural:**
- Debug bittiğinde tek yerden kapatabilmeliyim.

---

### 5.2 Log Format (Zorunlu)
**ViewModel**
- `[MenuVM] ACTION START ...`
- `[MenuVM] STEP ...`
- `[MenuVM] DONE ... ms`
- `[MenuVM] ERROR ...` + (debug’da stack)

**Service**
- `[MenuService] method START ...`
- `[MenuService] RAW ... (count/keys/size)`
- `[MenuService] DONE ...`
- `[MenuService] ERROR ...` + (debug’da stack)

---

### 5.3 Önerilen ortak logger (tek yerden yönetim)
`lib/app/app_logger.dart`:

```dart
import 'package:flutter/foundation.dart';

class AppLog {
  static bool debugEnabled = true;

  static void d(String tag, String msg) {
    if (!debugEnabled) return;
    if (kDebugMode) debugPrint('[$tag] $msg');
  }

  static void e(String tag, String msg, {Object? error, StackTrace? st}) {
    if (!debugEnabled) return;
    if (kDebugMode) {
      debugPrint('[$tag] ERROR $msg');
      if (error != null) debugPrint('[$tag] error=$error');
      if (st != null) debugPrint('[$tag] stack=$st');
    }
  }
}
