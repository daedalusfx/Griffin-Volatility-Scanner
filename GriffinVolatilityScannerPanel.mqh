//+------------------------------------------------------------------+
//|                           GriffinVolatilityScannerPanel.mqh |
//|                                                                  |
//+------------------------------------------------------------------+
#ifndef GRIFFINVOLATILITYSCANNERPANEL_MQH
#define GRIFFINVOLATILITYSCANNERPANEL_MQH

#include <Controls\Label.mqh> 

//+------------------------------------------------------------------+
//| Enumeration to represent the current state of the squeeze.       |
//+------------------------------------------------------------------+
enum ENUM_SQUEEZE_STATE
{
   STATE_LOADING,     // Indicator is still loading data
   STATE_SQUEEZE,     // Market is in squeeze (low volatility)
   STATE_EXPANSION,   // Market is expanding (high volatility)
   STATE_CONTRACTION  // Market is contracting (volatility decreasing)
};

//+------------------------------------------------------------------+
//| Structure to hold the result of squeeze analysis for a symbol    |
//| and timeframe. Contains state, signals, and UI display data.     |
//+------------------------------------------------------------------+
struct SqueezeResult
{
   // Raw signal flags
   bool              isAscending;      // MA stack is in ascending order (bullish alignment)
   bool              isDescending;     // MA stack is in descending order (bearish alignment)
   bool              upTrend;          // Price is above Keltner upper band (bullish)
   bool              downTrend;        // Price is below Keltner lower band (bearish)
   bool              upSlowing;        // Bullish momentum slowing (not used in this version)
   bool              downSlowing;      // Bearish momentum slowing (not used in this version)
   int               barsSinceSwitch;  // Number of bars since last squeeze state change

   ENUM_SQUEEZE_STATE state;           // Current squeeze state

   string            cellText;         // Text to display in the UI cell
   color             cellBgColor;      // Background color for the UI cell
   color             cellTextColor;    // Text color for the UI cell
   color             pairNameColor;    // Color for the pair name label (for alignment status)
};

//+------------------------------------------------------------------+
//| Class: Griffin Volatility Scanner Panel                          |
//| Purpose: A visual panel to scan multiple symbols/timeframes for  |
//|          Bollinger Bands and Keltner Channel squeeze states.     |
//+------------------------------------------------------------------+
class CGriffinVolatilityScannerPanel
{
private:
   // --- UI Settings ---
   string            m_prefix;             // Unique prefix for all object names
   ENUM_BASE_CORNER  m_panel_corner;       // Corner of the chart to anchor the panel
   int               m_x_offset, m_y_offset; // X and Y offset from the corner
   string            m_font_name;          // Font name for UI elements
   int               m_font_size;          // Font size for UI elements
   int               m_cell_width;         // Width of each data cell in pixels
   int               m_cell_height;        // Height of each cell in pixels
   int               m_header_width;       // Width of the left header (for pair names)

   // --- Symbol and Timeframe Lists ---
   string            m_pair_list_str;      // Comma-separated string: "EURUSD,GBPUSD,..."
   string            m_tf_list_str;        // Comma-separated string: "M30,H1,H4,..."
   string            m_pair_array[];       // Array of symbol names parsed from m_pair_list_str
   string            m_tf_array[];         // Array of timeframe strings parsed from m_tf_list_str
   ENUM_TIMEFRAMES   m_tf_enum_array[];    // Array of ENUM_TIMEFRAMES parsed from m_tf_array

   // --- Analysis Parameters ---
   int               m_bb_period;          // Bollinger Bands period (default 20)
   double            m_bb_deviation;       // Bollinger Bands deviation multiplier (default 2.0)
   int               m_kc_period;          // Keltner Channel MA period (default 20)
   double            m_kc_multiplier;      // Keltner Channel ATR multiplier (default 1.5)
   bool              m_check_ma_stack;     // Whether to check for MA stack alignment
   string            m_ma_periods_str;     // Comma-separated string for MA periods: "8,21,34,55,89"
   int               m_ma_periods_array[]; // Array of MA periods parsed from m_ma_periods_str
   string            m_ma_method_str;      // MA calculation method: "Exponential", "Simple", etc.
   string            m_ma_price_str;       // Price applied to MA: "Close", "HL2", etc.
   int               m_shift;              // Shift for calculations (default 1)
   int               m_min_tf_aligned;     // Minimum number of timeframes aligned for pair color

