//+------------------------------------------------------------------+
//|                                                        Midas.mq5 |
//|                                        le0nard01 - Leonardo Oste |
//|                                                  www.oste.com.br |
//+------------------------------------------------------------------+
#property copyright "le0nard01 - Leonardo Oste"
#property link      "https://github.com/le0nard01"
#property version   "1.3.2"

/*
   RSI PASSADO ATÉ A ENTRADA MULTIPLICAR TP * .RSI
   EX: 150 (TAKE PROFIT) * PELA SOMA DOS 4 ULTIMOS RSI = .50 -> 150*1.50 = 225 TP
*/

// INCLUDE MIDAS
#include <MidasLib\BibliotecaBot.mqh>

//CONFIG
#define EXPERT_MAGIC 042020
string _SIMBOLO = "WIN";
ENUM_TIMEFRAMES _PERIODO = PERIOD_M1;

//--- INPUT ---//
// DI
input int   DIPDIN = 14;

//MACD
input int   MACD_Fast = 12;
input int   MACD_Slow = 26;
input int   MACD_Signal = 9;

//RSI
input int   RSI_Period = 10;
input int   RSI_MA = 10;
input ENUM_APPLIED_PRICE RSI_Price = PRICE_CLOSE;

// Configuração Midas
//ANALYTIC-1F:
input int   cond_OP_fator = 5;
input int   cond_OP_di = 10;
input bool  cond_OP_di_use = true;

//ANALYTIC-2F:
input int   num_rsi_get = 10;
input bool  cond_rsi_use = true;
input bool  cond_op_rsi = true;

//ANALYTIC-PRICE:
input int   SL = 100;
input int   TP = 150;
input int SL_DAY = 400;
input bool use_sl_day = true;

//-----------------------------------//
//TIME:
input int   cond_2_close_time = 30;
input int   cond_2_open_time = 30;
input bool  cond_2_mid_time = false;
//LOG:
input bool use_log = true;
string log_name = "MidasLog.csv";
string log_dir = "midas-log";
//GLOBAL
MqlDateTime time;
MqlDateTime start_bot_time;
MqlTradeRequest request = {0};
MqlTradeResult  result = {0};
double start_balance;


struct sfator
{
   double            dir; // -1 CONTINUIDADE / 1 REVERSAO / 0 INVERSÃO
   int               position; // 1 POSITIVO / -1 NEGATIVO
   double            fator;
};


