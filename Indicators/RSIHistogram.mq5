//+------------------------------------------------------------------+
//|                                                 RSIHistogram.mq5 |
//|                                        le0nard01 - Leonardo Oste |
//|                                                  www.oste.com.br |
//+------------------------------------------------------------------+
#property copyright "le0nard01 - Leonardo Oste"
#property link      "https://github.com/le0nard01"
#property version   "1.01"

#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   1

//--- plot RSI
#property indicator_label1  "RSI HISTOGRAM"
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrCyan
#property indicator_width1  2

//--- indicator buffers
double         rsihBuffer[];
double         rsiMediaBuffer;
double         rsiCalc[];
double         RSIHandle;

input int RSI_Period = 9;
input int RSI_Media = 9;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
//--- indicator buffers mapping
   SetIndexBuffer(0,rsihBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,rsiCalc,INDICATOR_CALCULATIONS);

   RSIHandle = iRSI(_Symbol,_Period,RSI_Period,PRICE_CLOSE);
//---
   return(INIT_SUCCEEDED);
}
//|                                                                  |
//+------------------------------------------------------------------+
double SimpleMA(const int position,const int period,const double &price[])
{
//---
   double result = 0.0;
//--- check position
   Comment(position," | ",period);
   if(position >= period - 1 && period > 0)
   {

      //--- calculate value
      for(int i = 0; i < period; i++) result += price[position - i];
      result /= period;
   }
   return result;
}

//+------------------------------------------------------------------+
//|                                                                  |
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

   if(rates_total < RSI_Period) return(0);

   int calculated = BarsCalculated(RSIHandle);

   if(calculated < rates_total)
   {
      Print("Os dados de RSIHandle não foram totalmente calculados (",calculated,"bars ). Error",GetLastError());
      return(0);
   }


   int to_copy;
   if(prev_calculated > rates_total || prev_calculated < 0)
      to_copy = rates_total;
   else
   {
      to_copy = rates_total - prev_calculated;
      if(prev_calculated > 0)
         to_copy++;
   }

   if(IsStopped())
      return(0);
   if(CopyBuffer(RSIHandle,0,0,rates_total,rsiCalc) <= 0)
   {
      Print("Dados do RSI falhou. Error",GetLastError());
      return(0);
   }

   int limit;
   if(prev_calculated == 0)
      limit = 0;
   else
      limit = prev_calculated - 1;

   for(int i = limit; i < rates_total && !IsStopped(); i++)
   {
      rsiMediaBuffer = SimpleMA(i,RSI_Media,rsiCalc);
      //Print(rsiMediaBuffer);
      //Comment(rsiMediaBuffer);
      rsihBuffer[i] =  rsiCalc[i]-rsiMediaBuffer;
      //Comment("rsiMediaBuffer: ",rsiMediaBuffer,"\n RSI: ",rsiCalc[i]);
      //Print(i);
      //Comment("DIP: ", string(DIPBuffer[i]), "\nDIN: ", string(DINBuffer[i]), "\nDIF: ", string(DIFBuffer[i]));
   }


//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
/*
input
  RSIPeriodo(9);
  RSIMedia(9);
  RSICondicao(10);

var
  rsidif, md : Float;

begin
  md := Media(RSIMedia,RSI(RSIPeriodo,0));
  rsidif := RSI(RSIPeriodo,0) - md;
  Plot(rsidif);
  if rsidif > RSICondicao then
  begin
    PaintBar(cllime);
  end
  else if rsidif < Neg(RSICondicao) then
  begin
    PaintBar(clred);
  end
  else
    PaintBar(clwhite);
end;
*/
//+------------------------------------------------------------------+
