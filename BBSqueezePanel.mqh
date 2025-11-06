//+------------------------------------------------------------------+
//|                                           BBSqueezePanel.mqh |
//|        کلاس پنل اسکنر BB Squeeze (بر اساس VdsPanel)           |
//|                        (نسخه ۱.۲ - ریفکتور شده)                |
//+------------------------------------------------------------------+
#ifndef BBSQUEZEPANEL_MQH
#define BBSQUEZEPANEL_MQH

#include <Controls\Label.mqh> 

//+------------------------------------------------------------------+
//| ساختار برای نگهداری نتایج اسکن (برای هر سلول)
//+------------------------------------------------------------------+
struct SqueezeResult
{
   // --- سیگنال‌های خام ---
   bool              inSqueeze;
   bool              isAscending;     // MA Stack صعودی
   bool              isDescending;    // MA Stack نزولی
   bool              upTrend;           // Keltner Channel
   bool              downTrend;         // Keltner Channel
   bool              upSlowing;
   bool              downSlowing;
   int               barsSinceSwitch;

   // --- مقادیر نهایی ---
   string            cellText;
   color             cellBgColor;     // رنگ پس‌زمینه سلول
   color             pairNameColor;     // رنگ جفت ارز (برای همسویی)

   // ===> FIX: متغیرهای تکراری حذف شدند
};
//+------------------------------------------------------------------+
//| کلاس پنل اسکنر BB Squeeze
//+------------------------------------------------------------------+
class CBBSqueezeScannerPanel
{
private:
   // --- تنظیمات پنل ---
   string            m_prefix;
   ENUM_BASE_CORNER  m_panel_corner;
   int               m_x_offset, m_y_offset;
   string            m_font_name;
   int               m_font_size;
   int               m_cell_width;      // عرض هر سلول
   int               m_cell_height;     // ارتفاع هر سلول
   int               m_header_width;    // عرض ستون نام جفت ارزها

   // --- لیست‌های اسکن ---
   string            m_pair_list_str;   // "EURUSD,GBPUSD,..."
   string            m_tf_list_str;     // "M30,H1,H4,..."
   string            m_pair_array[];    // آرایه جفت ارزها
   string            m_tf_array[];      // آرایه تایم‌فریم‌ها (متنی)
   ENUM_TIMEFRAMES   m_tf_enum_array[]; // آرایه تایم‌فریم‌ها (MQL5 Enum)

   // --- پارامترهای اندیکاتور (از پاین اسکریپت) ---
   int               m_bb_period;
   double            m_bb_deviation;
   int               m_kc_period;
   double            m_kc_multiplier;
   bool              m_check_ma_stack;
   string            m_ma_periods_str;  // "8,21,34,..."
   int               m_ma_periods_array[];// آرایه عددی پریودهای MA
   string            m_ma_method_str;
   string            m_ma_price_str;
   int               m_shift;
   int               m_min_tf_aligned;

   // --- رنگ‌ها (از پاین اسکریپت) ---
   color             m_color_low_vol;
   color             m_color_high_vol;
   color             m_color_ma_up;
   color             m_color_ma_down;
   color             m_color_kc_up;
   color             m_color_kc_down;
   color             m_color_text;
   color             m_color_bg;


   //------------------------------------------------------------------
   // تابع کمکی: تبدیل رشته قیمت به ENUM_APPLIED_PRICE (اصلاح شده)
   //------------------------------------------------------------------
   ENUM_APPLIED_PRICE GetPriceEnum(string price_str)
     {
      if(price_str == "Open") return PRICE_OPEN;
      if(price_str == "High") return PRICE_HIGH;
      if(price_str == "Low") return PRICE_LOW;
      
      // ===> FIX: استفاده از Enum های صحیح MQL5
      if(price_str == "HL2") return PRICE_MEDIAN;     // (Pine Script: hl2)
      if(price_str == "HLC3") return PRICE_TYPICAL;    // (Pine Script: hlc3)
      if(price_str == "OHLC4") return PRICE_WEIGHTED;   // (Pine Script: ohlc4)

      return PRICE_CLOSE; // پیش‌فرض
     }