   // --- UI Colors ---
   color             m_color_low_vol;      // Color for low volatility (contraction) state
   color             m_color_high_vol;     // Color for high volatility (expansion/fire) state
   color             m_color_ma_up;        // Color for pair name when MAs are aligned up
   color             m_color_ma_down;      // Color for pair name when MAs are aligned down
   color             m_color_kc_up;        // Color for Keltner up trend (currently unused)
   color             m_color_kc_down;      // Color for Keltner down trend (currently unused)
   color             m_color_text;         // Default text color (white)
   color             m_color_bg;           // Default background color (dark grey)
   color             m_color_loading;      // Color for loading state (grey)
   color             m_color_squeeze;      // Color for squeeze state (yellow)

   //+------------------------------------------------------------------+
   //| Helper function to convert a price string to ENUM_APPLIED_PRICE |
   //+------------------------------------------------------------------+
   ENUM_APPLIED_PRICE GetPriceEnum(string price_str)
     {
      if(price_str == "Open") return PRICE_OPEN;
      if(price_str == "High") return PRICE_HIGH;
      if(price_str == "Low") return PRICE_LOW;
      if(price_str == "HL2") return PRICE_MEDIAN;    
      if(price_str == "HLC3") return PRICE_TYPICAL;  
      if(price_str == "OHLC4") return PRICE_WEIGHTED; 
      return PRICE_CLOSE; 
     }

   //+------------------------------------------------------------------+
   //| Helper function to convert a MA method string to ENUM_MA_METHOD |
   //+------------------------------------------------------------------+
   ENUM_MA_METHOD GetMaMethodEnum(string method_str)
     {
      if(method_str == "Simple") return MODE_SMA;
      if(method_str == "Smoothed") return MODE_SMMA;
      if(method_str == "Linear Weighted") return MODE_LWMA;
      return MODE_EMA; // Default to Exponential
     }

public:
   //+------------------------------------------------------------------+
   //| Constructor: Initializes default settings for the panel.         |
   //+------------------------------------------------------------------+
   CGriffinVolatilityScannerPanel(void)
     {
      m_prefix = "GriffinVolatility_" + (string)ChartID() + "_";
      m_font_name = "Tahoma";
      m_font_size = 8;
      m_cell_width = 100; 
      m_cell_height = 20;  
      m_header_width = 80; 

      // Default indicator parameters
      m_bb_period = 20;
      m_bb_deviation = 2.0;
      m_kc_period = 20;
      m_kc_multiplier = 1.5;
      m_shift = 1;
      m_check_ma_stack = true;
      m_ma_periods_str = "8,21,34,55,89";
      m_ma_method_str = "Exponential";
      m_ma_price_str = "Close";
      m_min_tf_aligned = 3;

      // Default UI colors
      m_color_low_vol = C'176, 30, 30';    // Dark Red (Contraction)
      m_color_high_vol = C'0, 100, 0';    // Dark Green (Expansion / Fire)
      m_color_squeeze = C'255, 200, 0';   // Yellow (Squeeze)

      m_color_ma_up = C'0, 255, 255';     // Aqua
      m_color_ma_down = C'255, 80, 80';   // Bright Red

      m_color_text = C'255, 255, 255';    // White
      m_color_bg = C'30, 30, 30';         // Dark Grey
      m_color_loading = C'50, 50, 50';    // Loading Grey
     }

