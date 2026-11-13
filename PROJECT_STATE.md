# Pythonst3 — Project State

**آخر تحديث:** 2026-11-14  
**الفرع النشط:** `pythonista-ai-v2`  
**المستودع:** https://github.com/moha700m/Pythonst3  
**الفرع الأساسي:** `main`

## الحالة

- تطبيق iOS أصلي (SwiftUI) مع CPython 3.13.18 مدمج، يعمل محلياً على الجهاز.
- IPA غير موقّع يُبنى ويُتحقق منه في GitHub Actions على `macos-26` بـ SDK 26.5.
- الواجهة عربية RTL بهوية Cyberpunk، وتُختبر على أربعة مقاسات iPhone.
- المساعد الذكي يقترح كوداً، ويعرض Diff، ولا يكتب أي ملف قبل موافقة صريحة.

## أحدث بناء على الفرع

| البند | القيمة |
|---|---|
| Commit | `ebee7c5` |
| GitHub Actions | https://github.com/moha700m/Pythonst3/actions/runs/43516382766 |
| اختبار CPython | 1 اختبار / 0 فشل |
| SDK | 26.5 |
| فحص الشاشة الكاملة | 4 مقاسات عبر `pixel_probe.swift` |
| Artifact | `Pythonst3-unsigned-IPA` و`iphone-layout-screenshots` |
| التوقيع | غير موقّع — مسؤولية المالك عبر ESign |

### بناء main المرجعي (قبل دمج الفرع)

| البند | القيمة |
|---|---|
| Commit | `66bcbe1` |
| GitHub Actions | https://github.com/moha700m/Pythonst3/actions/runs/43504552227 |
| النتيجة | success |
| IPA | 20,374,940 بايت (غير موقّع) |
| SHA-256 | `a7d9d4faebd64575ebe48f736f942c5fa5e1f25cf59303822e967271d7299770` |
| محتوى IPA | 2,869 ملفاً، 69 إطاراً في `Frameworks/` |

## ما تم التحقق منه فعلياً

- بناء Release لـ `iphoneos arm64` بدون توقيع.
- وجود التنفيذي و`Info.plist` و`Python.framework` و`python/lib/python3.13/os.py` و`lib-dynload`.
- `CFBundleIdentifier = com.moha700m.pythonst3` و`MinimumOSVersion = 16.0` و`UILaunchScreen`.
- تشغيل CPython في المحاكي والتقاط `print()` — `Executed 1 test, with 0 failures`.
- **تحليل بكسلات لقطات main:** لا صفوف سوداء صلبة في أعلى/أسفل أي صورة من الثماني (17 Pro، 17 Pro Max، 16، SE).
- حارس CI يفشل إذا كان SDK البناء أقدم من 26.
- مسبار `--pythonst3-layout-probe` مع علامة `Documents/layout_probe.txt` للتأكد من وصول وضع الفحص.

### ملاحظة عن عطل سابق في الفحص

أول تشغيل للمسبار فشل لأن اللقطة التُقطت على شاشة الإقلاع، التي تستخدم نفس لون خلفية التطبيق `(4,6,8)`، فبدت كأنها letterboxing. الإصلاح: يكتب `RootView` ملف علامة بعد ظهور الواجهة، وينتظر السكربت هذا الملف قبل التصوير؛ كما نُقل الـ overlay إلى `.overlay` مع `ignoresSafeArea`.

## الميزات المنفذة

| المجال | الحالة | الدليل |
|---|---|---|
| CPython مدمج | منجز | اختبار المحاكي |
| محرر بتلوين Python وأرقام أسطر | منجز | `CodeEditorView` |
| مسافة بادئة تلقائية وإغلاق أقواس | منجز | `CodeEditorView` |
| لصق واضح من الحافظة | منجز | شريط الملحقات + بطاقة رئيسية + تلميح |
| وحدة تحكم + REPL مستمر | منجز | `pythonst3_repl` |
| إيقاف ومهلة تنفيذ | منجز | trace hook |
| مشاريع محلية وحفظ تلقائي | منجز | `ProjectStore` |
| استيراد/تصدير `.pythonst3` | منجز | JSON archive |
| مساعد AI (OpenRouter/OpenAI/Anthropic) | منجز | `AIClient` |
| اقتراح كود + Diff + موافقة + تراجع | منجز | `DiffApprovalView`, `AgentUndo` |
| Keychain للمفاتيح | منجز | `KeychainStore` |
| بناء IPA غير موقّع | منجز | `build-ipa.yml` |

## غير منفذ (لا توجد واجهات وهمية له)

- CodeMirror 6 أو محرر ويب داخل WKWebView.
- بحث واستبدال داخل الملف، تنقّل بين الرموز، طي الكود.
- مدير حزم يثبّت من PyPI (لا يوجد pip مدمج).
- مصحح بنقاط توقف ومتغيرات.
- Jupyter / NumPy / Pandas / Matplotlib.
- تكامل GitHub (OAuth، clone، commit، push).
- نماذج AI محلية عبر Core ML.
- منسّق وكلاء متعدد.
- استيراد/تصدير ZIP.
- الوضع الفاتح (التطبيق dark-only حالياً).

## حدود تقنية

- iOS لا يسمح بـ subprocess؛ التشغيل داخل عملية التطبيق وليس sandbox عملية منفصلة.
- `input()` عبر جسر SwiftUI، وليس stdin طرفياً.
- الإيقاف يعتمد على trace hook لكل سطر.
- حزم PyPI ذات امتدادات C تحتاج بناءً خاصاً لـ iOS arm64.
- REPL سطر واحد في كل مرة.
- الـ IPA غير موقّع، ويجب أن يوقّع ESign التطبيق و`Python.framework` وكل إطارات الامتداد الـ68.

## قواعد العمل

1. اقرأ هذا الملف و`ARCHITECTURE.md` قبل أي تغيير جوهري.
2. لا تسجل ميزة مكتملة اعتماداً على واجهة فقط.
3. لا تضف خدمة مدفوعة دون موافقة.
4. لا تضع مفاتيح أو شهادات في المستودع.
