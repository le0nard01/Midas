//+------------------------------------------------------------------+
//|                                                BibliotecaBot.mq5 |
//|                                        le0nard01 - Leonardo Oste |
//|                                                  www.oste.com.br |
//+------------------------------------------------------------------+
#property copyright "le0nard01 - Leonardo Oste"
#property link      "https://github.com/le0nard01"

bool isNewBar(ENUM_TIMEFRAMES PERIODO) //NOVA BARRA
  {
   static datetime last_time=0;
   datetime lastbar_time=(datetime)SeriesInfoInteger(Symbol(),PERIODO,SERIES_LASTBAR_DATE);
   if(last_time==0)
     {
      last_time=lastbar_time;
      return(false);
     }
   if(last_time!=lastbar_time)
     {
      last_time=lastbar_time;
      return(true);
     }
   return(false);
  }

double SimpleMA(const int position,const int period,const double &price[])
{
//---
   double xxresult = 0.0;
//--- check position
   Comment(position," | ",period);
   if(position >= period - 1 && period >= 0)
   {

      //--- calculate value
      for(int i = 0; i < period; i++) xxresult += price[position - i];
      xxresult /= period;
   }
   return xxresult;
}


//FUNC MEDIA
double MediaS(const double &buffer[], const int periodo, const int casa)
  {
   double md=0;
   for(int x=0; x!=periodo; x++)
     {
      md += buffer[casa-x];
     }
   md = md/periodo;
   return md;
  }
//+------------------------------------------------------------------+