   //+------------------------------------------------------------------+
   //| Initialize: Sets up the panel with user-provided settings.       |
   //| This includes symbol/timeframe lists, indicator parameters,      |
   //| and calls the initial UI layout drawing.                         |
   //+------------------------------------------------------------------+
   void Initialize(ENUM_BASE_CORNER corner, int x, int y,
                   string pair_list, string tf_list,
                   int bb_period, double bb_dev, int kc_period, double kc_mult,
                   bool check_ma, string ma_periods, string ma_method, string ma_price,
                   int min_tf_align, int shift
                  )
     {
      m_panel_corner = corner;
      m_x_offset = x;
      m_y_offset = y;
      m_pair_list_str = pair_list;
      m_tf_list_str = tf_list;
      m_bb_period = bb_period;
      m_bb_deviation = bb_dev;
      m_kc_period = kc_period;
      m_kc_multiplier = kc_mult;
      m_check_ma_stack = check_ma;
      m_ma_periods_str = ma_periods;
      m_ma_method_str = ma_method;
      m_ma_price_str = ma_price;
      m_min_tf_aligned = min_tf_align;
      m_shift = shift;

      StringSplit(m_pair_list_str, ',', m_pair_array);
      StringSplit(m_tf_list_str, ',', m_tf_array);
      ParseMaPeriods();
      ParseTimeframes();

      DrawPanelLayout();
     }

   //+------------------------------------------------------------------+
   //| Deinitialize: Cleans up all drawn objects from the chart.        |
   //+------------------------------------------------------------------+
   void Deinitialize()
     {
      ObjectsDeleteAll(0, m_prefix);
      ChartRedraw();
     }

