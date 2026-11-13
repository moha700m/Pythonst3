# MASTER BUILD PROMPT — PYTHONST3

أنت فريق هندسي خبير مسؤول عن تنفيذ منتج حقيقي باسم **PYTHONST3** داخل هذا المستودع. اقرأ README.md وPROJECT_STATE.md وARCHITECTURE.md وROADMAP.md وSECURITY.md قبل أي تنفيذ، والتزم بها باعتبارها مصدر الحقيقة.

المستودع:
https://github.com/moha700m/Pythonst3

## المهمة

ابنِ تطبيقاً متكاملاً يتكون من:
1. تطبيق iOS أصلي SwiftUI قابل لإنتاج IPA بعد التوقيع.
2. موقع ويب متكامل وPWA.
3. تشغيل Python محلياً أولاً على كل منصة.
4. تصميم Cloud Linux Runtime اختياري للمشاريع غير المتوافقة، لكن لا تنشئه أو تنشره أو تتحمل أي تكلفة دون موافقة صريحة منفصلة.

لا تكتفِ بواجهة تجريبية. نفّذ، اختبر، أصلح، ووثّق.

## مبادئ إلزامية

- لا تنشئ موارد AWS أو Cloud أو قواعد بيانات أو خوادم أو نطاقات أو اشتراكات.
- لا تستخدم أي خدمة مدفوعة أو API مدفوع دون موافقة صريحة.
- لا تطلب من المستخدم مشاركة كلمات المرور أو مفاتيح خاصة في المحادثة.
- لا تضع أسراراً في Git أو ملفات Frontend أو سجلات CI.
- لا تدّعِ تشغيل كل مكتبات Python؛ أنشئ مصفوفة توافق واقعية لكل منصة.
- لا تنسخ تطبيق Pyto أو كوده. استخدم المشاريع المفتوحة كمراجع مع احترام تراخيصها وإشعاراتها.
- لا تدّعِ أن IPA جاهز للتثبيت ما لم يكن مبنياً وموقعاً ومتحققاً منه.
- لا تسجل ميزة مكتملة لمجرد وجود زر أو شاشة شكلية.

## A. Native iOS application

أنشئ مشروع SwiftUI منظم وقابل للبناء على Xcode.

### Python runtime
- استخدم CPython embedded عبر Python C API.
- قيّم Python-Apple-support / BeeWare كمسار البناء والتوزيع الأساسي.
- ثبّت نسخة Python ونسخة framework متوافقتين، وسجّل مصدرهما وتراخيصهما.
- لا تشغّل Python كعملية نظام مستقلة؛ المفسر embedded داخل التطبيق.
- نفّذ runtime manager مع حالة تحميل وتهيئة وأخطاء واضحة.
- نفّذ تشغيل الكود بعيداً عن MainActor مع احترام قيود CPython والتزامن.
- التقط stdout وstderr وtraceback.
- نفّذ input() عبر واجهة تفاعلية بين المفسر وواجهة SwiftUI.
- ادعم ملفات المشروع والاستيراد المحلي عبر sys.path مضبوط.
- خزّن المشاريع ضمن sandbox الخاص بالتطبيق، ووفّر File Import/Export عبر واجهات iOS الرسمية.
- لا تعد بدعم subprocess أو multiprocessing أو shell حقيقي على iOS.
- لا تعد بتثبيت pip عشوائي؛ اعرض المكتبات المدمجة أو المتوافقة فقط، واشترط wheel مبنياً لـ iOS/arm64 عند الحاجة.

### iOS UI
- تصميم Cyberpunk احترافي لكن Native، أسود/فحمي مع أخضر نيون وسماوي ولمسات بنفسجية.
- العربية RTL افتراضياً والإنجليزية اختيارية.
- محرر ملفات مع tabs وsyntax highlighting وsearch وline numbers.
- Explorer للمشاريع والمجلدات والملفات.
- Console تفاعلي، نتائج، أخطاء، وسجل تنفيذ.
- Run / Stop / Reset.
- Autosave واستعادة المشاريع.
- إعدادات حجم الخط والثيم ولوحة المفاتيح.
- دعم iPhone وiPad وSafe Areas وDynamic Type وVoiceOver.
- الكود LTR دائماً، بينما عناصر الواجهة تتبع اللغة.

## B. Web application

استخدم React + TypeScript + Vite، وCodeMirror 6 للمحرر، وPyodide لتشغيل Python داخل Web Worker.

الميزات:
- واجهة عربية RTL كاملة وإنجليزية اختيارية.
- محرر متقدم وتبويبات.
- شجرة ملفات ومشاريع.
- حفظ تلقائي في IndexedDB.
- إنشاء/استيراد/تصدير المشاريع وZIP.
- Pyodide Worker مع زر إيقاف وإعادة تشغيل وحدود وقت/مخرجات عملية.
- Console والتقاط stdout/stderr والأخطاء.
- input() بواجهة تفاعلية.
- Package Manager يعرض حالة توافق المكتبة قبل محاولة التثبيت.
- PWA وoffline app shell بعد اختبار التخزين الفعلي.
- دعم Safari iPhone وiPad وDesktop.
- لا تعرض Pyodide كأنه Linux كامل أو Python desktop بلا قيود.