// -----------------------| FUNCTIONS |------------------------
double rsi_handle;
double di_handle;
double MACDHandle;
double OBVHandle;
int OnInit()
{
   TimeCurrent(start_bot_time);
   start_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   Print("[INFO] Iniciando Midas | Balança atual: ",start_balance);
   OBVHandle = iCustom(_Symbol,_Period,"OBVCustom");
   MACDHandle = iCustom(NULL,0,"MACDHistogram",MACD_Fast,MACD_Slow,MACD_Signal);
   di_handle = iCustom(NULL,0,"Dif");
   rsi_handle = iCustom(NULL,0,"RSIHistogram",RSI_Period,RSI_MA);

   if(IsStopped())
      return(false);
   if(StringFind(_Symbol,_SIMBOLO) < 0)
   {
      Print("[ERRO] Ativo não é WIN/IND. _Symbol: ",_Symbol);
      return(INIT_FAILED);
   }
   else
   {
      Print("[INFO] Ativo: ",_Symbol);
      if(_Period != _PERIODO)
      {
         Print("[INFO] Operando em M1(padrão), tempo gráfico atual: ",EnumToString(_Period));
      }
      request.action   = TRADE_ACTION_DEAL;                       // tipo de operação de negociação
      request.symbol   = _Symbol;                             // símbolo
      request.volume   = 1;                                     // volume de 0.1 lotes
      request.deviation = 5;                                      // desvio permitido do preço
      request.magic    = EXPERT_MAGIC;                           // MagicNumber da ordem

      return(INIT_SUCCEEDED);
   }

   return(INIT_FAILED);
}
// -----------------------| DI |------------------------ 
bool DI_Func(double& arr[])
{

   double ADXWHandle;
   double dip[];
   double din[];
   double did[];
   sfator fator_di;

   ADXWHandle = iADXWilder(NULL,0,DIPDIN);
   if(IsStopped())
      return(false);
   if(CopyBuffer(ADXWHandle,1,0,3,dip) <= 0) //{[2] == CONST | [1] == 1 ANTES | [0] == 2 ANTES}
   {
      Print("[ERRO] Dados do DIP falhou. Error",GetLastError());
      return(false);
   }

   if(IsStopped())
      return(false);
   if(CopyBuffer(ADXWHandle,2,0,3,din) <= 0) //{[2] == CONST | [1] == 1 ANTES | [0] == 2 ANTES}
   {
      Print("[ERRO] Dados do DIN falhou. Error",GetLastError());
      return(false);
   }
   ArrayResize(did,ArraySize(dip));

   did[0] = (dip[0] - din[0]); //2 ANTES
   did[1] = (dip[1] - din[1]); //1 ANTES

   if(did[0] == 0)
      return false;
   fator_di.position = (int)(did[0] / fabs(did[0]));
   fator_di.fator = fabs((did[0] - did[1]) / did[0]);

   if(fator_di.position != 1 && fator_di.position != -1)
   {
      PrintFormat("[ERRO] Valor position DI invalido! &fator_di.position: ",fator_di.position);
      return false;
   }
   if(((did[0] / fabs(did[0])) + (did[1] / fabs(did[1]))) == 0)
   {
      fator_di.dir = 0;
   }
   else
   {
      double x = (fabs(did[0]) - fabs(did[1])) * 1000;
      fator_di.dir = ((x / fabs(x)));
   }

// array [ 0 = did[0] / 1 = did[1] / 2 = fator / 3 = position / 4 = dir ]

   arr[0] = did[0];
   arr[1] = did[1];
   arr[2] = fator_di.fator;
   arr[3] = fator_di.position;
   arr[4] = fator_di.dir;
   return true;
}


