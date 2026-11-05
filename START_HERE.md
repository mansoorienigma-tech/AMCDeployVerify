# از کجا شروع کنم؟

## ۱. نگران «قاطی شدن» نباش

هیچ فایلی از شما عوض یا حذف نشده است. گیت در هر شاخه **تمام** پروژه را نشان
میدهد، برای همین فایلهای قدیمی و جدید کنار هم دیده میشوند.

| فایلهای شما (دستنخورده) | فایلهایی که من اضافه کردم |
|---|---|
| `matlab code for vivido ip/` (شامل `untitled.m`) | `vivado2023_2/` |
| `add_system_original_backup.tcl` | `matlab/` |
| `.gitattributes` | `tools/` |
| | `README.md`، `START_HERE.md`، `.gitignore` |

`main` فقط فایلهای خودتان را دارد. این شاخه همان فایلها **به اضافهٔ** کیت
سازگاری 2023.2 است. PR شماره ۱ دقیقاً همان فایلهای اضافهشده را نشان میدهد.

## ۲. گیت هاب جای اجرا نیست

هیچ فایلی در سایت گیت هاب اجرا نمیشود. پوشههای `vivado2023_2`، `matlab` و
`tools` را روی کامپیوتر ویندوزی خودتان، کنار پوشهٔ پروژه (`hdl_prj` و مدل
`soc_dlmc_rfsoc_zcu111.slx`) کپی کنید، یا شاخه را Clone کنید.

**همهٔ مراحل زیر روی همان کامپیوتر خودتان است**، با MATLAB R2025b و
Vivado 2023.2.

## ۳. فقط این ۴ کار را به ترتیب انجام بده

| # | کجا | چه کاری |
|---|---|---|
| ۱ | MATLAB | اجرای `matlab/setup_vivado_2023_2.m` (مسیر ویوادو 2023.2 را تنظیم و IP هوش مصنوعی را میسازد) |
| ۲ | Simulink / HDL Workflow Advisor | مراحل **۱٫۱ تا ۴٫۲** روی مدل `soc_dlmc_rfsoc_zcu111.slx`؛ در ۱٫۲ نام/مسیر/vendor ی IP را از `testbench_ip_core_report.html` بگذار. **مرحلهٔ ۴٫۳ را نزن** |
| ۳ | MATLAB | `patch_vivado_tcl_2023_2('C:\...\hdl_prj\vivado_ip_prj')` تا TCLهای ساختهشده پچ شوند |
| ۴ | ویندوز | چهار خط بالای `vivado2023_2/run_vivado_2023_2.bat` را پر کن و دابلکلیک کن → خروجی `system_wrapper.bit` |

بعد از آن، طبق مستند MathWorks با همان `.bit` ادامه بده
(`socUpdateBitstreamBuildInfo` ← `programFPGA` ← `compile` / `deploy`).

اختیاری: `matlab/patch_reference_design_tool_version` هم بزن تا خود Advisor
نسخهٔ 2023.2 را قبول کند.

## ۴. اینها را اجرا نکن

- `untitled.m` و `add_system_original_backup.tcl` → فقط نسخهٔ مرجع قدیمیاند.
- `tools/patch_vivado_tcl_for_2023_2.py` → همان کار مرحلهٔ ۳ است، ولی با پایتون. یا آن را بزن یا دستور MATLAB را، نه هر دو.
- `vivado2023_2/compat_2023_2.tcl` و `build_2023_2.tcl` → خود `.bat` آنها را صدا میزند؛ دستی لازم نیست.
- گام ۴٫۳ HDL Workflow Advisor → همانجاست که ویوادو GUI کرش میکرد.

جزئیات کامل در `README.md` است. اگر خطا داد، فایل `vivado2023_2/vivado_2023_2.log`
را بفرست.
