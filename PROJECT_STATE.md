# Pythonst3 — Project State

**آخر تحديث:** 2026-11-13  
**الحالة:** iOS MVP منفّذ — CPython مدمج ومُتحقق منه — سير بناء IPA غير موقّع ناجح  
**المستودع:** moha700m/Pythonst3  
**الفرع الأساسي:** main

## القرار المعتمد

- تطبيق iOS أصلي بصيغة IPA عند اكتمال البناء والتوقيع.
- موقع ويب متكامل وPWA (لم يُنفّذ في هذه المرحلة).
- تشغيل Python محلياً أولاً.
- Cloud Linux Runtime اختياري فقط عندما لا تكفي البيئة المحلية.
- لا موارد AWS أو Cloud أو خدمات مدفوعة قبل موافقة صريحة.
- لا مفاتيح أو أسرار أو شهادات توقيع داخل Git.

## أحدث بناء iOS

| البند | القيمة |
|---|---|
| Commit البناء | `63b9289be41922b40ce46a4098c8458c6793e92e` |
| GitHub Actions | https://github.com/moha700m/Pythonst3/actions/runs/43499206551 |
| Artifact | `Pythonst3-unsigned-IPA` |
| حجم الـ IPA | 19,555,549 بايت |
| SHA-256 | `3de9eac4f24b2d6e4b79811564b7fa3624e9bbed70fb1febee6d9f4b10c921ec` |
| اختبار التشغيل | `PythonRuntimeTests.testEmbeddedPythonExecutesAndCapturesOutput` — نجح، 1 اختبار / 0 فشل |
| نتيجة السير | success |

### ما تم التحقق منه فعلياً

- بناء Release لجهاز iOS arm64 مع تعطيل التوقيع.
- وجود `Pythonst3.app/Pythonst3` و`Info.plist` و`Frameworks/Python.framework/Python`.
- وجود `python/lib/python3.13/os.py` و`lib-dynload`.
- تحويل 68 وحدة امتداد إلى `*.framework` مع ملفات `.fwork` و`.origin`.
- التحقق من `CFBundleIdentifier = com.moha700m.pythonst3` داخل الـ IPA.
- تشغيل CPython داخل محاكي iOS وتنفيذ `print('PYTHONST3_SMOKE_OK')` والتقاط الإخراج.
- رفع `Pythonst3-unsigned.ipa` مع ملف SHA-256.

## بنية المنتج المستهدفة

| المكوّن | التقنية | الغرض |
|---|---|---|
| iOS App | SwiftUI | تجربة أصلية للآيفون والآيباد |
| Embedded Python | CPython 3.13.18 عبر Python-Apple-support 3.13-b18 | تنفيذ محلي داخل التطبيق |
| Web App | React + TypeScript + Vite | تجربة المتصفح (مؤجلة) |
| Web Runtime | Pyodide + Web Workers | تنفيذ Python المتوافق داخل المتصفح (مؤجل) |
| Editor | UITextView مخصص + تلوين نحوي | محرر مناسب للمس |
| Local Projects | iOS Files APIs + JSON project format v1 | حفظ المشاريع محلياً |
| AI | Provider adapters اختيارية | شرح وتصحيح وتوليد ومراجعة |
| Cloud Runtime | تصميم مؤجل، Linux containers | توافق أوسع عند الحاجة |
| CI | GitHub Actions | بناء واختبار وإنتاج IPA |

## الحالة الفعلية

- [x] التحقق من المستودع وصلاحية الكتابة.
- [x] اعتماد معمارية iOS + Web.
- [x] اعتماد local-first وcloud-optional.
- [x] كتابة وثائق الرؤية والمعمارية والخطة والبرومبت.
- [x] إنشاء تطبيق SwiftUI ومشروع Xcode عبر XcodeGen.
- [x] دمج CPython والتحقق من التهيئة والتنفيذ في المحاكي.
- [x] بناء واجهة محرر iOS العربية RTL مع تلوين Python وتبويبات ووحدة تحكم.
- [x] مشاريع محلية، حفظ تلقائي، استيراد/تصدير، وإعدادات.
- [x] AI Provider Adapter مع تخزين المفتاح في Keychain وعدم إرسال أي كود تلقائياً.
- [x] بناء iOS على macOS CI.
- [x] إنتاج IPA غير موقّع والتحقق من بنيته.
- [x] اختبار تشغيل مفسر Python على محاكي iOS.
- [ ] توقيع IPA بمفاتيح المالك (ESign) — مسؤولية المالك.
- [ ] Web App وPyodide.
- [ ] مزامنة المشاريع بين iOS والويب.

## حدود تقنية يجب عدم إخفائها

- iOS يشغّل Python في وضع embedded داخل التطبيق، وليس كـ system Python عام.
- لا يمكن الاعتماد على subprocess أو multiprocessing أو IPC التقليدي في iOS.
- لا يوجد stdin طرفي أصلي؛ `input()` يُنفّذ عبر جسر واجهة SwiftUI.
- Stop/timeout يعتمد على trace hook لكل سطر؛ العمليات الأصلية الطويلة قد لا تتوقف فوراً.
- لا يوجد pip عشوائي؛ فقط المكتبة القياسية والوحدات النقية المضمنة.
- Pyodide لا يساوي Linux ولا يدعم جميع حزم PyPI.
- الـ IPA غير موقّع وغير قابل للتثبيت قبل توقيعه بواسطة المالك.
- ESign يجب أن يوقّع التطبيق و`Python.framework` وكل إطارات الامتداد داخل `Frameworks/`.

## قواعد العمل

1. اقرأ هذا الملف وARCHITECTURE.md قبل أي تغيير جوهري.
2. حدّث الحالة بعد كل مرحلة مكتملة، مع أدلة الاختبار.
3. لا تسجل ميزة على أنها مكتملة اعتماداً على واجهة شكلية فقط.
4. لا تغيّر المعمارية أو تضف خدمة مدفوعة دون موافقة المستخدم.
5. استخدم إصدارات مثبتة ومراجعة، ولا تعتمد على latest بشكل أعمى.