   //+------------------------------------------------------------------+
   //| UpdatePanel: Main update function to recalculate and refresh the |
   //| displayed states for all symbol/timeframe combinations.          |
   //| Returns true if any symbol is still loading data.                |
   //+------------------------------------------------------------------+
   bool UpdatePanel()
   {
      int num_pairs = ArraySize(m_pair_array);
      int num_tfs   = ArraySize(m_tf_array);
      
      bool is_still_loading = false;
   
      for(int i = 0; i < num_pairs; i++) 
      {
         int aligned_up_count = 0;
         int aligned_down_count = 0;
   
         for(int j = 0; j < num_tfs; j++) 
         {
            SqueezeResult result = f_calculateAllSignals(m_pair_array[i], m_tf_enum_array[j]);
   
            if(m_check_ma_stack)
            {
               if(result.isAscending)  aligned_up_count++;
               if(result.isDescending) aligned_down_count++;
            }
   
            if(result.state == STATE_LOADING)
               is_still_loading = true;
   
            string bg_name  = m_prefix + "cell_bg_"  + (string)i + "_" + (string)j;
            string txt_name = m_prefix + "cell_txt_" + (string)i + "_" + (string)j;
   
            ObjectSetInteger(0, bg_name, OBJPROP_BGCOLOR, result.cellBgColor);
            ObjectSetString(0, txt_name, OBJPROP_TEXT, result.cellText);
            ObjectSetInteger(0, txt_name, OBJPROP_COLOR, result.cellTextColor);
         }
   
         string pair_label_name = m_prefix + "pair_" + (string)i;
         color pair_name_color = m_color_text; 
         if(m_check_ma_stack)
         {
            if(aligned_up_count >= m_min_tf_aligned)
               pair_name_color = m_color_ma_up;
            else if(aligned_down_count >= m_min_tf_aligned)
               pair_name_color = m_color_ma_down;
         }
         ObjectSetInteger(0, pair_label_name, OBJPROP_COLOR, pair_name_color);
      }
      
      ChartRedraw(0);
      return is_still_loading;
   }

private:
   //+------------------------------------------------------------------+
   //| f_calculateAllSignals: Core logic to calculate squeeze state,    |
   //| trend, and MA alignment for a given symbol and timeframe.        |
   //| Returns a SqueezeResult struct with all necessary data.          |
   //+------------------------------------------------------------------+
   SqueezeResult f_calculateAllSignals(string symbol, ENUM_TIMEFRAMES tf)
     {
      SqueezeResult res;
      res.state = STATE_LOADING; // Default state
      res.cellText = "...";
      res.cellBgColor = m_color_loading;
      res.cellTextColor = m_color_text;

      // 1. Prepare parameters
      ENUM_APPLIED_PRICE price_enum = GetPriceEnum(m_ma_price_str);
      ENUM_MA_METHOD ma_method_enum = GetMaMethodEnum(m_ma_method_str);

      int bars_to_copy = 100 + m_shift; 
      if(bars_to_copy < 100) bars_to_copy = 100; 

      // 2. Fetch price data non-blockingly
      double close_prices[];
      ArrayResize(close_prices, bars_to_copy + 2); 
      
      if(CopyClose(symbol, tf, 0, bars_to_copy + 2, close_prices) < bars_to_copy)
        {
         long error_code = GetLastError();
         if(error_code == ERR_HISTORY_NOT_FOUND || error_code == 5202)
           {
            return res; // Still loading, return loading state
           }
         else
           {
            res.cellText = "Err " + (string)error_code;
            return res;
           }
        }

      // 3. Create indicator handles
      int bb_handle = iBands(symbol, tf, m_bb_period, 0, m_bb_deviation, price_enum);
      int kc_ma_handle = iMA(symbol, tf, m_kc_period, 0, MODE_SMA, price_enum); 
      int kc_atr_handle = iATR(symbol, tf, m_kc_period); 

      int num_ma = ArraySize(m_ma_periods_array);
      int ma_handles[];
      ArrayResize(ma_handles, num_ma);
      for(int i = 0; i < num_ma; i++)
        {
         ma_handles[i] = iMA(symbol, tf, m_ma_periods_array[i], 0, ma_method_enum, price_enum);
         if(ma_handles[i] == INVALID_HANDLE)
           {
            for(int j = 0; j < i; j++) IndicatorRelease(ma_handles[j]);
            IndicatorRelease(bb_handle); IndicatorRelease(kc_ma_handle); IndicatorRelease(kc_atr_handle);
            res.cellText = "MA Err";
            return res;
           }
        }

      if(bb_handle == INVALID_HANDLE || kc_ma_handle == INVALID_HANDLE || kc_atr_handle == INVALID_HANDLE)
        {
         res.cellText = "Hndl Err";
         IndicatorRelease(bb_handle); IndicatorRelease(kc_ma_handle); IndicatorRelease(kc_atr_handle);
         for(int i = 0; i < num_ma; i++) IndicatorRelease(ma_handles[i]);
         return res;
        }

      // 4. Copy indicator buffer data
      double bb_upper[], bb_lower[], bb_basis[];
      double kc_basis[], kc_atr[];

      ArrayResize(bb_upper, bars_to_copy); ArrayResize(bb_lower, bars_to_copy); ArrayResize(bb_basis, bars_to_copy);
      ArrayResize(kc_basis, bars_to_copy); ArrayResize(kc_atr, bars_to_copy);

      if(CopyBuffer(bb_handle, 0, 0, bars_to_copy, bb_basis) < bars_to_copy ||
      CopyBuffer(bb_handle, 1, 0, bars_to_copy, bb_upper) < bars_to_copy ||
      CopyBuffer(bb_handle, 2, 0, bars_to_copy, bb_lower) < bars_to_copy ||
      CopyBuffer(kc_ma_handle, 0, 0, bars_to_copy, kc_basis) < bars_to_copy ||
      CopyBuffer(kc_atr_handle, 0, 0, bars_to_copy, kc_atr) < bars_to_copy)
     {
      res.cellText = "Copy Err";
      IndicatorRelease(bb_handle); IndicatorRelease(kc_ma_handle); IndicatorRelease(kc_atr_handle);
      for(int i = 0; i < num_ma; i++) IndicatorRelease(ma_handles[i]);
      return res;
     }

      double ma_values[];
      ArrayResize(ma_values, num_ma);
      double temp_buffer[1]; 

      if(m_check_ma_stack && num_ma > 1)
        {
         for(int i = 0; i < num_ma; i++)
           {
            if(CopyBuffer(ma_handles[i], 0, m_shift, 1, temp_buffer) < 1)
              {
               res.cellText = "MA Cpy Err";
               IndicatorRelease(bb_handle); IndicatorRelease(kc_ma_handle); IndicatorRelease(kc_atr_handle);
               for(int k = 0; k < num_ma; k++) IndicatorRelease(ma_handles[k]);
               return res;
              }
            ma_values[i] = temp_buffer[0];
           }
        }
      
      // 5. Perform calculations at shift index
      
      // a) Squeeze Logic
      double upperKC = kc_basis[m_shift] + (kc_atr[m_shift] * m_kc_multiplier);
      double lowerKC = kc_basis[m_shift] - (kc_atr[m_shift] * m_kc_multiplier);
      bool in_squeeze = (bb_lower[m_shift] > lowerKC) && (bb_upper[m_shift] < upperKC);

      // b) Keltner Trend Logic
      res.upTrend = (close_prices[m_shift] > upperKC);
      res.downTrend = (close_prices[m_shift] < lowerKC);
      
      // c) MA Stack Logic
      if(m_check_ma_stack && num_ma > 1)
        {
         res.isAscending = true;
         res.isDescending = true;
         for(int i = 0; i < num_ma - 1; i++)
           {
            if(ma_values[i] <= ma_values[i+1]) res.isAscending = false;
            if(ma_values[i] >= ma_values[i+1]) res.isDescending = false;
           }
         if(res.isAscending == res.isDescending)
           {
            res.isAscending = false;
            res.isDescending = false;
           }
        }

      // d) Bars Since Switch Logic
      res.barsSinceSwitch = 0;
      int max_scan = MathMin(bars_to_copy - 1, 50); 
      for(int i = m_shift + 1; i < m_shift + max_scan; i++)
        {
         if(i >= bars_to_copy) break;
         
         double upperKC_hist = kc_basis[i] + (kc_atr[i] * m_kc_multiplier);
         double lowerKC_hist = kc_basis[i] - (kc_atr[i] * m_kc_multiplier);
         bool inSqueeze_hist = (bb_lower[i] > lowerKC_hist) && (bb_upper[i] < upperKC_hist);

         if(inSqueeze_hist != in_squeeze)
           {
            res.barsSinceSwitch = (i - m_shift);
            break;
           }
         
          if(i == m_shift + max_scan - 1)
            {
             res.barsSinceSwitch = max_scan;
            }
        }
        
      // e) Determine Squeeze/Expansion/Contraction State
      double bbw_now = (bb_basis[m_shift] != 0) ? (bb_upper[m_shift] - bb_lower[m_shift]) / bb_basis[m_shift] : 0;
      double bbw_prev = (bb_basis[m_shift+1] != 0) ? (bb_upper[m_shift+1] - bb_lower[m_shift+1]) / bb_basis[m_shift+1] : 0;
      bool market_expansion = (bbw_now > bbw_prev);
      
      if(in_squeeze)
         res.state = STATE_SQUEEZE;
      else if(market_expansion)
         res.state = STATE_EXPANSION;
      else
         res.state = STATE_CONTRACTION;

      // 7. Clean up all handles
      IndicatorRelease(bb_handle);
      IndicatorRelease(kc_ma_handle);
      IndicatorRelease(kc_atr_handle);
      for(int i = 0; i < num_ma; i++)
        {
         IndicatorRelease(ma_handles[i]);
        }

      // 8. Format final display output
      string state_text = "";
      
      switch(res.state)
      {
         case STATE_SQUEEZE:
            state_text = "SQUEEZE";
            res.cellBgColor = m_color_squeeze; // Yellow
            res.cellTextColor = C'0,0,0';      // Black text for contrast
            break;
         case STATE_EXPANSION:
            state_text = "FIRE"; // Expansion
            res.cellBgColor = m_color_high_vol; // Green
            res.cellTextColor = m_color_text;     // White text
            break;
         case STATE_CONTRACTION:
            state_text = "CONTRACT"; // Decreasing volatility
            res.cellBgColor = m_color_low_vol;  // Red
            res.cellTextColor = m_color_text;     // White text
            break;
         default:
            break; 
      }
      
      if(res.state != STATE_LOADING)
      {
         string bars_str = "(" + (res.barsSinceSwitch >= 50 ? "+" : (string)res.barsSinceSwitch) + ")";
         res.cellText = state_text + " " + bars_str;
      }

      return res;
     }

