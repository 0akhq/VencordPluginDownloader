# 0akh Vencord Plugin Yükleyici

Discord deneyimini kişiselleştirmek için geliştirdiğim **Vencord pluginleri** ve bunların kurulumunu otomatikleştiren **PowerShell installer**.

Bu proje sayesinde Git, Node.js, pnpm, Vencord ve plugin dosyalarıyla tek tek uğraşmadan gerekli kurulum işlemlerini otomatik olarak gerçekleştirebilirsin.

> **Not:** Bu proje Vencord üzerine kuruludur. Vencord'un kendisi bu projenin bir parçası değildir.

> **49251FE01354168F25846CCE334E2B5E4D99699FEE1794CAABFE316E175BF19D** 
> Güncel SHA256 değeri budur. İndirdiğiniz dosyanın SHA değerinin eşleştiğini kontrol etmek için terminalde şu komutu çalıştırabilirsiniz:
> `Get-FileHash ".\install.ps1" -Algorithm SHA256`

---

# Kullanım

1. ZIP dosyasını indirin ve istediğiniz bir klasöre ayıklayın.
2. Ayıklanan klasörde PowerShell açın.
3. Aşağıdaki komutu çalıştırın:

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1
```

## Özellikler

### 🖼️ Özel Arka Plan — `OzelArkaPlan`

Discord'un varsayılan görünümünü kendi wallpaper'ınla değiştirmene olanak sağlar.

Desteklenen özellikler:

* 🔗 URL üzerinden özel arka plan
* 🌑 Arka plan karartma
* 🌫️ Blur efekti
* 🎨 Renk doygunluğu ayarı
* ☀️ Parlaklık ayarı
* 🎨 Özel overlay rengi
* 🌈 Gradient overlay
* 📐 Arka plan konumu
* ⚙️ Vencord ayarlarından kolay yapılandırma

Amaç, Discord'u tamamen değiştirmek yerine mevcut Discord arayüzünü koruyarak arka plana kişisel bir görünüm kazandırmaktır.

---

### ✏️ SilentEdit

`SilentEdit`, Discord içerisinde mesaj düzenleme deneyimini daha sessiz ve dikkat çekmeden kullanmaya yönelik geliştirilmiş bir plugin'dir.

Plugin'in amacı mesaj düzenleme sırasında oluşan gereksiz görsel/arayüz bildirimlerini azaltarak daha temiz bir kullanım deneyimi sağlamaktır.

> Pluginin davranışı Vencord'un Discord arayüzüyle olan entegrasyonuna bağlı olarak değişebilir.
Orjinal Github: https://github.com/aurickk/SilentEdit-Vencord
---

# 🚀 Otomatik Installer

Projede ayrıca PowerShell tabanlı bir **otomatik Vencord Plugin Installer** bulunur.

Normalde Vencord'u kaynak koddan kurmak için Git, Node.js, pnpm, repository klonlama, dependency kurulumu, plugin klasörlerinin oluşturulması, build ve inject gibi işlemler gerekir.

Bu installer bu süreci mümkün olduğunca otomatik hale getirir.

### Installer'ın yaptığı işlemler

```text
Git kontrolü
      ↓
Node.js kontrolü
      ↓
pnpm kontrolü
      ↓
Vencord repository kontrolü
      ↓
Vencord clone / update
      ↓
pnpm install
      ↓
Plugin seçimi
      ↓
Plugin dosyalarının yerleştirilmesi
      ↓
pnpm build
      ↓
Discord inject
```

---

## 🧩 Plugin Seçimi

Installer çalıştırıldığında hangi pluginlerin kurulacağını seçebilirsin:

```text
[1] OzelArkaPlan
[2] SilentEdit

Birden fazla plugin:
1 2

Tüm pluginler:
hepsi
```

Pluginleri tek tek veya aynı anda kurabilirsin.

---

## 🔄 Vencord Güncelleme

Installer her çalıştırıldığında Vencord klasörünü kontrol eder.

Eğer daha önce kurulmuş bir Vencord repository'si varsa tekrar indirmek yerine:

```powershell
git pull --ff-only
```

kullanarak mevcut kurulumu günceller.

Bu sayede her güncellemede Vencord'u baştan klonlamak gerekmez.

---

## 📦 Otomatik Bağımlılık Kurulumu

Installer bilgisayarda gerekli araçları kontrol eder.

Eksik olan araçlar mümkün olduğunda otomatik olarak kurulmaya çalışılır:

* Git
* Node.js 22+
* pnpm

Node.js için Vencord'un güncel gereksinimlerine uygun sürüm kullanılır.

pnpm bulunmuyorsa resmi pnpm PowerShell installer'ı kullanılır.

---

## 📁 Oluşturulan Yapı

Pluginler Vencord'un `src/userplugins` yapısına otomatik olarak yerleştirilir:

```text
Vencord/
└── src/
    └── userplugins/
        ├── ozelArkaPlan/
        │   └── index.ts
        │
        └── silentEdit/
            └── index.tsx
```

Ardından Vencord build edilir ve Discord'a inject edilir.

---

## 🛠️ Manuel Kurulum

Installer kullanmak istemiyorsan işlemleri manuel olarak da gerçekleştirebilirsin.

```powershell
git clone https://github.com/Vendicated/Vencord.git
cd Vencord

pnpm install --frozen-lockfile
```

Daha sonra pluginleri:

```text
src/userplugins/
```

altına yerleştir.

Örneğin:

```text
src/userplugins/ozelArkaPlan/index.ts
```

ve:

```text
src/userplugins/silentEdit/index.tsx
```

Sonrasında:

```powershell
pnpm build
pnpm inject
```

çalıştır.

---

## ⚠️ Gereksinimler

* Windows
* PowerShell 5.1+
* İnternet bağlantısı
* Discord
* Git
* Node.js 22+
* pnpm

Git, Node.js ve pnpm sistemde bulunmuyorsa installer bunları otomatik olarak hazırlamayı dener.

---

## 📌 Projenin Amacı

Bu proje, Vencord kullanarak Discord'u kişiselleştirmek isteyen ancak her plugin için:

```text
git clone
pnpm install
klasör oluştur
dosya kopyala
pnpm build
pnpm inject
```

gibi işlemlerle tek tek uğraşmak istemeyen kullanıcılar için hazırlanmıştır.

Özellikle arkadaşlar arasında plugin paylaşımını kolaylaştırmak ve kurulumu birkaç dakikalık terminal işleminden mümkün olduğunca **tek bir installer deneyimine** dönüştürmek amaçlanmıştır.

---

## 👤 Author

**0akh**

Software Developer

---

## ⚖️ Disclaimer

Bu proje bağımsız bir topluluk projesidir ve Vencord veya Discord tarafından resmi olarak desteklenmemektedir.

Vencord, Discord ve ilgili markalar kendi sahiplerine aittir.

Pluginleri kullanmadan önce kullandığın Vencord sürümüyle uyumluluğunu kontrol etmen önerilir.
