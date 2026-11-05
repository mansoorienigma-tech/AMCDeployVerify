@echo off
setlocal
REM ===========================================================================
REM  Build the RFSoC modulation-classification design with Vivado 2023.2
REM  in BATCH mode. No GUI is opened, so the "graphics" crash cannot occur.
REM  Edit only the 4 lines between the markers, then double-click this file.
REM ===========================================================================

REM --- EDIT START ------------------------------------------------------------
set "VIVADO=C:\Xilinx\Vivado\2023.2\bin\vivado.bat"
set "HDL_PRJ=C:\work\AMCDeployVerify\hdl_prj"
REM DLIP_NAME / DLIP_DIR come from testbench_ip_core_report.html (step 1.2)
set "DLIP_NAME=GenericProcessor"
set "DLIP_DIR=C:\work\AMCDeployVerify\genericipcore\dlhdl_prj\ipcore"
REM --- EDIT END --------------------------------------------------------------

set "KIT=%~dp0"
if not exist "%VIVADO%" (
  echo [ERROR] Vivado not found: %VIVADO%
  pause
  exit /b 1
)
if not exist "%HDL_PRJ%" (
  echo [ERROR] hdl_prj folder not found: %HDL_PRJ%
  echo Run HDL Workflow Advisor steps 1.1 - 4.2 in MATLAB first.
  pause
  exit /b 1
)

echo Running Vivado 2023.2 in batch mode...
call "%VIVADO%" -mode batch ^
  -log "%KIT%vivado_2023_2.log" -journal "%KIT%vivado_2023_2.jou" ^
  -source "%KIT%build_2023_2.tcl" ^
  -tclargs -hdl_prj "%HDL_PRJ%" ^
           -dlip_name "%DLIP_NAME%" ^
           -dlip_dir "%DLIP_DIR%" ^
           -jobs 4 -bitstream -clean

echo.
echo ===========================================================================
echo Log file: %KIT%vivado_2023_2.log
echo On success look for "MW-2023.2: BITSTREAM:" in the log.
echo On failure send me the first line containing ERROR or MW-2023.2 WARNING.
echo ===========================================================================
pause
