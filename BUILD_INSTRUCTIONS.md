# Build & Install Instructions

## 1. البناء عبر GitHub Actions (المسار المعتمد)

1. ادفع إلى `main` أو شغّل يدوياً:
   ```bash
   gh workflow run build-ipa.yml --ref main
   ```
2. راقب التشغيل:
   ```bash
   gh run list --workflow build-ipa.yml
   gh run watch <run-id>
   ```
3. نزّل الـ IPA:
   ```bash
   gh run download <run-id> -n Pythonst3-unsigned-IPA
   ```

سير العمل يقوم بالتالي بالترتيب:

1. `actions/checkout`
2. طباعة نسخة Xcode وSwift
3. تثبيت XcodeGen
4. تنزيل CPython 3.13.18 من Python-Apple-support والتحقق من SHA-256
5. توليد `Pythonst3.xcodeproj`
6. بناء Release لـ `iphoneos` بدون توقيع
7. التحقق من وجود التنفيذي و`Python.framework` والمكتبة القياسية و`lib-dynload`
8. التحقق من `CFBundleIdentifier` و`MinimumOSVersion` و`UILaunchScreen`
9. التأكد أن SDK البناء ≥ 26 (منع letterboxing على iOS 26)
10. تشغيل اختبار CPython على محاكي iPhone 17 Pro
11. التقاط لقطات على 4 مقاسات + فحص بكسلات يثبت أن التطبيق يملأ الشاشة
12. تجهيز `Payload/Pythonst3.app` وضغطه كـ `.ipa`
13. التحقق من محتويات الـ IPA
14. رفع `Pythonst3-unsigned-IPA` و`iphone-layout-screenshots`

## 2. البناء محلياً على macOS

المتطلبات: Xcode 26+، XcodeGen، اتصال إنترنت لتنزيل CPython مرة واحدة.

```bash
brew install xcodegen
./Scripts/fetch_python.sh
xcodegen generate --spec project.yml
xcodebuild -project Pythonst3.xcodeproj -scheme Pythonst3 \
  -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  CODE_SIGN_ENTITLEMENTS="" DEVELOPMENT_TEAM="" ONLY_ACTIVE_ARCH=NO build
```

## 3. تجهيز IPA غير موقّع

```bash
rm -rf Payload Pythonst3-unsigned.ipa
mkdir Payload
cp -R build/Build/Products/Release-iphoneos/Pythonst3.app Payload/
zip -qry Pythonst3-unsigned.ipa Payload
shasum -a 256 Pythonst3-unsigned.ipa
```

## 4. التثبيت عبر ESign

1. نزّل `Pythonst3-unsigned.ipa` من Artifact.
2. افتحه في ESign (Share → Open in ESign أو من داخل التطبيق).
3. اختر شهادة التوقيع الخاصة بك.
4. **مهم:** ESign يجب أن يوقّع:
   - `Payload/Pythonst3.app/Pythonst3`
   - `Payload/Pythonst3.app/Frameworks/Python.framework`
   - كل `*.framework` داخل `Frameworks/` (68+ إطار امتداد)
5. ثبّت التطبيق، ثم ثق بالمطور من Settings → General → VPN & Device Management.
6. عند أول تشغيل، افتح المحرر مباشرة واكتب أو الصق كوداً ثم اضغط «تشغيل».

> الـ IPA غير موقّع ولن يُثبَّت قبل توقيعه. لا توجد شهادات أو مفاتيح في المستودع.


## 5. بناء C++ إلى EXE على Windows

هذا سير مستقل عن بناء تطبيق iOS:

- Workflow: `.github/workflows/build-cpp-windows.yml`
- Runner: `windows-latest` مع MSVC x64.
- المعايير: C++14 وC++17 وC++20 وC++23.
- الأنواع: `CONSOLE` أو `WINDOWS`.
- الناتج: `main.exe` و`main.cpp` و`build.log` و`build-info.txt` داخل Artifact ZIP لمدة 3 أيام.

### التشغيل اليدوي

1. افتح تبويب Actions ثم اختر **Windows C++ Build**.
2. اضغط **Run workflow**.
3. أدخل `request_id` فريداً.
4. حوّل ملف `main.cpp` إلى Base64 UTF-8 وألصقه في `source_b64`.
5. اختر معيار C++ ونوع البرنامج ثم شغّل Workflow.
6. نزّل Artifact باسم `windows-cpp-build-<request_id>` بعد نجاح البناء.

مثال PowerShell لتحويل الملف:

```powershell
$source = Get-Content -Raw .\main.cpp
$b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($source))
```

### ربط M C++ Studio

- يُحفظ Fine-grained Personal Access Token في AppDeploy Secrets باسم `GITHUB_ACTIONS_TOKEN`.
- امنح الرمز صلاحية **Actions: Read and write** على مستودع `Pythonst3` فقط.
- لا تضع الرمز في المستودع أو داخل كود الواجهة.
- يرسل الموقع طلب `workflow_dispatch` ويتابع حالة التشغيل ثم يعرض رابط Artifact.

> تنبيه: GitHub-hosted Windows runner مخصص للبناء غير التفاعلي؛ لا يعرض نافذة البرنامج داخل المتصفح ولا يشغّل EXE بعد بنائه. المعاينة والتحكم في واجهة Windows يتطلبان Windows Worker ذاتياً مع جلسة سطح مكتب تفاعلية مرئية. سير البناء الحالي لا يشغّل ملفات المستخدم التنفيذية.