// -----------------------| MACD |------------------------
bool MACD_Func(double& arr[])
{
   double macd_handle[];
   sfator fator_macd;

   if(IsStopped())
      return(false);
   if(CopyBuffer(MACDHandle,0,0,3,macd_handle) <= 0) //{[2] == CONST | [1] == 1 ANTES | [0] == 2 ANTES}
   {
      Print("[ERRO] Dados do Buffer MACD falhou. Error: ",GetLastError());
      return(false);
   }

// MACD_HANDLE[0] = 2 ANTES | [1] = 1 ANTES
   fator_macd.position = (int)(macd_handle[0] / fabs(macd_handle[0]));
   fator_macd.fator = fabs((macd_handle[0] - macd_handle[1]) / macd_handle[0]);

   if(fator_macd.position != 1 && fator_macd.position != -1)
   {
      PrintFormat("[ERRO] Valor position MACD invalido! &fator_macd.position: ",fator_macd.position);
      return false;
   }

   if(((macd_handle[0] / fabs(macd_handle[0])) + (macd_handle[1] / fabs(macd_handle[1]))) == 0)
   {
      fator_macd.dir = 0;
   }

   else
   {
      double x = (fabs(macd_handle[0]) - fabs(macd_handle[1])) * 1000;
      fator_macd.dir = ((x / fabs(x)));
   }

// array [ 0 = did[0] / 1 = did[1] / 2 = fator / 3 = position / 4 = dir ]

   arr[0] = macd_handle[0];
   arr[1] = macd_handle[1];
   arr[2] = fator_macd.fator;
   arr[3] = fator_macd.position;
   arr[4] = fator_macd.dir;
   return true;
}
// -----------------------| RSI |------------------------
//{[2] == CONST | [1] == 1 ANTES | [0] == 2 ANTES}
//{[RSI_MA-1] == CONST}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool RSI(double& fator_rsi[])
{

   double rsi_filtr[];
   CopyBuffer(rsi_handle,0,0,num_rsi_get + 1,rsi_filtr);
   //Print("RSI[1]: ",rsi_filtr[num_rsi_get - 1]);
   for(int i = num_rsi_get - 1; i >= 0; i--)
   {

      if(rsi_filtr[i] < 0)
      {
         fator_rsi[0] += fabs(rsi_filtr[i]);
      }

      if(rsi_filtr[i] > 0)
      {
         fator_rsi[1] += fabs(rsi_filtr[i]);
      }
   }
   //fator_rsi = fator_rsi/num_rsi_get-1;
   //Print("fator: ",fator_rsi);
   if(fator_rsi[0] != 0 || fator_rsi[1] != 0)
   {
      return true;
   }
   else
   {
      Print("[ERRO] Dados do RSI falhou.");
      return false;
   }
}
// -----------------------| ANALYTIC |------------------------
bool analytic_op(int op, double rsifator = 0) // OP 0 = VENDA . OP 1 = COMPRA
{
   /*HistorySelect(0,TimeCurrent()); 
   Print (HistoryDealsTotal());
   if(HistoryDealsTotal() > 0 )
     {
      Print("TSTE");
      double profit = HistoryDealGetDouble(HistoryDealGetTicket(HistoryDealsTotal()-1),DEAL_PROFIT);
      Print("Ultimo profit: ", profit);
     }*/
   if(PositionSelect(_Symbol))
   {
      //Print("[INFO]Posição aberta!");
      return false;
   }
   
   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   int takeprofit;
   int stoploss;
   if(cond_rsi_use)
   {
      takeprofit = (int)(TP * ((rsifator / 100) + 1));
      takeprofit = (int)(ceil(takeprofit / 10)) * 10;
      stoploss = (int)(SL * (((rsifator / 100)) + 1));
      stoploss = (int)(ceil(stoploss / 10)) * 10;
   }
   else
   {
      takeprofit = (int)TP;
      stoploss = (int)SL;
   }


   if(op == 0) //venda
   {
      request.type     = ORDER_TYPE_SELL;
      request.price  = bid;
      request.sl = bid + stoploss;
      request.tp = bid - takeprofit;
      Print("");
      if(!OrderSend(request,result))
         PrintFormat("OrderSend error %d",GetLastError());
      Print("[OP] VENDA | TP: ",takeprofit," | SL: ",stoploss);
   }
   else if(op == 1) //compra
   {
      request.type     = ORDER_TYPE_BUY;
      request.price  = ask;
      request.sl = ask - stoploss;
      request.tp = ask + takeprofit;
      Print("");
      if(!OrderSend(request,result))
         PrintFormat("OrderSend error %d",GetLastError());
      Print("[OP] COMPRA | TP: ",takeprofit," | SL: ",stoploss);
   }
   return true;

}
//+------------------------------------------------------------------+
bool analytic_main(double& macd[], double& di[], double& rsi[]) //RSI[0] SOBRE-VENDA RSI[1] SOBRE-COMPRA
{
//array [ 0 = did[0] / 1 = did[1] / 2 = fator / 3 = position / 4 = dir ]
   if(!Checktime())
   {
      return false;
   }

   if( di[1] > (cond_OP_di * -1) && di[1] < cond_OP_di && cond_OP_di_use)
   {
      return false;
   }
   
   if(macd[4] + di[4] == 2)
   {
      if(macd[3] + di[3] == 2)    //venda
      {
         //TESTER VENDA
         if(cond_op_rsi && (rsi[1] - rsi[0] < 51) && ((di[2] < 0.10) || (macd[2] < 0.10)))
           {
            Print("RSI-DIF MENOR QUE 50!");
            return false;
           }
         
         if (analytic_op(0,rsi[1])) {
            return true;
         }
            return false;

      }
      else if(macd[3] + di[3] == -2) //compra
      {
         //TESTER COMPRA
         if(cond_op_rsi && (rsi[0] - rsi[1] < 51) && ((di[2] < 0.10) || (macd[2] < 0.10)))
              {
               Print("RSI-DIF MENOR QUE 50!");
               return false;
              }
         
         if (analytic_op(1,rsi[0])) {
         return true;
         }
         return false;

      }
   }
   return false;
}
//+------------------------------------------------------------------+
bool Checktime()
{
   TimeCurrent(time);

   if(time.hour <= 9 && time.min <= cond_2_open_time)
   {
      return false;
   }
   else if(time.hour >= 17)
   {
      return false;
   }
   else
   {
      if(time.hour == 13 && time.min <= 60 && cond_2_mid_time)
      {
         return false;
      }
      else
      {
         return true;
      }
   }

   return false;
}
bool isNewDay() {
   TimeCurrent(time);
   if(time.day != start_bot_time.day)
     {
      TimeCurrent(start_bot_time);
      Print("[INFO] Novo dia | Resultado diario: ",(AccountInfoDouble(ACCOUNT_BALANCE)-start_balance));
      return true;
     }
   else if(time.day == start_bot_time.day)
          {
           return false;
          }
   return false;
   
}
bool CheckSLDay(double curr_balance) {
   if(isNewDay())
     {
      start_balance = AccountInfoDouble(ACCOUNT_BALANCE);
     }
   
   if(curr_balance <= ((start_balance)-(SL_DAY*0.20)))
     {
      Print("[INFO] Atingiu SL Diario | Resultado do dia: ",(AccountInfoDouble(ACCOUNT_BALANCE)-start_balance));  
      return false;
     }
   else
     {
      return true;
     }
   return false;
   
}