   //+------------------------------------------------------------------+
   //| DrawPanelLayout: Draws the initial grid layout for the panel.    |
   //| Creates labels for symbols/timeframes and placeholder cells.     |
   //+------------------------------------------------------------------+
   void DrawPanelLayout()
   {
      int num_pairs = ArraySize(m_pair_array);
      int num_tfs = ArraySize(m_tf_array);
      if(num_pairs == 0 || num_tfs == 0) return; 
   
      int total_width = m_header_width + (num_tfs * m_cell_width);
      int total_height = m_cell_height + (num_pairs * m_cell_height);
   
      // Background of the entire panel
      CreateRect("Panel_BG", 0, 0, total_width, total_height, m_color_bg); 
   
      int current_y = 0;
   
      // --- Header Row (Timeframes) ---
      CreateLabel("header_corner", "PAIRS", 0, current_y, m_header_width, m_cell_height, m_color_text, ALIGN_CENTER);
      for(int j = 0; j < num_tfs; j++)
      {
         int x_pos = m_header_width + (j * m_cell_width);
         CreateLabel("tf_" + (string)j, m_tf_array[j], x_pos, current_y, m_cell_width, m_cell_height, m_color_text, ALIGN_CENTER);
      }
   
      current_y += m_cell_height;
   
      // --- Data Rows ---
      for(int i = 0; i < num_pairs; i++)
      {
         // Pair name
         CreateLabel("pair_" + (string)i, m_pair_array[i], 
                     0, current_y, m_header_width, m_cell_height, m_color_text, ALIGN_CENTER);
   
         // Cells
         for(int j = 0; j < num_tfs; j++)
         {
            int x_pos = m_header_width + (j * m_cell_width);
            
            // Cell background
            CreateRect("cell_bg_" + (string)i + "_" + (string)j,
                       x_pos, current_y, m_cell_width, m_cell_height, m_color_loading);
            
            // Cell text
            CreateLabel("cell_txt_" + (string)i + "_" + (string)j, "...",
                        x_pos, current_y, m_cell_width, m_cell_height, m_color_text, ALIGN_CENTER);
         }
         current_y += m_cell_height;
      }
   }