   //------------------------------------------------------------------
   // تابع کمکی: تبدیل رشته متد MA به ENUM_MA_METHOD
   //------------------------------------------------------------------
   ENUM_MA_METHOD GetMaMethodEnum(string method_str)
     {
      if(method_str == "Simple") return MODE_SMA;
      if(method_str == "Smoothed") return MODE_SMMA;
      if(method_str == "Linear Weighted") return MODE_LWMA;
      return MODE_EMA; // پیش‌فرض Exponential
     }


public:
   //------------------------------------------------------------------
   // سازنده (Constructor) - تنظیمات پیش‌فرض
   //------------------------------------------------------------------
   CBBSqueezeScannerPanel(void)
     {
      // مقداردهی اولیه متغیرها
      m_prefix = "BBSqueeze_" + (string)ChartID() + "_";
      m_font_name = "Tahoma";
      m_font_size = 8;
      m_cell_width = 100; // 100 پیکسل عرض برای هر سلول
      m_cell_height = 20;  // 20 پیکسل ارتفاع
      m_header_width = 80; // 80 پیکسل برای نام جفت ارز

      // تنظیمات پیش‌فرض منطق (مثل پاین اسکریپت)
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

      // تنظیمات پیش‌فرض رنگ‌ها (مثل پاین اسکریپت)
      m_color_low_vol = C'255,0,0';     // Red
      m_color_high_vol = C'0,128,0';    // Green
      m_color_ma_up = C'0,255,255';     // Aqua
      m_color_ma_down = C'255,0,0';     // Red
      m_color_kc_up = C'0,255,255';     // Aqua
      m_color_kc_down = C'255,0,0';     // Red
      m_color_text = C'255,255,255';   // White
      m_color_bg = C'30,30,30';         // Dark Grey
     }

   //------------------------------------------------------------------
   // ۱. راه‌اندازی (Initialize) - گرفتن ورودی‌ها از EA
   //------------------------------------------------------------------
   void Initialize(ENUM_BASE_CORNER corner, int x, int y,
                   string pair_list, string tf_list,
                   int bb_period, double bb_dev, int kc_period, double kc_mult,
                   bool check_ma, string ma_periods, string ma_method, string ma_price,
                   int min_tf_align, int shift
                  )
     {
      // --- ذخیره موقعیت پنل ---
      m_panel_corner = corner;
      m_x_offset = x;
      m_y_offset = y;

      // --- ذخیره لیست‌های اسکن ---
      m_pair_list_str = pair_list;
      m_tf_list_str = tf_list;

      // --- ذخیره تنظیمات اندیکاتور ---
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

      // --- پردازش رشته‌ها و تبدیل به آرایه ---
      StringSplit(m_pair_list_str, ',', m_pair_array);
      StringSplit(m_tf_list_str, ',', m_tf_array);
      ParseMaPeriods();
      ParseTimeframes();

      // --- رسم ساختار اولیه پنل ---
      DrawPanelLayout();
     }

   //------------------------------------------------------------------
   // ۲. پاکسازی (Deinitialize)
   //------------------------------------------------------------------
   void Deinitialize()
     {
      ObjectsDeleteAll(0, m_prefix);
      ChartRedraw();
     }

   //------------------------------------------------------------------
   // ۳. آپدیت پنل (تابع اصلی که توسط EA صدا زده می‌شود)
   //------------------------------------------------------------------
   void UpdatePanel()
     {
      int num_pairs = ArraySize(m_pair_array);
      int num_tfs = ArraySize(m_tf_array);

      for(int i = 0; i < num_pairs; i++) // حلقه روی جفت ارزها (ردیف‌ها)
        {
         int aligned_up_count = 0;
         int aligned_down_count = 0;

         for(int j = 0; j < num_tfs; j++) // حلقه روی تایم‌فریم‌ها (ستون‌ها)
           {
            // ۱. دریافت داده‌ها
            SqueezeResult result;
            result = f_calculateAllSignals(m_pair_array[i], m_tf_enum_array[j]);

            // ۲. شمارش همسویی MA
            if(m_check_ma_stack)
              {
               if(result.isAscending) aligned_up_count++;
               if(result.isDescending) aligned_down_count++;
              }

            // ۳. آپدیت لیبل سلول
            string cell_name = m_prefix + "cell_" + (string)i + "_" + (string)j;
            UpdateLabelText(cell_name, result.cellText);
            ObjectSetInteger(0, cell_name, OBJPROP_BGCOLOR, result.cellBgColor);
            
            color text_color = m_color_text;
            if(result.inSqueeze) text_color = m_color_text;
            else text_color = m_color_text;
            ObjectSetInteger(0, cell_name, OBJPROP_COLOR, text_color);
           }

         // ۴. آپدیت رنگ نام جفت ارز بر اساس همسویی
         string pair_label_name = m_prefix + "pair_" + (string)i;
         color pair_name_color = m_color_text; // رنگ پیش‌فرض
         if(m_check_ma_stack)
           {
            if(aligned_up_count >= m_min_tf_aligned)
              {
               pair_name_color = m_color_ma_up;
              }
            else if(aligned_down_count >= m_min_tf_aligned)
              {
               pair_name_color = m_color_ma_down;
              }
           }
         ObjectSetInteger(0, pair_label_name, OBJPROP_COLOR, pair_name_color);
        }

      ChartRedraw(0);
     }


//+------------------------------------------------------------------+
//| بخش خصوصی (توابع کمکی)
//+------------------------------------------------------------------+
private:

