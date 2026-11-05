# از کجا شروع کنم؟

## ۱. پاسخ کوتاه به سؤالت

**فایل TCL را مستقیم اجرا نکن.** تنها فایلی که اجرا میکنی
`vivado2023_2/run_vivado_2023_2.bat` است. خودش بهترتیب صدا میزند:

```
run_vivado_2023_2.bat  →  build_2023_2.tcl  →  add_system_2023_2.tcl  →  compat_2023_2.tcl
```

پس `build_2023_2.tcl`، `add_system_2023_2.tcl` و `compat_2023_2.tcl` را هم
دستی اجرا نکن؛ همه توسط همان `.bat` و در حالت batch بدون پنجرهٔ گرافیکی اجرا
میشوند.

## ۲. شاخهها جدا شدند

| شاخه | محتوا |
|---|---|
| `main` | فقط فایلهای اولیهٔ خودت (`matlab code for vivido ip/`، `add_system_original_backup.tcl`، `.gitattributes`) — دستنخورده |
| `arena/59036d27-amcdeployverify` | **فقط** کیت من، بدون هیچ فایلی از پروژهٔ اصلی |

PR شماره ۱ بسته شد، چون با این ساختار جدید، ادغام آن در `main` فایلهای خودت را پاک میکرد.
`main` امن است و هیچ فایلی از آن حذف نشده.

گیت هاب فقط محل نگهداری فایل است، جای اجرا نیست. این شاخه را دانلود کن
(**Code → Download ZIP**) و پوشههای `vivado2023_2`، `matlab` و `tools` را روی
کامپیوتر ویندوزیات، کنار پوشهٔ پروژه (`hdl_prj` و مدل
`soc_dlmc_rfsoc_zcu111.slx`) بگذار.

## ۳. فقط این ۴ کار، به ترتیب، روی کامپیوتر خودت

| # | کجا | چه کاری |
|---|---|---|
| ۱ | MATLAB R2025b | اجرای `matlab/setup_vivado_2023_2.m` (تنظیم مسیر ویوادو 2023.2 و ساخت IP هوش مصنوعی) |
| ۲ | Simulink / HDL Workflow Advisor | مراحل **۱٫۱ تا ۴٫۲** روی مدل `soc_dlmc_rfsoc_zcu111.slx`؛ در ۱٫۲ نام/مسیر/vendor ی IP را از `testbench_ip_core_report.html` بگذار. **مرحلهٔ ۴٫۳ را نزن** |
| ۳ | MATLAB | `patch_vivado_tcl_2023_2('C:\...\hdl_prj\vivado_ip_prj')` تا TCLهای ساختهشده پچ شوند |
| ۴ | ویندوز | چهار خط بالای `vivado2023_2/run_vivado_2023_2.bat` را پر کن و دابلکلیک کن → خروجی `system_wrapper.bit` |

بعدش طبق مستند MathWorks با همان `.bit` ادامه بده
(`socUpdateBitstreamBuildInfo` ← `programFPGA` ← `compile` / `deploy`).

اختیاری: `matlab/patch_reference_design_tool_version` را هم بزن تا خود Advisor
نسخهٔ 2023.2 را قبول کند.

## ۴. اینها را اجرا نکن

- `untitled.m` و `add_system_original_backup.tcl` — اگر کپیشان روی سیستمات هست، قدیمیاند.
- `tools/patch_vivado_tcl_for_2023_2.py` — همان کار مرحلهٔ ۳ است ولی با پایتون؛ یا آن را بزن یا دستور MATLAB را، نه هر دو.
- گام ۴٫۳ HDL Workflow Advisor — همانجاست که ویوادو GUI کرش میکرد.
- هر فایل `.tcl` بهصورت دستی.

جزئیات کامل در `README.md`. اگر خطا داد، `vivado2023_2/vivado_2023_2.log` را بفرست.
