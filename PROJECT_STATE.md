# Pythonst3 — Project State

**آخر تحديث:** 2026-11-14  
**الفرع النشط:** `pythonista-ai-v2` (مدموج في `main` بعد نجاح البناء)  
**المستودع:** https://github.com/moha700m/Pythonst3  
**الفرع الأساسي:** `main`

## الحالة

- تطبيق iOS أصلي (SwiftUI) مع CPython 3.13.18 مدمج، يعمل محلياً على الجهاز.
- IPA غير موقّع يُبنى ويُتحقق منه في GitHub Actions على `macos-26` بـ SDK 26.5.
- الواجهة عربية RTL بهوية Cyberpunk، ومُتحقَّق منها بكسلّياً على أربعة مقاسات iPhone.
- المساعد الذكي يقترح كوداً، ويعرض Diff، ولا يكتب أي ملف قبل موافقة صريحة.

## أحدث بناء موثّق

| البند | القيمة |
|---|---|
| Commit | `e623b2f` |
| GitHub Actions | https://github.com/moha700m/Pythonst3/actions/runs/43520998546 |
| النتيجة | success |
| اختبار CPython | 1 اختبار / 0 فشل |
| SDK | 26.5 |
| فحص الشاشة الكاملة | 4 مقاسات، `rgb=255,0,255` على الحواف |
| IPA | 20,531,686 بايت (غير موقّع) |
| SHA-256 | `32cb45ecd30168b8ca38243b8a7275ef6cd145bc0e9e82fba4b8c2a546c4fd64` |
| محتوى IPA | 2,869 ملفاً، 69 إطاراً في `Frameworks/` |
| Artifact | `Pythonst3-unsigned-IPA` (id 14083794746) |

### أدلة فحص الشاشة الكاملة (من سجل CI)

| الجهاز | مساحة التطبيق | البكسلات | النتيجة |
|---|---|---|---|
| iPhone 17 Pro | 402×874 @3x | 1206×2622 | verified |
| iPhone 17 Pro Max | 440×956 @3x | 1320×2868 | verified |
| iPhone 16 | 393×852 @3x | 1179×2556 | verified |
| iPhone SE (3rd) | 375×667 @2x | 750×1334 | verified |

المسبار يرسم أشرطة ماجنتا 8pt على الحواف الحقيقية، والعيّنات أعادت `rgb=255,0,255` في أعلى ويمين وأسفل الشاشة. كما أن `UIScreen` داخل التطبيق يطابق مقاس الجهاز، أي لا يوجد letterboxing.

## ما تم التحقق منه فعلياً

- بناء Release لـ `iphoneos arm64` بدون توقيع.
- وجود التنفيذي و`Info.plist` و`Python.framework` و`python/lib/python3.13/os.py` و`lib-dynload`.
- `CFBundleIdentifier = com.moha700m.pythonst3` و`MinimumOSVersion = 16.0` و`UILaunchScreen`.
- تشغيل CPython في المحاكي والتقاط `print()`.
- تحليل بكسلات لقطات main السابقة: لا صفوف سوداء صلبة في أي صورة.
- حارس CI يفشل إذا كان SDK البناء أقدم من 26.
- فحص IPA: 69 إطاراً، وSHA-256 مطابق للملف.

## الميزات المنفذة

| المجال | الحالة | الدليل |
|---|---|---|
| CPython مدمج وتشغيل محلي | منجز | اختبار المحاكي |
| محرر بتلوين Python وأرقام أسطر | منجز | `CodeEditorView` |
| مسافة بادئة تلقائية وإغلاق أقواس | منجز | `CodeEditorView` |
| بحث واستبدال داخل الملف | منجز | `FindReplaceView` |
| تمييز سطر الخطأ من traceback | منجز | `PythonRuntime.parseErrorLocation` |
| لصق واضح من الحافظة | منجز | شريط الملحقات + البطاقة الرئيسية |
| وحدة تحكم + REPL مستمر | منجز | `pythonst3_repl` |
| إيقاف ومهلة تنفيذ | منجز | trace hook |
| قوالب مشاريع (6) | منجز | `ProjectTemplate` |
| مشاريع محلية وحفظ تلقائي | منجز | `ProjectStore` |
| استيراد/تصدير `.pythonst3` | منجز | JSON archive |
| مساعد AI بأوضاع ستة | منجز | `AIAssistantView` |
| اقتراح كود + Diff + موافقة + تراجع | منجز | `DiffApprovalView`, `AgentUndo` |
| OpenRouter / OpenAI / Anthropic | منجز | `AIClient` |
| Keychain للمفاتيح | منجز | `KeychainStore` |
| بناء IPA غير موقّع | منجز | `build-ipa.yml` |

## غير منفذ (لا توجد واجهات وهمية له)

- CodeMirror 6 أو محرر ويب داخل WKWebView.
- تنقّل بين الرموز، طي الكود، وتعدد المؤشرات.
- مدير حزم يثبّت من PyPI (لا يوجد pip مدمج).
- مصحح بنقاط توقف ومتغيرات (المتوفر: تمييز سطر الخطأ فقط).
- Jupyter / NumPy / Pandas / Matplotlib.
- تكامل GitHub (OAuth، clone، commit، push).
- نماذج AI محلية عبر Core ML.
- منسّق وكلاء متعدد.
- استيراد/تصدير ZIP.
- الوضع الفاتح (التطبيق dark-only).

## حدود تقنية

- iOS لا يسمح بـ subprocess؛ التشغيل داخل عملية التطبيق وليس sandbox عملية منفصلة.
- `input()` عبر جسر SwiftUI، وليس stdin طرفياً.
- الإيقاف يعتمد على trace hook لكل سطر.
- حزم PyPI ذات امتدادات C تحتاج بناءً خاصاً لـ iOS arm64.
- REPL سطر واحد في كل مرة.
- الـ IPA غير موقّع، ويجب أن يوقّع ESign التطبيق و`Python.framework` و68 إطار امتداد.

## قواعد العمل

1. اقرأ هذا الملف و`ARCHITECTURE.md` قبل أي تغيير جوهري.
2. لا تسجل ميزة مكتملة اعتماداً على واجهة فقط.
3. لا تضف خدمة مدفوعة دون موافقة.
4. لا تضع مفاتيح أو شهادات في المستودع.