   //------------------------------------------------------------------
   // (منطق اصلی) محاسبه سیگنال‌ها برای یک سلول (نسخه ریفکتور شده)
   //------------------------------------------------------------------
   SqueezeResult f_calculateAllSignals(string symbol, ENUM_TIMEFRAMES tf)
     {
      SqueezeResult res;
      ZeroMemory(res);
      res.cellText = "...";
      res.cellBgColor = C'50,50,50';

      // --- ۱. آماده‌سازی پارامترها ---
      ENUM_APPLIED_PRICE price_enum = GetPriceEnum(m_ma_price_str);
      ENUM_MA_METHOD ma_method_enum = GetMaMethodEnum(m_ma_method_str);

      int bars_to_copy = 100 + m_shift; 
      if(bars_to_copy < 100) bars_to_copy = 100; 

      // --- ۲. ساخت هندل‌های اندیکاتور ---
      int bb_handle = iBands(symbol, tf, m_bb_period, 0, m_bb_deviation, price_enum);
      int kc_ma_handle = iMA(symbol, tf, m_kc_period, 0, MODE_SMA, price_enum); 
      int kc_atr_handle = iATR(symbol, tf, m_kc_period); 

      // ساخت هندل برای MA Stack
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

      // --- ۳. کپی کردن دیتا در بافرها ---
      double bb_upper[], bb_lower[];
      double kc_basis[], kc_atr[];

      ArrayResize(bb_upper, bars_to_copy); ArrayResize(bb_lower, bars_to_copy);
      ArrayResize(kc_basis, bars_to_copy); ArrayResize(kc_atr, bars_to_copy);

      // (فقط قیمت Close را برای Keltner Trend کپی می‌کنیم)
      double close_prices[];
      ArrayResize(close_prices, bars_to_copy + 2); // +2 برای [shift+1]
      if(CopyClose(symbol, tf, 0, bars_to_copy + 2, close_prices) < bars_to_copy + 2)
        {
         res.cellText = "Price Err";
         // ===> FIX: پاکسازی کامل هندل‌ها
         IndicatorRelease(bb_handle); IndicatorRelease(kc_ma_handle); IndicatorRelease(kc_atr_handle);
         for(int k = 0; k < num_ma; k++) IndicatorRelease(ma_handles[k]);
         return res;
        }

      // کپی دیتای اندیکاتورها
      if(CopyBuffer(bb_handle, 1, 0, bars_to_copy, bb_upper) < bars_to_copy ||
         CopyBuffer(bb_handle, 2, 0, bars_to_copy, bb_lower) < bars_to_copy ||
         CopyBuffer(kc_ma_handle, 0, 0, bars_to_copy, kc_basis) < bars_to_copy ||
         CopyBuffer(kc_atr_handle, 0, 0, bars_to_copy, kc_atr) < bars_to_copy)
        {
         res.cellText = "Copy Err";
         IndicatorRelease(bb_handle); IndicatorRelease(kc_ma_handle); IndicatorRelease(kc_atr_handle);
         for(int i = 0; i < num_ma; i++) IndicatorRelease(ma_handles[i]);
         return res;
        }

      // ===> REFACTOR START: کپی دیتای MA Stack (بخش اصلاح شده) <===
      double ma_values[]; // آرایه 1 بعدی برای نگهداری مقادیر MA در نقطه m_shift
      ArrayResize(ma_values, num_ma);
      double temp_buffer[1]; // بافر موقت برای کپی 1 مقدار

      if(m_check_ma_stack && num_ma > 1) // (فقط اگر به MA Stack نیاز داریم، کپی کن)
        {
         for(int i = 0; i < num_ma; i++)
           {
            // فقط 1 مقدار از کندل m_shift را کپی می‌کنیم
            if(CopyBuffer(ma_handles[i], 0, m_shift, 1, temp_buffer) < 1)
              {
               res.cellText = "MA Cpy Err";
               // پاکسازی کامل هندل‌ها
               IndicatorRelease(bb_handle); IndicatorRelease(kc_ma_handle); IndicatorRelease(kc_atr_handle);
               for(int k = 0; k < num_ma; k++) IndicatorRelease(ma_handles[k]);
               return res;
              }
            ma_values[i] = temp_buffer[0];
           }
        }
      // ===> REFACTOR END <===
      
      // --- ۴. انجام محاسبات (در اندیس shift) ---
      
      // (الف) منطق Squeeze
      double upperKC = kc_basis[m_shift] + (kc_atr[m_shift] * m_kc_multiplier);
      double lowerKC = kc_basis[m_shift] - (kc_atr[m_shift] * m_kc_multiplier);
      res.inSqueeze = (bb_lower[m_shift] > lowerKC) && (bb_upper[m_shift] < upperKC);

      // (ب) منطق Keltner Trend
      res.upTrend = (close_prices[m_shift] > upperKC);
      res.downTrend = (close_prices[m_shift] < lowerKC);
      
      // (ج) منطق MA Stack
      if(m_check_ma_stack && num_ma > 1)
        {
         res.isAscending = true;
         res.isDescending = true;
         for(int i = 0; i < num_ma - 1; i++)
           {
            // ===> FIX: استفاده از آرایه 1 بعدی جدید
            if(ma_values[i] <= ma_values[i+1])
               res.isAscending = false;
            if(ma_values[i] >= ma_values[i+1])
               res.isDescending = false;
           }
         if(res.isAscending == res.isDescending)
           {
            res.isAscending = false;
            res.isDescending = false;
           }
        }

      // (د) منطق "Bars Since Switch"
      res.barsSinceSwitch = 0;
      int max_scan = MathMin(bars_to_copy - 1, 50); // 50 = m_maxPastBars
      for(int i = m_shift + 1; i < m_shift + max_scan; i++)
        {
         double upperKC_hist = kc_basis[i] + (kc_atr[i] * m_kc_multiplier);
         double lowerKC_hist = kc_basis[i] - (kc_atr[i] * m_kc_multiplier);
         bool inSqueeze_hist = (bb_lower[i] > lowerKC_hist) && (bb_upper[i] < upperKC_hist);

         if(inSqueeze_hist != res.inSqueeze) // اگر سوییچ پیدا شد
           {
            res.barsSinceSwitch = (i - m_shift);
            break;
           }
         
         if(i == m_shift + max_scan - 1) // اگر به انتهای اسکن رسیدیم
           {
            res.barsSinceSwitch = max_scan; // نشانه‌ی (+)
           }
        }

      // --- ۵. پاکسازی تمام هندل‌ها ---
      IndicatorRelease(bb_handle);
      IndicatorRelease(kc_ma_handle);
      IndicatorRelease(kc_atr_handle);
      for(int i = 0; i < num_ma; i++)
        {
         IndicatorRelease(ma_handles[i]);
        }

      // --- ۶. فرمت کردن خروجی نهایی ---
      string squeeze_char = res.inSqueeze ? "●" : "●";
      string bars_str = "(" + (res.barsSinceSwitch >= 50 ? "+" : (string)res.barsSinceSwitch) + ")";
      string ma_arrow = res.isAscending ? " ↗" : (res.isDescending ? " ↘" : "");
      string kc_arrow = res.upTrend ? " ↑" : (res.downTrend ? " ↓" : "");
      
      res.cellText = squeeze_char + bars_str + ma_arrow + kc_arrow;
      res.cellBgColor = res.inSqueeze ? m_color_low_vol : m_color_high_vol;

      return res;
     }

