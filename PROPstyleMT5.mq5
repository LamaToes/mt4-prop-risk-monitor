//+------------------------------------------------------------------+
//| PROP STYLE RISK MONITOR - SAFETY PACK (MT5)                      |
//| Created by: LamaToes                                             |
//| Enhanced with comprehensive safety features                      |
//| Free to use under MIT License                                    |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_plots 0
#property strict

input double ReferenceBalance = 0;               // Reference Balance
input ENUM_BASE_CORNER PanelCorner = CORNER_LEFT_UPPER;  // Panel Corner Position
input bool   TrackBalanceDown = false;           // Track Balance Down Only
input bool   AutoTrackBalance = false;           // Auto Track Balance

// === SAFETY SETTINGS ===
input double MaxTotalRiskPercent = 5.0;          // Max Total Risk % (Alert Threshold)
input double MaxPerTradeRiskPercent = 2.0;       // Max Per Trade Risk % (Alert Threshold)
input int    MaxOpenPositions = 10;              // Max Open Positions (Alert Threshold)
input bool   UseEquityInsteadOfBalance = false;  // Use Equity Instead of Balance
input bool   EnableAlerts = true;                // Enable Audio/Visual Alerts
input bool   ShowTradesWithoutSL = true;         // Show Trades Without Stop Loss

// === DAILY LOSS LIMIT TRACKING ===
input bool   TrackDailyLoss = false;             // Track Daily Loss Limit
input double DailyLossLimitPercent = 5.0;        // Daily Loss Limit %
input double DailyLossLimitDollar = 5000;        // Daily Loss Limit $ (0 = use % only)
input string SessionResetTime = "00:00";         // Session Reset Time (HH:MM)

// === TRAILING DRAWDOWN (for Prop Firms) ===
input bool   TrackTrailingDrawdown = false;      // Track Trailing Drawdown
input double TrailingDrawdownPercent = 10.0;     // Trailing Drawdown %
input double TrailingDrawdownDollar = 10000;     // Trailing Drawdown $ (0 = use % only)

#define MAX_VISIBLE_TRADES 5

string HeaderLabel="PS_Header";
string RiskLabel="PS_Risk";
string MoneyLabel="PS_Money";
string BalanceLabel="PS_Balance";
string WarningLabel="PS_Warning";
string AlertLabel="PS_Alert";
string DailyLossLabel="PS_DailyLoss";
string TrailingDDLabel="PS_TrailingDD";
string NoSLLabel="PS_NoSL";
string PositionCountLabel="PS_PosCount";
string TradeLabels[MAX_VISIBLE_TRADES];

double CurrentTrackedBalance = 0;
double SessionStartBalance = 0;
double SessionStartEquity = 0;
double HighestBalance = 0;
double HighestEquity = 0;
datetime LastResetTime = 0;
bool AlertTriggered = false;

