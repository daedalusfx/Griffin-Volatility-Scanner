//+------------------------------------------------------------------+
//|                                           BBSqueezePanel.mqh |
//|        کلاس پنل اسکنر BB Squeeze (بر اساس VdsPanel)           |
//|                        (نسخه ۱.۰)                             |
//+------------------------------------------------------------------+
#ifndef BBSQUEEZEPANEL_MQH
#define BBSQUEEZEPANEL_MQH

#include <Controls\Label.mqh> // (از VdsPanel می‌دانیم که به این نیاز داریم)

//+------------------------------------------------------------------+
//| ساختار برای نگهداری نتایج اسکن (برای هر سلول)
//+------------------------------------------------------------------+
struct SqueezeResult
  {
   // --- وضعیت‌ها ---
   bool              inSqueeze;
   bool              isAscending;     // MA Stack صعودی
   bool              isDescending;    // MA Stack نزولی
   bool              upTrend;           // Keltner Channel
   bool              downTrend;         // Keltner Channel
   bool              upSlowing;
   bool              downSlowing;

   // --- مقادیر نمایشی ---
   string            cellText;          // متن نهایی (●/○ ↗ ↑)
   color             cellBgColor;       // رنگ پس‌زمینه سلول
   color             pairNameColor;     // رنگ جفت ارز (برای همسویی)
   int               barsSinceSwitch;   // (فعلا V1 - این پیچیده‌ست، بعدا اضافه می‌کنیم)
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
      // (نیاز به توابع کمکی برای تبدیل رشته MA و TF به آرایه عددی/Enum داریم)
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
      // این تابع قلب تپنده خواهد بود
      // ما در گام بعدی این را کامل می‌کنیم

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
            // result = f_calculateAllSignals(m_pair_array[i], m_tf_enum_array[j]); // (گام بعدی)

            // (شبیه‌سازی نتیجه برای تست ظاهری)
            if(MathRand() % 2 == 0)
              {
               result.cellText = "● (3) ↗ ↑";
               result.cellBgColor = m_color_low_vol;
               result.isAscending = true;
              }
            else
              {
               result.cellText = "○ (10) ↘ ↓";
               result.cellBgColor = m_color_high_vol;
               result.isDescending = true;
              }
            // (پایان شبیه‌سازی)


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
            ObjectSetInteger(0, cell_name, OBJPROP_COLOR, m_color_text); // رنگ متن
           }

         // ۴. آپدیت رنگ نام جفت ارز بر اساس همسویی
         string pair_label_name = m_prefix + "pair_" + (string)i;
         color pair_name_color = m_color_text; // رنگ پیش‌فرض
         if(m_check_ma_stack)
           {
            if(aligned_up_count >= m_min_tf_aligned) pair_name_color = m_color_ma_up;
            else if(aligned_down_count >= m_min_tf_aligned) pair_name_color = m_color_ma_down;
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
   // (منطق اصلی) محاسبه سیگنال‌ها برای یک سلول
   //------------------------------------------------------------------
   SqueezeResult f_calculateAllSignals(string symbol, ENUM_TIMEFRAMES tf)
     {
      SqueezeResult res;
      // صفر کردن مقادیر
      res.inSqueeze = false;
      res.isAscending = false;
      res.isDescending = false;
      // ...
      res.cellText = "Loading...";
      res.cellBgColor = C'50,50,50';

      // =========================================================
      // گام بعدی: ما این تابع را با iBands, iMA, iATR کامل می‌کنیم
      // =========================================================

      // (این تابع باید تمام هندل‌های اندیکاتور را بسازد،)
      // (دیتای لازم را با CopyBuffer بخواند،)
      // (منطق Squeeze و MA Stack را اجرا کند،)
      // (و تمام هندل‌ها را با IndicatorRelease آزاد کند.)

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

      // محاسبه ابعاد کلی پنل
      int total_width = m_header_width + (num_tfs * m_cell_width);
      int total_height = m_cell_height + (num_pairs * m_cell_height);

      // رسم پس‌زمینه اصلی
      CreateRect("Panel_BG", 0, 0, total_width, total_height, m_color_bg, 200); // 200 = alpha

      int current_y = 0;

      // --- ۱. رسم هدر (تایم‌فریم‌ها) ---
      // سلول خالی بالای نام جفت ارزها
      CreateLabel("header_corner", "PAIRS", 0, current_y, m_header_width, m_cell_height, m_color_bg, m_color_text, ALIGN_CENTER);

      // رسم هدر تایم‌فریم‌ها
      for(int j = 0; j < num_tfs; j++)
        {
         int x_pos = m_header_width + (j * m_cell_width);
         CreateLabel("tf_" + (string)j, m_tf_array[j], x_pos, current_y, m_cell_width, m_cell_height, m_color_bg, m_color_text, ALIGN_CENTER);
        }

      current_y += m_cell_height;

      // --- ۲. رسم ردیف‌ها (جفت ارزها و سلول‌های داده) ---
      for(int i = 0; i < num_pairs; i++)
        {
         // رسم نام جفت ارز (هدر ردیف)
         CreateLabel("pair_" + (string)i, m_pair_array[i], 0, current_y, m_header_width, m_cell_height, m_color_bg, m_color_text, ALIGN_CENTER);

         // رسم سلول‌های داده (فعلا خالی)
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
      // این تابع باید کامل‌تر شود
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

   // تابع CreateLabel را برای پشتیبانی از پس‌زمینه و تراز وسط تغییر می‌دهیم
   void CreateLabel(string name, string text, int x, int y, int w, int h, color bg_color, color text_color, ENUM_ALIGN_MODE align = ALIGN_LEFT)
     {
      string obj_name = m_prefix + name;
      if(ObjectFind(0, obj_name) < 0)
        {
         ObjectCreate(0, obj_name, OBJ_LABEL, 0, 0, 0);
         ObjectSetString(0, obj_name, OBJPROP_TEXT, text);
         ObjectSetInteger(0, obj_name, OBJPROP_CORNER, m_panel_corner);

         // تنظیم موقعیت X بر اساس تراز
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
#endif // BBSQUEEZEPANEL_MQH