   //------------------------------------------------------------------
   // رسم ساختار اولیه پنل (فقط یکبار در Initialize)
   //------------------------------------------------------------------
   void DrawPanelLayout()
     {
      int num_pairs = ArraySize(m_pair_array);
      int num_tfs = ArraySize(m_tf_array);
      if(num_pairs == 0 || num_tfs == 0) return; // اگر ورودی خالی بود، رسم نکن

      int total_width = m_header_width + (num_tfs * m_cell_width);
      int total_height = m_cell_height + (num_pairs * m_cell_height);

      CreateRect("Panel_BG", 0, 0, total_width, total_height, m_color_bg, 200); // 200 = alpha

      int current_y = 0;

      // --- ۱. رسم هدر (تایم‌فریم‌ها) ---
      CreateLabel("header_corner", "PAIRS", 0, current_y, m_header_width, m_cell_height, m_color_bg, m_color_text, ALIGN_CENTER);
      for(int j = 0; j < num_tfs; j++)
        {
         int x_pos = m_header_width + (j * m_cell_width);
         CreateLabel("tf_" + (string)j, m_tf_array[j], x_pos, current_y, m_cell_width, m_cell_height, m_color_bg, m_color_text, ALIGN_CENTER);
        }

      current_y += m_cell_height;

      // --- ۲. رسم ردیف‌ها (جفت ارزها و سلول‌های داده) ---
      for(int i = 0; i < num_pairs; i++)
        {
         CreateLabel("pair_" + (string)i, m_pair_array[i], 0, current_y, m_header_width, m_cell_height, m_color_bg, m_color_text, ALIGN_CENTER);

         for(int j = 0; j < num_tfs; j++)
           {
            int x_pos = m_header_width + (j * m_cell_width);
            string cell_name = "cell_" + (string)i + "_" + (string)j;
            CreateLabel(cell_name, "...", x_pos, current_y, m_cell_width, m_cell_height, C'50,50,50', m_color_text, ALIGN_CENTER);
           }
         current_y += m_cell_height;
        }
     }