   //+------------------------------------------------------------------+
   //| ParseMaPeriods: Parses the MA periods string into an integer array. |
   //+------------------------------------------------------------------+
   void ParseMaPeriods()
     {
      string ma_array_str[];
      int count = StringSplit(m_ma_periods_str, ',', ma_array_str);
      ArrayResize(m_ma_periods_array, count);
      for(int i = 0; i < count; i++)
        {
         m_ma_periods_array[i] = (int)StringToInteger(ma_array_str[i]);
        }
     }

   //+------------------------------------------------------------------+
   //| ParseTimeframes: Parses the timeframe strings into ENUM values.  |
   //+------------------------------------------------------------------+
   void ParseTimeframes()
     {
      int count = ArraySize(m_tf_array);
      ArrayResize(m_tf_enum_array, count);
      for(int i = 0; i < count; i++)
        {
         m_tf_enum_array[i] = StringToTimeframe(m_tf_array[i]);
        }
     }

   //+------------------------------------------------------------------+
   //| StringToTimeframe: Converts a string like "H1" to PERIOD_H1.     |
   //+------------------------------------------------------------------+
   ENUM_TIMEFRAMES StringToTimeframe(string tf_str)
     {
      if(tf_str == "M1") return PERIOD_M1;
      if(tf_str == "M5") return PERIOD_M5;
      if(tf_str == "M15") return PERIOD_M15;
      if(tf_str == "M30") return PERIOD_M30;
      if(tf_str == "H1") return PERIOD_H1;
      if(tf_str == "H4") return PERIOD_H4;
      if(tf_str == "D1") return PERIOD_D1;
      if(tf_str == "W1") return PERIOD_W1;
      if(tf_str == "MN1") return PERIOD_MN1;
      return _Period; // Default to current chart timeframe
     }

