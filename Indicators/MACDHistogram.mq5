

//+------------------------------------------------------------------+
//|                                            MACD Histogram MC.mq5 |
//|                                           Copyright © 2010, AK20 |
//|                                             traderak20@gmail.com |
//|                                                                  |
//|                                                        Based on: |
//|                                                         MACD.mq5 |
//|                        Copyright 2009, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright   "2010, traderak20@gmail.com"
#property description "Moving Average Convergence/Divergence, Histogram, Multi-color"

#include <MovingAverages.mqh>
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots  1

//--- indicator plots
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_color1  clrGreen
#property indicator_width1  3
#property indicator_label1  "MACD"

//--- input parameters
input int                  InpFastEMA=12;                // Fast EMA period
input int                  InpSlowEMA=26;                // Slow EMA period
input int                  InpSignalMA=9;                // Signal MA period
input ENUM_MA_METHOD       InpAppliedSignalMA=MODE_EMA;  // Applied MA method for signal line
input ENUM_APPLIED_PRICE   InpAppliedPrice=PRICE_CLOSE;  // Applied price

//--- indicator buffers
double                     ExtMacdBuffer[];
double                     ExtSignalBuffer[];
double                     ExtHistogramBuffer[];

double                     ExtFastMaBuffer[];
double                     ExtSlowMaBuffer[];
//--- global variables
int                        weightsum_global;             // used for calculation of LWMA
//--- indicator handles
int                        ExtFastMaHandle;
int                        ExtSlowMaHandle;
//--- turn on/off error messages
bool                       ShowErrorMessages=true;       // turn on/off error messages for debugging
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(2,ExtMacdBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(1,ExtSignalBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(0,ExtHistogramBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,ExtFastMaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,ExtSlowMaBuffer,INDICATOR_CALCULATIONS);

//--- set buffers as series, most recent entry at index [0]
   ArraySetAsSeries(ExtMacdBuffer,true);
   ArraySetAsSeries(ExtSignalBuffer,true);
   ArraySetAsSeries(ExtHistogramBuffer,true);
   ArraySetAsSeries(ExtFastMaBuffer,true);
   ArraySetAsSeries(ExtSlowMaBuffer,true);

//--- sets first bar from what index will be drawn

//--- name for indicator
   IndicatorSetString(INDICATOR_SHORTNAME,"MACD("+string(InpFastEMA)+","+string(InpSlowEMA)+","+string(InpSignalMA)+")");

//--- get MA handles
   ExtFastMaHandle=iMA(NULL,0,InpFastEMA,0,MODE_EMA,InpAppliedPrice);
   ExtSlowMaHandle=iMA(NULL,0,InpSlowEMA,0,MODE_EMA,InpAppliedPrice);

//--- initialize global variable used for LWMA
   weightsum_global=0;

//--- initialization done
  }
//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &TickVolume[],
                const long &Volume[],
                const int &Spread[])
  {
//--- check for data
   if(rates_total<InpSignalMA)
      return(0);

//--- not all data may be calculated
   int calculated;

   calculated=BarsCalculated(ExtFastMaHandle);
   if(calculated<rates_total)
     {
      if(ShowErrorMessages) Print("Not all data of ExtFastMaHandle has been calculated (",calculated,"bars ). Error",GetLastError());
      return(0);
     }

   calculated=BarsCalculated(ExtSlowMaHandle);
   if(calculated<rates_total)
     {
      if(ShowErrorMessages) Print("Not all data of ExtSlowMaHandle has been calculated (",calculated,"bars ). Error",GetLastError());
      return(0);
     }

//--- calculate how many bars need to be recalculated
   int to_copy;
   if(prev_calculated>rates_total || prev_calculated<0)
      to_copy=rates_total;
   else
     {
      to_copy=rates_total-prev_calculated;
      if(prev_calculated>0)
         to_copy++;
     }

//--- get fast MA buffer values
   if(CopyBuffer(ExtFastMaHandle,0,0,to_copy,ExtFastMaBuffer)<=0)
     {
      if(ShowErrorMessages) Print("Getting fast EMA failed! Error",GetLastError());
      return(0);
     }

//--- get slow MA buffer values
   if(CopyBuffer(ExtSlowMaHandle,0,0,to_copy,ExtSlowMaBuffer)<=0)
     {
      if(ShowErrorMessages) Print("Getting slow SMA failed! Error",GetLastError());
      return(0);
     }

//--- set limit for which bars need to be (re)calculated
   int limit;
   if(prev_calculated==0 || prev_calculated<0 || prev_calculated>rates_total)
      limit=rates_total-1;
   else
      limit=rates_total-prev_calculated;
//--- older bars ([1]) are needed to set the color of the current bar
   if(limit>rates_total-1-1) limit=rates_total-1-1;

//--- calculate MACD buffer
   for(int i=limit;i>=0;i--)
      ExtMacdBuffer[i]=ExtFastMaBuffer[i]-ExtSlowMaBuffer[i];

//--- calculate Signal buffer
   if(InpAppliedSignalMA==MODE_SMA)
      SimpleMAOnBuffer(rates_total,prev_calculated,0,InpSignalMA,ExtMacdBuffer,ExtSignalBuffer);
   if(InpAppliedSignalMA==MODE_EMA)
      ExponentialMAOnBuffer(rates_total,prev_calculated,0,InpSignalMA,ExtMacdBuffer,ExtSignalBuffer);
   if(InpAppliedSignalMA==MODE_SMMA)
      SmoothedMAOnBuffer(rates_total,prev_calculated,0,InpSignalMA,ExtMacdBuffer,ExtSignalBuffer);
   if(InpAppliedSignalMA==MODE_LWMA)
      LinearWeightedMAOnBuffer(rates_total,prev_calculated,0,InpSignalMA,ExtMacdBuffer,ExtSignalBuffer,weightsum_global);

   for(int i=limit;i>=0;i--)
     {
      ExtHistogramBuffer[i]=ExtMacdBuffer[i]-ExtSignalBuffer[i];
     }

//--- return value of rates_total, will be used as prev_calculated in next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