// -----------------------|      ONTICK      |------------------------

void OnTick()
{

   if(isNewBar(_PERIODO))
   {
      //array [ 0 = did[0] / 1 = did[1] / 2 = fator / 3 = position / 4 = dir ]
      double curr_balance = AccountInfoDouble(ACCOUNT_BALANCE);
      if(!CheckSLDay(curr_balance) && use_sl_day)
        {
         return;
        }
      double rsiinfo[2];
      double diinfo[5];
      double macdinfo[5];
      double high[];
      double low[];

      CopyHigh(_Symbol,_Period,0,2,high);
      CopyLow(_Symbol,_Period,0,2,low);
      if(!DI_Func(diinfo) || !MACD_Func(macdinfo) || !RSI(rsiinfo))
      {
         Print("[ERRO] Erro ao obter dados.");
         return;
      }
      PrintFormat("DID: %.2f | MACD: %.2f || F_DID: %.2f | F_MACD: %.2f || F_RSI+: %.0f | F_RSI-: %.0f || DIR: %.0f %.0f | POS: %.0f %.0f | H-L: %.0f",diinfo[1],macdinfo[1],diinfo[2],macdinfo[2],rsiinfo[1],rsiinfo[0],diinfo[4],macdinfo[4],diinfo[3],macdinfo[3],(high[0] - low[0]));
      analytic_main(macdinfo, diinfo, rsiinfo);
      /*if(analytic_main(macdinfo, diinfo, rsiinfo))
        {
         PrintFormat("DID: %.2f | MACD: %.2f || F_DID: %.2f | F_MACD: %.2f || F_RSI+: %.0f | F_RSI-: %.0f || DIR: %.0f %.0f | POS: %.0f %.0f | H-L: %.0f",diinfo[1],macdinfo[1],diinfo[2],macdinfo[2],rsiinfo[1],rsiinfo[0],diinfo[4],macdinfo[4],diinfo[3],macdinfo[3],(high[0] - low[0]));
        }*/
       
      }
}
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{

}

/*float OBV_Func(const int rates_total, const int block)
  {

   double obv_handle[];
   double mediaobv[];
   CopyBuffer(iOBV(_Symbol,_PERIODO,VOLUME_TICK),0,0,rates_total,obv_handle);
   ArrayResize(mediaobv,ArraySize(obv_handle));
   mediaobv[block] = MediaS(obv_handle,3,block);

   return 0;
  }*/

//+------------------------------------------------------------------+