//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize tracked balance
   if(CurrentTrackedBalance == 0)
   {
      CurrentTrackedBalance = ReferenceBalance;
   }
   
   // Initialize session tracking
   SessionStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   SessionStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   HighestBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   HighestEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   LastResetTime = TimeCurrent();
   
   // Validate settings
   if(ReferenceBalance <= 0)
   {
      Alert("WARNING: Please set ReferenceBalance in indicator settings!");
   }
   
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Clean up all objects on removal
   ObjectDelete(0,HeaderLabel);
   ObjectDelete(0,RiskLabel);
   ObjectDelete(0,MoneyLabel);
   ObjectDelete(0,BalanceLabel);
   ObjectDelete(0,WarningLabel);
   ObjectDelete(0,AlertLabel);
   ObjectDelete(0,DailyLossLabel);
   ObjectDelete(0,TrailingDDLabel);
   ObjectDelete(0,NoSLLabel);
   ObjectDelete(0,PositionCountLabel);
   
   for(int i=0;i<MAX_VISIBLE_TRADES;i++)
   {
      ObjectDelete(0,"PS_T"+IntegerToString(i));
   }
}
//+------------------------------------------------------------------+
void CheckSessionReset()
{
   if(!TrackDailyLoss && !TrackTrailingDrawdown) return;
   
   MqlDateTime currentTime, lastTime;
   TimeToStruct(TimeCurrent(), currentTime);
   TimeToStruct(LastResetTime, lastTime);
   
   // Parse reset time
   string parts[];
   int split = StringSplit(SessionResetTime, ':', parts);
   int resetHour = (split >= 1) ? (int)StringToInteger(parts[0]) : 0;
   int resetMinute = (split >= 2) ? (int)StringToInteger(parts[1]) : 0;
   
   // Check if we've passed the reset time
   bool shouldReset = false;
   
   if(currentTime.day != lastTime.day)
   {
      // Different day - check if we've passed reset time today
      if(currentTime.hour > resetHour || 
         (currentTime.hour == resetHour && currentTime.min >= resetMinute))
      {
         shouldReset = true;
      }
   }
   else if(currentTime.hour == resetHour && currentTime.min >= resetMinute && 
           lastTime.hour < resetHour)
   {
      // Same day, but crossed reset time
      shouldReset = true;
   }
   
   if(shouldReset)
   {
      SessionStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      SessionStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      LastResetTime = TimeCurrent();
      AlertTriggered = false;
   }
   
   // Update highest values for trailing drawdown
   if(AccountInfoDouble(ACCOUNT_BALANCE) > HighestBalance) 
      HighestBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(AccountInfoDouble(ACCOUNT_EQUITY) > HighestEquity) 
      HighestEquity = AccountInfoDouble(ACCOUNT_EQUITY);
}
//+------------------------------------------------------------------+
void CreateLabel(string name,int y)
{
   ObjectDelete(0,name);
   ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,PanelCorner);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,10);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,10);
   ObjectSetString(0,name,OBJPROP_FONT,"Arial");
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
}
//+------------------------------------------------------------------+
void UpdateTrackedBalance()
{
   double currentBalance = UseEquityInsteadOfBalance ? 
                          AccountInfoDouble(ACCOUNT_EQUITY) : 
                          AccountInfoDouble(ACCOUNT_BALANCE);
   
   if(AutoTrackBalance)
   {
      // Auto track: always use current balance/equity
      CurrentTrackedBalance = currentBalance;
   }
   else if(TrackBalanceDown)
   {
      // Track down only: update only if balance drops below initial reference
      if(currentBalance < ReferenceBalance)
      {
         CurrentTrackedBalance = currentBalance;
      }
      else
      {
         CurrentTrackedBalance = ReferenceBalance;
      }
   }
   else
   {
      // Default: use fixed reference balance
      CurrentTrackedBalance = ReferenceBalance;
   }
}
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
   UpdateTrackedBalance();
   CheckSessionReset();

   // === FIXED POSITIONS ===
   int yStart = 20;
   int yRisk = yStart;
   int yMoney = yStart + 18;
   int yBalance = yStart + 36;
   int yPosCount = yStart + 54;
   int yNoSL = yStart + 72;
   int yTrades = yStart + 95;
   int yDailyLoss = yStart + 195;
   int yTrailingDD = yStart + 213;
   int yWarning = yStart + 231;
   int yAlert = yStart + 249;
   int yHeader = yStart + 267;

   // HEADER
   CreateLabel(HeaderLabel,yHeader);
   ObjectSetInteger(0,HeaderLabel,OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,HeaderLabel,OBJPROP_FONTSIZE,7);
   ObjectSetString(0,HeaderLabel,OBJPROP_TEXT,"= PROPstyle=by LamaToes");

   // === CALCULATE RISK ===
   double totalRisk=0;
   int positionCount=0;
   int tradesWithoutSL=0;
   double maxSingleTradeRisk=0;
   
   // Clear old labels
   for(int i=0;i<MAX_VISIBLE_TRADES;i++)
   {
      TradeLabels[i]="PS_T"+IntegerToString(i);
      ObjectDelete(0,TradeLabels[i]);
   }

   // Loop through all positions (MT5 uses positions instead of orders)
   int totalPositions = PositionsTotal();
   
   for(int i=0; i<totalPositions; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      
      if(!PositionSelectByTicket(ticket)) continue;
      
      // Get position details
      double posVolume = PositionGetDouble(POSITION_VOLUME);
      double posSL = PositionGetDouble(POSITION_SL);
      double posPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      string posSymbol = PositionGetString(POSITION_SYMBOL);
      long posType = PositionGetInteger(POSITION_TYPE);
      
      // Check for positions without SL
      if(posSL == 0)
      {
         tradesWithoutSL++;
         continue;
      }

      // Calculate risk for this position
      double point = SymbolInfoDouble(posSymbol, SYMBOL_POINT);
      double tickSize = SymbolInfoDouble(posSymbol, SYMBOL_TRADE_TICK_SIZE);
      double tickValue = SymbolInfoDouble(posSymbol, SYMBOL_TRADE_TICK_VALUE);
      
      if(tickSize == 0) tickSize = point;
      
      double risk = MathAbs(posPrice - posSL) / tickSize * tickValue * posVolume;
      double riskPercent = (CurrentTrackedBalance > 0) ? (risk/CurrentTrackedBalance)*100.0 : 0;
      
      totalRisk += risk;
      if(risk > maxSingleTradeRisk) maxSingleTradeRisk = risk;

      if(positionCount < MAX_VISIBLE_TRADES)
      {
         CreateLabel(TradeLabels[positionCount], yTrades + positionCount*15);
         
         // Color code by risk
         color tc = clrWhite;
         if(riskPercent > MaxPerTradeRiskPercent) tc = clrRed;
         else if(riskPercent > MaxPerTradeRiskPercent*0.75) tc = clrYellow;
         
         ObjectSetInteger(0,TradeLabels[positionCount],OBJPROP_COLOR,tc);
         ObjectSetString(0,TradeLabels[positionCount],OBJPROP_TEXT,
            "#"+IntegerToString(ticket)+" "+posSymbol+"  $"+DoubleToString(risk,2)+
            " ("+DoubleToString(riskPercent,2)+"%)");
      }

      positionCount++;
   }

   if(positionCount > MAX_VISIBLE_TRADES)
   {
      int extra = positionCount - MAX_VISIBLE_TRADES;
      CreateLabel(TradeLabels[MAX_VISIBLE_TRADES-1], yTrades+(MAX_VISIBLE_TRADES-1)*15);
      ObjectSetString(0,TradeLabels[MAX_VISIBLE_TRADES-1],
         OBJPROP_TEXT,"+"+IntegerToString(extra)+" more positions");
      ObjectSetInteger(0,TradeLabels[MAX_VISIBLE_TRADES-1],OBJPROP_COLOR,clrGray);
   }

   // === TOTAL RISK % LINE ===
   double percent = (CurrentTrackedBalance>0) ? (totalRisk/CurrentTrackedBalance)*100.0 : 0;

   color pc;
   if(totalRisk==0) pc=clrWhite;
   else if(percent<=1) pc=clrLime;
   else if(percent<=2) pc=clrYellow;
   else if(percent<=MaxTotalRiskPercent) pc=clrOrange;
   else pc=clrRed;

   CreateLabel(RiskLabel,yRisk);
   ObjectSetInteger(0,RiskLabel,OBJPROP_COLOR,pc);
   ObjectSetInteger(0,RiskLabel,OBJPROP_FONTSIZE,11);
   ObjectSetString(0,RiskLabel,OBJPROP_TEXT,
      "Total Risk: "+DoubleToString(percent,2)+"% of "+DoubleToString(CurrentTrackedBalance,0));

   // === MONEY LINE ===
   CreateLabel(MoneyLabel,yMoney);
   ObjectSetInteger(0,MoneyLabel,OBJPROP_COLOR,clrMagenta);
   ObjectSetInteger(0,MoneyLabel,OBJPROP_FONTSIZE,10);
   ObjectSetString(0,MoneyLabel,OBJPROP_TEXT,
      "Total Risk: $"+DoubleToString(totalRisk,2));

   // === BALANCE DISPLAY ===
   CreateLabel(BalanceLabel,yBalance);
   ObjectSetInteger(0,BalanceLabel,OBJPROP_COLOR,clrGray);
   ObjectSetInteger(0,BalanceLabel,OBJPROP_FONTSIZE,8);
   string balanceMode = "";
   if(AutoTrackBalance) balanceMode = " [Auto]";
   else if(TrackBalanceDown) balanceMode = " [Down Only]";
   else balanceMode = " [Fixed]";
   string balanceType = UseEquityInsteadOfBalance ? "Equity" : "Balance";
   ObjectSetString(0,BalanceLabel,OBJPROP_TEXT,
      "Tracking "+balanceType+": $"+DoubleToString(CurrentTrackedBalance,2)+balanceMode);

   // === POSITION COUNT ===
   CreateLabel(PositionCountLabel,yPosCount);
   color posColor = (positionCount > MaxOpenPositions) ? clrRed : clrGray;
   ObjectSetInteger(0,PositionCountLabel,OBJPROP_COLOR,posColor);
   ObjectSetInteger(0,PositionCountLabel,OBJPROP_FONTSIZE,9);
   ObjectSetString(0,PositionCountLabel,OBJPROP_TEXT,
      "Open Positions: "+IntegerToString(positionCount)+" / "+IntegerToString(MaxOpenPositions));

   // === TRADES WITHOUT STOP LOSS WARNING ===
   if(ShowTradesWithoutSL && tradesWithoutSL > 0)
   {
      CreateLabel(NoSLLabel,yNoSL);
      ObjectSetInteger(0,NoSLLabel,OBJPROP_COLOR,clrOrangeRed);
      ObjectSetInteger(0,NoSLLabel,OBJPROP_FONTSIZE,9);
      ObjectSetString(0,NoSLLabel,OBJPROP_TEXT,
         "⚠️ "+IntegerToString(tradesWithoutSL)+" trade(s) WITHOUT Stop Loss!");
   }
   else
   {
      ObjectDelete(0,NoSLLabel);
   }

   // === DAILY LOSS TRACKING ===
   if(TrackDailyLoss)
   {
      double currentValue = UseEquityInsteadOfBalance ? 
                           AccountInfoDouble(ACCOUNT_EQUITY) : 
                           AccountInfoDouble(ACCOUNT_BALANCE);
      double sessionStart = UseEquityInsteadOfBalance ? SessionStartEquity : SessionStartBalance;
      double dailyLoss = sessionStart - currentValue;
      double dailyLossPercent = (sessionStart > 0) ? (dailyLoss / sessionStart) * 100.0 : 0;
      
      double limit = DailyLossLimitDollar > 0 ? DailyLossLimitDollar : 
                     (sessionStart * DailyLossLimitPercent / 100.0);
      double limitPercent = DailyLossLimitPercent;
      
      color dlColor = clrGray;
      if(dailyLoss >= limit * 0.8) dlColor = clrOrange;
      if(dailyLoss >= limit) dlColor = clrRed;
      
      CreateLabel(DailyLossLabel,yDailyLoss);
      ObjectSetInteger(0,DailyLossLabel,OBJPROP_COLOR,dlColor);
      ObjectSetInteger(0,DailyLossLabel,OBJPROP_FONTSIZE,9);
      ObjectSetString(0,DailyLossLabel,OBJPROP_TEXT,
         "Daily Loss: $"+DoubleToString(dailyLoss,2)+" ("+DoubleToString(dailyLossPercent,2)+
         "%) / Limit: $"+DoubleToString(limit,2));
      
      // Alert if exceeded
      if(dailyLoss >= limit && EnableAlerts && !AlertTriggered)
      {
         Alert("DAILY LOSS LIMIT EXCEEDED! $"+DoubleToString(dailyLoss,2));
         AlertTriggered = true;
      }
   }
   else
   {
      ObjectDelete(0,DailyLossLabel);
   }

   // === TRAILING DRAWDOWN TRACKING ===
   if(TrackTrailingDrawdown)
   {
      double currentValue = UseEquityInsteadOfBalance ? 
                           AccountInfoDouble(ACCOUNT_EQUITY) : 
                           AccountInfoDouble(ACCOUNT_BALANCE);
      double highest = UseEquityInsteadOfBalance ? HighestEquity : HighestBalance;
      double drawdown = highest - currentValue;
      double drawdownPercent = (highest > 0) ? (drawdown / highest) * 100.0 : 0;
      
      double ddLimit = TrailingDrawdownDollar > 0 ? TrailingDrawdownDollar : 
                       (highest * TrailingDrawdownPercent / 100.0);
      
      color ddColor = clrGray;
      if(drawdown >= ddLimit * 0.8) ddColor = clrOrange;
      if(drawdown >= ddLimit) ddColor = clrRed;
      
      CreateLabel(TrailingDDLabel,yTrailingDD);
      ObjectSetInteger(0,TrailingDDLabel,OBJPROP_COLOR,ddColor);
      ObjectSetInteger(0,TrailingDDLabel,OBJPROP_FONTSIZE,9);
      ObjectSetString(0,TrailingDDLabel,OBJPROP_TEXT,
         "Trailing DD: $"+DoubleToString(drawdown,2)+" ("+DoubleToString(drawdownPercent,2)+
         "%) / Limit: $"+DoubleToString(ddLimit,2));
      
      // Alert if exceeded
      if(drawdown >= ddLimit && EnableAlerts)
      {
         Alert("TRAILING DRAWDOWN LIMIT REACHED! $"+DoubleToString(drawdown,2));
      }
   }
   else
   {
      ObjectDelete(0,TrailingDDLabel);
   }

   // === COMPREHENSIVE WARNING SYSTEM ===
   string warnings = "";
   color warnColor = clrGray;
   
   if(percent > MaxTotalRiskPercent)
   {
      warnings += "⚠️ TOTAL RISK EXCEEDED ("+DoubleToString(percent,2)+"%) ";
      warnColor = clrRed;
      if(EnableAlerts && !AlertTriggered)
      {
         Alert("Total Risk Exceeded: "+DoubleToString(percent,2)+"%");
         AlertTriggered = true;
      }
   }
   
   if(positionCount > MaxOpenPositions)
   {
      warnings += "⚠️ TOO MANY POSITIONS ("+IntegerToString(positionCount)+") ";
      warnColor = clrRed;
   }
   
   if(tradesWithoutSL > 0 && ShowTradesWithoutSL)
   {
      warnings += "⚠️ MISSING STOP LOSS ";
      if(warnColor != clrRed) warnColor = clrOrange;
   }
   
   double maxSingleRiskPercent = (CurrentTrackedBalance > 0) ? 
                                  (maxSingleTradeRisk/CurrentTrackedBalance)*100.0 : 0;
   if(maxSingleRiskPercent > MaxPerTradeRiskPercent)
   {
      warnings += "⚠️ SINGLE TRADE RISK HIGH ("+DoubleToString(maxSingleRiskPercent,2)+"%) ";
      if(warnColor != clrRed) warnColor = clrOrange;
   }
   
   if(CurrentTrackedBalance <= 0)
   {
      warnings = "⚠️ PLEASE SET REFERENCE BALANCE IN SETTINGS!";
      warnColor = clrRed;
   }
   
   if(warnings != "")
   {
      CreateLabel(WarningLabel,yWarning);
      ObjectSetInteger(0,WarningLabel,OBJPROP_COLOR,warnColor);
      ObjectSetInteger(0,WarningLabel,OBJPROP_FONTSIZE,9);
      ObjectSetString(0,WarningLabel,OBJPROP_TEXT,warnings);
   }
   else
   {
      ObjectDelete(0,WarningLabel);
   }
   
   // === STATUS MESSAGE ===
   if(warnings == "" && totalRisk > 0)
   {
      CreateLabel(AlertLabel,yAlert);
      ObjectSetInteger(0,AlertLabel,OBJPROP_COLOR,clrLime);
      ObjectSetInteger(0,AlertLabel,OBJPROP_FONTSIZE,8);
      ObjectSetString(0,AlertLabel,OBJPROP_TEXT,"✓ All safety checks passed");
   }
   else
   {
      ObjectDelete(0,AlertLabel);
   }

   return(rates_total);
}
//+------------------------------------------------------------------+