## C. Shared project format

نفّذ تنسيق مشروع موحداً بين iOS والويب:
- manifest بإصدار schema.
- اسم المشروع وentrypoint.
- ملفات UTF-8 بمسارات نسبية.
- dependency declarations.
- metadata.
- ZIP import/export.
- validation ضد path traversal والملفات الضخمة.
- migrations عند تغير schema.

لا تخلط ملفات المنصة الخاصة مع ملفات مشروع Python المحمولة.

## D. AI assistant

ابنِ واجهة Provider Adapter اختيارية تدعم مزودات متوافقة عند إعدادها:
- Explain.
- Generate.
- Debug traceback.
- Refactor.
- Review.
- Tests.
- Documentation.
- Project context.

الأمان:
- لا تضع API keys في source code أو static web app.
- لا ترسل محتوى الملفات إلى AI دون إظهار ما سيُرسل وموافقة المستخدم.
- Agent يبدأ Read Only.
- التعديلات تعرض Diff/Patch قبل التطبيق.
- Auto Apply خيار صريح ومحدود بمجلد المشروع.
- وفر Undo.
- أي Backend Proxy أو AI hosting يتطلب موافقة تكلفة مستقلة.

## E. Cloud Runtime — design only until approved

صمم واجهة مستقبلية قابلة للتكامل، ولا تنشئ موارد فعلية.
عند الموافقة المستقبلية، يجب أن يكون التنفيذ داخل sandbox معزول قصير العمر، non-root، دون privileged mode أو Docker socket أو host mounts أو cloud credentials، مع CPU/RAM/time/output/storage limits، والشبكة مقفلة افتراضياً، والتنظيف التلقائي، والمصادقة، ومراقبة التكلفة وحد إنفاق. لا تنفذ untrusted Python داخل web server process.

اعرض للمستخدم اختيار Local أو Cloud، لكن أخفِ Cloud أو اعرضه كـ “غير مفعّل” حتى وجود خدمة آمنة وموافقة صريحة.

## F. GitHub Actions

أنشئ workflows منفصلة:
- CI للويب: npm ci، lint، typecheck، tests، production build.
- Web deploy إلى GitHub Pages بعد نجاح CI، مع base path صحيح لاسم المستودع.
- iOS build على macOS runner باستخدام Xcode بعد وجود مشروع iOS.
- simulator tests.
- device archive كخطوة منفصلة.
- signing فقط عند توفير المالك لأسرار التوقيع في GitHub Secrets.
- لا تضع شهادات أو provisioning profiles في Git.
- لا تدّعِ أن artifact غير الموقع IPA صالح للتثبيت.

لا تفعّل نشر الإنتاج أو تنشئ خدمة خارج GitHub دون توثيق ما سيتغير وموافقة المستخدم إذا ترتبت تكلفة.

## G. Quality gates

اختبر:
1. Python print.
2. arithmetic, functions, loops, collections.
3. multiple local modules.
4. input() interactive bridge.
5. syntax/runtime exceptions and traceback.
6. stdout/stderr.
7. project create/save/reopen/export/import.
8. invalid and traversal file paths.
9. supported vs unsupported packages.
10. runtime reset and interrupted execution.
11. UI remains responsive during execution.
12. iPhone Safari viewport and keyboard resizing.
13. iOS app sandbox and Files import/export.
14. AI disabled and configured states.
15. no secrets in built assets or repository.
16. web PWA cache behavior.
17. project portability between clients.

أنشئ اختبارات unit/integration واكتب خطوات real-device QA. لا تختلق نجاح اختبار لم يتم تشغيله.

## H. Delivery sequence

نفّذ وفق ROADMAP.md:
Phase 0 feasibility first. لا تقفز إلى بناء واجهات ضخمة قبل إثبات تشغيل CPython على iOS وPyodide على الويب.

بعد كل مرحلة:
- حدّث PROJECT_STATE.md.
- أضف نتائج الاختبارات الفعلية.
- وثّق القيود والقرارات.
- حافظ على تغييرات المستخدم ولا تستبدل ملفات موجودة دون فحص.

## Final report

قدّم:
- ما تم تنفيذه فعلياً.
- الملفات والتغييرات.
- Python version وruntime source.
- التوافق المعروف للمكتبات.
- نتائج CI والاختبارات وروابطها.
- رابط الموقع فقط بعد التحقق من النشر.
- IPA فقط بعد نجاح البناء والتوقيع والتحقق.
- أي متطلبات متبقية من المالك.
- تأكيد واضح بعدم إنشاء أي موارد مدفوعة دون موافقة.

**Build a real, secure, local-first Python IDE for iOS and the web. Never fake capability or test results.**
