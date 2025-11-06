//+------------------------------------------------------------------+
//|                                       BBSqueezeScanner.mq5 |
//|        اکسپرت راه‌انداز پنل اسکنر BB Squeeze (نسخه ۱.۰)        |
//+------------------------------------------------------------------+
#property copyright "BBSqueeze Scanner EA"
#property version   "1.0"
#property description "Launches the BB Squeeze Scanner Panel"




// --- فایل کلاس پنل را ضمیمه می‌کنیم ---
#include "BBSqueezePanel.mqh"
#include <Controls\Defines.mqh> 

// --- ساخت یک نمونه سراسری از کلاس پنل ---
CBBSqueezeScannerPanel g_ScannerPanel;


input group "Panel Settings"

input int              InpPanelX      = 10;
input int              InpPanelY      = 30;
input string           InpPairList    = "EURUSD,GBPUSD,AUDUSD,USDJPY,USDCAD,USDCHF,NZDUSD";
input string           InpTimeframes  = "M30,H1,H4,D1";

input group "Bollinger & Keltner Settings"
input int              InpBBPeriod    = 20;
input double           InpBBDeviation = 2.0;
input int              InpKcPeriod    = 20;
input double           InpKcMultiplier= 1.5;
input int              InpShift       = 1; // 0 = کندل فعلی, 1 = کندل بسته شده قبلی

input group "MA Stack Settings"
input bool             InpCheckMAStack  = true;
input string           InpMAPeriods     = "8,21,34,55,89";
input string           InpMAMethod      = "Exponential"; // "Simple", "Exponential"
input string           InpMAPrice       = "Close";       // "Close", "Open", "High", ...
input int              InpMinTFAligned  = 3; // حداقل تعداد تایم‌فریم همسو برای رنگی شدن نام جفت ارز

//--- متغیر سراسری برای مدیریت آپدیت (جلوگیری از آپدیت در هر تیک) ---
datetime g_last_update_time = 0;
input int    InpUpdateIntervalSec = 10; // آپدیت هر ۱۰ ثانیه

//+------------------------------------------------------------------+
//| OnInit
//+------------------------------------------------------------------+
int OnInit()
  {

   g_ScannerPanel.Initialize(
    CORNER_LEFT_UPPER, InpPanelX, InpPanelY,
      InpPairList, InpTimeframes,
      InpBBPeriod, InpBBDeviation, InpKcPeriod, InpKcMultiplier,
      InpCheckMAStack, InpMAPeriods, InpMAMethod, InpMAPrice,
      InpMinTFAligned, InpShift
   );
   EventSetTimer(InpUpdateIntervalSec);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| OnDeinit
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer(); // کشتن تایمر
   g_ScannerPanel.Deinitialize(); // پاکسازی تمام آبجکت‌های پنل
  }

//+------------------------------------------------------------------+
//| OnTimer (به جای OnTick برای بهینه‌سازی)
//+------------------------------------------------------------------+
void OnTimer()
  {
   // --- صدا زدن تابع آپدیت پنل ---
   // (در حال حاضر این تابع از دیتای شبیه‌سازی شده استفاده می‌کند)
   g_ScannerPanel.UpdatePanel();
  }

//+------------------------------------------------------------------+
//| OnChartEvent (برای جابجایی پنل - فعلا خالی)
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   // (می‌توانیم بعداً منطق درگ کردن پنل را اضافه کنیم)
  }
//+------------------------------------------------------------------+