   //------------------------------------------------------------------
   // توابع کمکی پردازش ورودی
   //------------------------------------------------------------------
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

   void ParseTimeframes()
     {
      int count = ArraySize(m_tf_array);
      ArrayResize(m_tf_enum_array, count);
      for(int i = 0; i < count; i++)
        {
         m_tf_enum_array[i] = StringToTimeframe(m_tf_array[i]);
        }
     }

   // تابع کمکی برای تبدیل رشته تایم‌فریم به Enum
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
      return _Period; // پیش‌فرض
     }

   //------------------------------------------------------------------
   // توابع کمکی رسم (کپی شده از VdsPanel با کمی تغییر)
   //------------------------------------------------------------------
   void CreateRect(string name, int x, int y, int w, int h, color c, uchar alpha = 255)
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
         ObjectSetInteger(0, obj_name, OBJPROP_BGCOLOR, c);
         ObjectSetInteger(0, obj_name, OBJPROP_COLOR, c); // برای بوردر
         ObjectSetInteger(0, obj_name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
         ObjectSetInteger(0, obj_name, OBJPROP_BACK, true);
         ObjectSetInteger(0, obj_name, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, obj_name, OBJPROP_HIDDEN, true);
        }
     }

   void CreateLabel(string name, string text, int x, int y, int w, int h, color bg_color, color text_color, ENUM_ALIGN_MODE align = ALIGN_LEFT)
     {
      string obj_name = m_prefix + name;
      if(ObjectFind(0, obj_name) < 0)
        {
         ObjectCreate(0, obj_name, OBJ_LABEL, 0, 0, 0);
         ObjectSetString(0, obj_name, OBJPROP_TEXT, text);
         ObjectSetInteger(0, obj_name, OBJPROP_CORNER, m_panel_corner);

         int x_pos = m_x_offset + x;
         ENUM_ANCHOR_POINT anchor = ANCHOR_LEFT;
         if(align == ALIGN_CENTER)
           {
            x_pos = m_x_offset + x + (w / 2);
            anchor = ANCHOR_CENTER;
           }
         else if(align == ALIGN_RIGHT)
           {
            x_pos = m_x_offset + x + w - 5; // 5 پیکسل پدینگ
            anchor = ANCHOR_RIGHT;
           }

         ObjectSetInteger(0, obj_name, OBJPROP_XDISTANCE, x_pos);
         ObjectSetInteger(0, obj_name, OBJPROP_YDISTANCE, m_y_offset + y + (h / 2)); // تراز عمودی وسط
         ObjectSetInteger(0, obj_name, OBJPROP_COLOR, text_color);
         ObjectSetInteger(0, obj_name, OBJPROP_BGCOLOR, bg_color);
         ObjectSetInteger(0, obj_name, OBJPROP_FONTSIZE, m_font_size);
         ObjectSetString(0, obj_name, OBJPROP_FONT, m_font_name);
         ObjectSetInteger(0, obj_name, OBJPROP_ANCHOR, anchor);
         ObjectSetInteger(0, obj_name, OBJPROP_BACK, false);
         ObjectSetInteger(0, obj_name, OBJPROP_SELECTABLE, false);
        }
     }

   void UpdateLabelText(string name, string text)
     {
      ObjectSetString(0, m_prefix + name, OBJPROP_TEXT, text);
     }
};
//+------------------------------------------------------------------+
#endif // BBSQUEZEPANEL_MQH