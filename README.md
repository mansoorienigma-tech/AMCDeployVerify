# اجرای پروژه روی Vivado 2023.2 (بدون نصب 2024.1)

همهٔ تغییرات لازم در همین ریپو انجام شده است. اصل ماجرا این است: مثال R2025b و
فایل `add_system_original_backup.tcl` برای Vivado 2024.1 ساخته شده بودند؛ عوض
کردن عدد نسخه در TCL بهتنهایی کافی نیست، چون ویوادو هنگام اضافه کردن IP هوش
مصنوعی وارد `regenerate_bd_layout` (محیط گرافیکی) میشود و کرش میکند. نسخهٔ 2023.2
بیشتر IPهای موردنیاز (RFDC 2.6، Zynq PS، DDR4، clk_wiz و …) را دارد؛ مشکل
اصلی همان بررسی نسخه، مسیر فایلها و فرمانهای GUI بود.

## فایلهایی که اضافه/تغییر کردم

| فایل | کارش |
|---|---|
| `vivado2023_2/compat_2023_2.tcl` | لایهٔ سازگاری: چک نسخهٔ نرمان، پیدا کردن نسخهٔ موجود هر IP در کاتالوگ 2023.2، اعمال CONFIGها تکتک، حذف فرمانهای GUI، پیام خطای خوانا |
| `matlab/patch_vivado_tcl_2023_2.m` | هر TCL ساختهشده توسط HDL Workflow Advisor را پچ میکند (بکاپ `*.2024_1.bak` میگیرد)؛ نیازی به پایتون نیست |
| `tools/patch_vivado_tcl_for_2023_2.py` | همان کار، بهصورت خط فرمان (اختیاری) |
| `vivado2023_2/add_system_2023_2.tcl` | نسخهٔ آمادهٔ پچشدهٔ همان `add_system_original_backup.tcl` |
| `vivado2023_2/build_2023_2.tcl` | اجراکنندهٔ کامل در حالت batch: ساخت بلاک دیزاین + IP هوش مصنوعی + سنتز + بیتستریم، بدون باز کردن پنجرهٔ ویوادو |
| `vivado2023_2/run_vivado_2023_2.bat` | دابلکلیک کنید؛ ویوادو 2023.2 را با `-mode batch` اجرا میکند و لاگ مینویسد |
| `matlab/setup_vivado_2023_2.m` | تنظیم مسیر 2023.2، `AllowUnsupportedToolVersion` و ساخت دوبارهٔ IP هوش مصنوعی |
| `matlab/patch_reference_design_tool_version.m` | اختیاری: اضافه کردن `'2023.2'` به `SupportedToolVersion` رفرنسدیزاین تا خود Workflow Advisor هم گیر ندهد |

`add_system_original_backup.tcl` و `untitled.m` دستنخورده ماندند تا مرجع باشند.

## نکتهٔ مهم قبل از شروع

این ریپو فقط خروجیهای VHDL و بکاپ TCL را دارد؛ **پروژهٔ قابل اجرا نیست**. اینها
باید روی سیستم خودتان وجود داشته باشند (از همان مثال MathWorks):

- مدل `soc_dlmc_rfsoc_zcu111.slx`،
- پوشهٔ `hdl_prj` که مرحلهٔ 4.1 میسازد، بهخصوص `add_pl_ddr.tcl`، `add_rfdc_ip.tcl`،
  `constr.xdc` و `ipcore/tclutils/*.tcl` (شامل `add_DLIP.tcl`)،
- IP بستهبندی شدهٔ هوش مصنوعی (`component.xml`) و فایل `testbench_ip_core_report.html`.

اگر مدل را ندارید، در MATLAB بزنید:
`openExample('soc/ModulationClassificationDeploymentOnRFSoCDevicesExample')`.

## مراحل اجرا

1. در MATLAB R2025b اسکریپت `matlab/setup_vivado_2023_2.m` را اجرا کنید. مسیر
   `C:\Xilinx\Vivado\2023.2\bin\vivado.bat` در بالای فایل قابل ویرایش است.
2. (اختیاری، توصیه میشود) `matlab/patch_reference_design_tool_version` را اجرا کنید
   تا Advisor نسخهٔ 2023.2 را به رسمیت بشناسد. اگر پیام «فایلی پیدا نشد» داد،
   متغیر `MW_SUPPORT_PACKAGE_ROOT` را تنظیم کنید یا همان
   `AllowUnsupportedToolVersion = true` کافی است.
3. HDL Workflow Advisor را فقط تا **مرحلهٔ 4.2** بروید:
   - 1.1: `IP Core Generation` + برد `Zynq UltraScale+ RFSoC ZCU111`؛
   - 1.2: رفرنسدیزاین `Deep Learning design with I/Q DAC/ADC and real-time interfaces`
     و پر کردن `DL Processor IP Name`، `DL Processor IP Location`،
     `DL Processor IP Vendor` **از روی `testbench_ip_core_report.html`**
     (اسم IP لزوماً `dlprocessor` نیست؛ چون در اسکریپت ما `ProcessorName = GenericProcessor` است)؛
   - 1.3 تا 4.2 مثل مستند MathWorks.
   - **مرحلهٔ 4.3 را اجرا نکنید**؛ همانجاست که ویوادو GUI کرش میکرد.
4. یکبار TCLهای تولیدشده را پچ کنید (بعد از 4.1، و دیگر 4.1 را تکرار نکنید).
   در MATLAB بزنید:

   ```matlab
   patch_vivado_tcl_2023_2('C:\work\...\hdl_prj\vivado_ip_prj')
   ```

   معادل خط فرمان، درصورتی که پایتون دارید:

   ```
   python tools/patch_vivado_tcl_for_2023_2.py --dir "C:\work\...\hdl_prj\vivado_ip_prj"
   ```

5. چهار خط بالای `vivado2023_2/run_vivado_2023_2.bat` را با مسیرهای واقعی
   (`VIVADO`، `HDL_PRJ`، `DLIP_NAME`، `DLIP_DIR`) پر کنید و اجرا کنید. خروجی
   `vivado_2023_2.log` و در صورت موفقیت `system_wrapper.bit` است.
6. فایل `.bit` را کنار اسکریپتهای MATLAB بگذارید و بقیهٔ مراحل مستند را ادامه
   دهید: `socUpdateBitstreamBuildInfo('system_wrapper.bit')`، `programFPGA`،
   `dlhdl.Workflow` / `compile` / `deploy`.

## اگر خطا داد

لاگ `vivado2023_2/vivado_2023_2.log` را باز کنید و اولین خطی که `ERROR` یا
`MW-2023.2: WARNING` دارد را بفرستید. پچر نام IPهای ناسازگار، CONFIGهای ردشده و
فایلهای کمشده را دقیقاً در لاگ مینویسد تا همان مورد را اصلاح کنیم.

## یک محدودیت صادقانه

MATLAB، ویوادو و برد ZCU111 در محیط من در دسترس نیست؛ بنابراین خود بیتستریم را
اینجا نساختم، ولی تمام تغییرات فایلها انجام شده و مسیر اجرا بهصورت batch و بدون
GUI بسته شده است. R2025b رسماً فقط با 2024.1 تست شده، پس اگر IP یا فرمان TCL
کاملاً وابسته به 2024.1 پیدا شد، لاگ نامش را میدهد و همان را هم پچ میکنیم.
