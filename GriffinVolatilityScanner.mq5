//+------------------------------------------------------------------+
//|                                   GriffinVolatilityScanner.mq5   |
//+------------------------------------------------------------------+
#property copyright "Griffin Volatility Scanner EA"
#property version   "1.0"
#property description "Launches the Griffin Volatility Scanner Panel"

#include "GriffinVolatilityScannerPanel.mqh"
#include <Controls\Defines.mqh> 

//+------------------------------------------------------------------+
//| Global instance of the scanner panel class.                      |
//+------------------------------------------------------------------+
CGriffinVolatilityScannerPanel g_ScannerPanel;

//+------------------------------------------------------------------+
//| Input Parameters Group: Panel Settings                           |
//+------------------------------------------------------------------+
input group "Panel Settings"

input int              InpPanelX      = 10;        // X offset for the panel
input int              InpPanelY      = 30;        // Y offset for the panel
input string           InpPairList    = "EURUSD,GBPUSD,AUDUSD,USDJPY,USDCAD,USDCHF,NZDUSD"; // Comma-separated list of symbols to scan
input string           InpTimeframes  = "M30,H1,H4,D1"; // Comma-separated list of timeframes to scan

//+------------------------------------------------------------------+
//| Input Parameters Group: Bollinger & Keltner Settings             |
//+------------------------------------------------------------------+
input group "Bollinger & Keltner Settings"
input int              InpBBPeriod    = 20;        // Bollinger Bands period
input double           InpBBDeviation = 2.0;       // Bollinger Bands deviation multiplier
input int              InpKcPeriod    = 20;        // Keltner Channel MA period
input double           InpKcMultiplier= 1.5;       // Keltner Channel ATR multiplier
input int              InpShift       = 1;         // Shift for calculations

//+------------------------------------------------------------------+
//| Input Parameters Group: MA Stack Settings                        |
//+------------------------------------------------------------------+
input group "MA Stack Settings"
input bool             InpCheckMAStack  = true;    // Whether to check for Moving Average stack alignment
input string           InpMAPeriods     = "8,21,34,55,89"; // Comma-separated list of MA periods
input string           InpMAMethod      = "Exponential"; // MA calculation method
input string           InpMAPrice       = "Close";       // Price applied to MA calculation
input int              InpMinTFAligned  = 3;            // Minimum number of aligned timeframes to color the pair name

//+------------------------------------------------------------------+
//| Global variables for update timing and loading status.           |
//+------------------------------------------------------------------+
datetime g_last_update_time = 0;
input int    InpUpdateIntervalSec = 10; // Update interval in seconds after initial load
bool g_is_loading = true; 

//+------------------------------------------------------------------+
//| OnInit: Called when the Expert Advisor is initialized.           |
//| Initializes the scanner panel and sets the initial timer.        |
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

   EventSetTimer(1); // Start with a 1-second timer for initial loading
   g_is_loading = true; 
   
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| OnDeinit: Called when the Expert Advisor is deinitialized.       |
//| Cleans up the panel and kills the timer.                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer(); 
   g_ScannerPanel.Deinitialize(); 
  }

//+------------------------------------------------------------------+
//| OnTimer: Called every time the timer ticks.                      |
//| Updates the panel and manages the timer interval based on        |
//| whether data is still loading or not.                            |
//+------------------------------------------------------------------+
void OnTimer()
  {
     
   bool still_loading = g_ScannerPanel.UpdatePanel();
   
   if(still_loading && g_is_loading)
     {
      // Still loading, keep the 1s timer
     }
   else if(!still_loading && g_is_loading)
     {
      Print("GriffinVolatilityScanner: All data loaded. Switching to " + (string)InpUpdateIntervalSec + "s interval.");
      g_is_loading = false;
      EventSetTimer(InpUpdateIntervalSec); // Switch to user-defined interval
     }
   else if(!g_is_loading)
     {
      // Panel is updated on the new interval
     }
  }

//+------------------------------------------------------------------+
//| OnChartEvent: Handles chart events (currently unused).           |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   // Not implemented
  }
//+------------------------------------------------------------------+