   //+------------------------------------------------------------------+
   //| CreateRect: Helper to create a rectangle label object.           |
   //+------------------------------------------------------------------+
   void CreateRect(string name, int x, int y, int w, int h, color bg_color)
{
   string obj_name = m_prefix + name;
   if(ObjectFind(0, obj_name) < 0)
   {
      ObjectCreate(0, obj_name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, obj_name, OBJPROP_CORNER, m_panel_corner);
      ObjectSetInteger(0, obj_name, OBJPROP_XDISTANCE, m_x_offset + x);
      ObjectSetInteger(0, obj_name, OBJPROP_YDISTANCE, m_y_offset + y);
      ObjectSetInteger(0, obj_name, OBJPROP_XSIZE, w);
      ObjectSetInteger(0, obj_name, OBJPROP_YSIZE, h);
      ObjectSetInteger(0, obj_name, OBJPROP_BGCOLOR, bg_color);
      ObjectSetInteger(0, obj_name, OBJPROP_FILL, true);
      ObjectSetInteger(0, obj_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, obj_name, OBJPROP_BACK, true);
      ObjectSetInteger(0, obj_name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, obj_name, OBJPROP_HIDDEN, true);
   }
}

   //+------------------------------------------------------------------+
   //| CreateLabel: Helper to create a label object.                    |
   //+------------------------------------------------------------------+
   void CreateLabel(string name, string text, int x, int y, int w, int h, color text_color, ENUM_ALIGN_MODE align = ALIGN_LEFT)
{
   string obj_name = m_prefix + name;
   if(ObjectFind(0, obj_name) < 0)
   {
      ObjectCreate(0, obj_name, OBJ_LABEL, 0, 0, 0);
      ObjectSetString(0, obj_name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, obj_name, OBJPROP_CORNER, m_panel_corner);
      
      int x_pos = x;
      ENUM_ANCHOR_POINT anchor = ANCHOR_LEFT;
      
      if(align == ALIGN_CENTER)
      {
         x_pos = x + w / 2;
         anchor = ANCHOR_CENTER;
      }
      else if(align == ALIGN_RIGHT)
      {
         x_pos = x + w;
         anchor = ANCHOR_RIGHT;
      }

      ObjectSetInteger(0, obj_name, OBJPROP_XDISTANCE, m_x_offset + x_pos);
      ObjectSetInteger(0, obj_name, OBJPROP_YDISTANCE, m_y_offset + y + h / 2);
      ObjectSetInteger(0, obj_name, OBJPROP_COLOR, text_color);
      ObjectSetInteger(0, obj_name, OBJPROP_FONTSIZE, m_font_size);
      ObjectSetString(0, obj_name, OBJPROP_FONT, m_font_name);
      ObjectSetInteger(0, obj_name, OBJPROP_ANCHOR, anchor);
      ObjectSetInteger(0, obj_name, OBJPROP_BACK, false);
      ObjectSetInteger(0, obj_name, OBJPROP_SELECTABLE, false);
   }
}

   //+------------------------------------------------------------------+
   //| UpdateLabelText: Updates the text of an existing label.          |
   //| Note: This function expects the full object name (with prefix).  |
   //+------------------------------------------------------------------+
   void UpdateLabelText(string name, string text)
     {
      ObjectSetString(0, name, OBJPROP_TEXT, text);
     }
};
//+------------------------------------------------------------------+
#endif // GRIFFINVOLATILITYSCANNERPANEL_MQH