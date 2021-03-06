//+------------------------------------------------------------------+
//|                                                          Dif.mq5 |
//|                                        le0nard01 - Leonardo Oste |
//|                                                  www.oste.com.br |
//+------------------------------------------------------------------+
#property copyright "le0nard01 - Leonardo Oste"
#property link      "https://github.com/le0nard01"
#property version   "1.01"
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   1
//--- plot DIF
#property indicator_label1  "DIF"
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrRed
#property indicator_width1  3
//--- input parameters
input int      DIPAR=14;
//--- indicator buffers
double         DIFBuffer[];
double         DIPBuffer[];
double         DINBuffer[];

double ADXHandle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,DIFBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,DIPBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,DINBuffer,INDICATOR_CALCULATIONS);
   

   //ADXHandle = iADX(NULL,0,DIPAR);
   ADXHandle = iADXWilder(NULL,0,DIPAR);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   if(rates_total<DIPAR)
      return(0);

   int calculated=BarsCalculated(ADXHandle);
   
   if(calculated<rates_total)
     {
      Print("Os dados de ADXHandle não foram totalmnte calculados (",calculated,"bars ). Error",GetLastError());
      return(0);
     }


   int to_copy;
   if(prev_calculated>rates_total || prev_calculated<0)
      to_copy=rates_total;
   else
     {
      to_copy=rates_total-prev_calculated;
      if(prev_calculated>0)
         to_copy++;
     }

   if(IsStopped())
      return(0);
   if(CopyBuffer(ADXHandle,1,0,rates_total,DIPBuffer)<=0)
     {
      Print("Dados do DIP falhou. Error",GetLastError());
      return(0);
     }

   if(IsStopped())
      return(0);
   if(CopyBuffer(ADXHandle,2,0,rates_total,DINBuffer)<=0)
     {
      Print("Dados do DIN falhou. Error",GetLastError());
      return(0);
     }

//--- calculate MACD
   int limit;
   if(prev_calculated==0)
      limit=0;
   else
      limit=prev_calculated-1;
   
   for(int i=limit; i<rates_total && !IsStopped(); i++)
     {
      DIFBuffer[i]=DIPBuffer[i]-DINBuffer[i];
      //Comment("DIP: ", string(DIPBuffer[i]), "\nDIN: ", string(DINBuffer[i]), "\nDIF: ", string(DIFBuffer[i]));
     }
   

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
