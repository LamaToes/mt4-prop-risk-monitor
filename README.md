MT4/MT5 Prop Style Risk Monitor - Safety Pack Edition
A professional risk management indicator for MetaTrader 4 / MetaTrader 5 that shows real money at risk based on Stop Loss, not guesses.
Built for traders who take risk seriously, especially prop firm traders.
What This Indicator Does
This tool calculates how much money you will lose if all Stop Losses are hit across your open trades.
It displays:

Total % risk based on your account reference size
Total money at risk in dollars
Risk per individual trade ($ and %)
Clean vertical trade list with color-coded warnings
Comprehensive safety alerts and limits
Daily loss tracking for prop firm rules
Trailing drawdown monitoring
Overflow protection if you have many trades open

Why This Is Different
Most traders calculate risk before entering. This shows your actual live risk after execution.
No spreadsheets. No mental math. No assumptions.
This isn't just a display tool - it's a complete safety system that actively monitors and alerts you when you're approaching dangerous territory.
Core Features
Risk Calculation & Display

SL-based money risk calculation - Real dollar amounts, not guesses
Per-trade risk breakdown - See individual position risk in $ and %
Risk % color system:

🟢 Green → Safe risk (≤1%)
🟡 Yellow → Caution (1-2%)
🟠 Orange → Elevated (2-5%)
🔴 Red → High risk (>5%)


Vertical trade column layout - Shows up to 5 trades + overflow counter

Balance Tracking Options

Fixed Balance Mode - Set a reference balance manually
Track Balance Down Only - Updates only when balance drops (perfect for prop challenges)
Auto Track Balance - Automatically follows your live balance
Equity vs Balance - Choose to track equity (includes floating P/L) for more accurate risk

Safety & Alert System

⚠️ Missing Stop Loss Detection - Shows trades without SL (excluded from calculations)
🚨 Max Total Risk Alert - Warning when portfolio risk exceeds your threshold
🚨 Per-Trade Risk Alert - Warns if any single trade risks too much
🚨 Position Count Monitor - Alerts when you have too many open positions
Audio & Visual Alerts - Optional sound/popup notifications

Prop Firm Compliance Tools

Daily Loss Limit Tracker

Set limits in % or fixed dollar amount
Custom session reset time (e.g., "17:00" for NY close)
Alerts before you breach prop firm rules


Trailing Drawdown Monitor

Tracks from highest balance/equity
Critical for prop firm trailing drawdown rules
Configurable in % or $



Professional Display

Clean, organized vertical layout
Color-coded warnings for instant visual feedback
Status indicator shows "All safety checks passed" when safe
Lightweight, no lag
Works on any broker, any symbol

Installation

Copy file to: MQL4 → Indicators
Compile in MetaEditor
Attach to chart
Configure settings:

Set ReferenceBalance (ex: 100000)
Enable desired safety features
Set risk thresholds and limits


Done!

Configuration Guide
Essential Settings

ReferenceBalance - Your account size or prop firm starting balance (defaults to 0 - you must set this!)
PanelCorner - 0 = Top Left, 2 = Bottom Left

Balance Tracking

TrackBalanceDown - Only updates if balance goes below reference (great for prop challenges)
AutoTrackBalance - Always uses current live balance
UseEquityInsteadOfBalance - Use equity for more accurate active trading risk

Risk Limits

MaxTotalRiskPercent - Alert threshold for total portfolio risk (default: 5%)
MaxPerTradeRiskPercent - Alert threshold per trade (default: 2%)
MaxOpenPositions - Maximum number of concurrent trades (default: 10)

Alerts

EnableAlerts - Turn on/off audio and popup alerts
ShowTradesWithoutSL - Display warning for positions missing stop loss

Daily Loss Tracking

TrackDailyLoss - Enable daily loss limit monitoring
DailyLossLimitPercent - Daily loss limit in % (default: 5%)
DailyLossLimitDollar - Fixed $ limit (0 = use % only)
SessionResetTime - When to reset daily tracking (format: "HH:MM")

Trailing Drawdown

TrackTrailingDrawdown - Enable trailing drawdown monitoring
TrailingDrawdownPercent - Limit in % from highest balance (default: 10%)
TrailingDrawdownDollar - Fixed $ limit (0 = use % only)

Who This Helps Most
Prop traders — Stay within daily & max loss limits, pass challenges safely
Swing traders — Manage multi-position exposure across days
Scalpers — Control stacked entries and avoid overtrading
Challenge takers — Track drawdown rules and daily limits automatically
Any serious trader — See risk in dollars, not pips, with comprehensive safety monitoring
Use Cases
✅ Prop Firm Challenges - Never breach rules accidentally
✅ Multi-Position Management - See total exposure instantly
✅ Risk Compliance - Stay within your trading plan limits
✅ Position Sizing Verification - Confirm your risk is what you intended
✅ Daily Stop Management - Know when to stop trading for the day
Why You Need This
If you've ever:

Blown an account by stacking too many trades
Failed a prop challenge by exceeding daily loss limits
Lost track of your total risk exposure
Taken trades without proper stop losses
Wished you had a warning system before things went wrong

This indicator is for you.
Technical Details

Lightweight performance - no chart lag
Works with all brokers and symbols
Compatible with MT4 build 600+
Real-time risk calculation
Persistent session tracking across restarts

Author
Created by LamaToes
If you share or modify this tool, please give credit to the original author.
License
Free to use under MIT License.
Built by traders, for traders.

⚠️ Risk Warning: This indicator is a tool, not financial advice. Trading involves substantial risk. Always use proper risk management and never risk more than you can afford to lose.
