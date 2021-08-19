/* The example EA "Moving Average.mq4" with explanatory comments */

#property copyright   "K. Okazaki"
#property link        "http://www.mql4.com"
#property description "Moving Average.mq4 with explanatory comments"

#define MAGICMA 20131112 // In MT, "magic number" is used to identify programmes (EA, indicator).

/* ---- inputs ---- */
// You can change values of these parameters even after compilation and before trading.
// input double Lots = 0.01; // 'lot' is a unit you can trade in forex markets.
// WE DON'T NEED THIS VARIABLE: Lots. See the function 'LotsOptimized()'
input double MaximumRisk = 0.02; // Do loss-cut when losing 2% of your whole property.
input double DecreaseFactor = 3; // Number of lots will be devided by this factor after you lose consectively
input int MovingPeriod = 10;
input int MovingShift = 3;

/* ---- Calculate open positions ---- */
int CalculateCurrentOrders(/* string symbol */){ // (we don't need this argument 'symbol' here becuase it's not used in this function.)
    int buys = 0, sells = 0;
    /* ---- count up positions run buy this EA ---- */
    for (int i=0; i<OrdersTotal(); i++){ // OrdersTotal() returns a number of orders you have or will.
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) break; // If can't select order, break this for-loop.
        if (OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA){ // Symbol() returns a symbol name (e.g. "usdjpy", "eurusd", ...) of a chart currently displayed.
            if (OrderType()==OP_BUY)   buys++;
            if (OrderType()==OP_SELL) sells++;
        }
    }
    /* ---- return orders volume ---- */
    if (buys > 0) return(buys);
    else return (-sells); // To distinguish from buys, a minus is placed.
    // This function returns 0 if there has been no order by this EA.
    // If there has already been an order because of this EA, this function returns a non-zero value.
}

/* ---- Calculate optimal lot size ---- */
double LotsOptimized(){
    /* double lot = Lots; */ // WE DON'T NEED THIS VARIABLE: Lots
    int orders = OrdersHistoryTotal(); // HistoryTotal() is obsolete. OrdersHistoryTotal() returns a number of closed orders displayed in terminal. This depends on the terminal settings (1 year, 1 month, ... etc.)
    int losses = 0; // number of loss orders

    double lot = NormalizeDouble( // rounds up a double number
        AccountFreeMargin()*MaximumRisk / 100000.0, // 1 lot = 100,000 currency in XMTrading
        1 // round off to one decimal place. e.g. 3.1415 --> 3.1
    )

    /* ---- Adjust lot size according to the number of consecutive losing trades ---- */
    if (DecreaseFactor>0){
        /* ---- count up consecutive losing trades ---- */
        for (int i = orders-1; i>=0; i--){ // scan from new order to old
            if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)){
                Print("Error in history!");
                break;
            }
            if (OrderSymbol()!=Symbol() || OrderType()>OP_SELL/* (The order type is either limit or stop order) */){
                continue;
            }
            if (OrderProfit()>0){ // if (profit of a closed trade)>0, break this for-loop.
                break;
            }
            if (OrderProfit()<0){
                losses++;
            }
        }
        /* ---- adjust lot size ---- */
        if (losses>1){ // if there are consecutive losing trades,
            // decrease lot size
            lot = NormalizeDouble(lot - lot*losses/DecreaseFactor, 1);
        }
    }

    if (lot < 0.01) lot = 0.01;
    return (lot);
}


/* ---- Check for open order conditions and execute entry ---- */
void CheckForOpen(){
    double ma; // Moving Average
    int res; // RESult of entry

    /* ---- go trading only for first tiks of new bar ---- */
    if (Volume[0] > 1){
        // Volume[0] is current bar's volume.
        // Volume[n] means an amount of volume of n bars ago.
        // Volume[Bars-1] is the volume of the oldest bar in a chart.
        // We want to run this EA as a new bar is generated.
        // So if Volume[0]>1, which means the current tick is not the very first one, and we don't want to run this EA.
        // For more info, please refer readme.md.
        return;
    }

    /* ---- get the value of moving average ---- */
    ma = iMA(
        NULL,           // Symbol. if NULL, it means the current symbol.
        PERIOD_CURRENT, // Timeframe (e.g. M30, H1, D1, ... and so on). Google ENUM_TIMEFRAMES for more info.
        MovingPeriod,   // Moving period
        MovingShift,    // Moving shift
        MODE_SMA,       // Type of moving average
        PRICE_CLOSE,    // Applied price
        0               // Shift of bars. If 0, it means the MA is calculated based on the current bar.
    );

    /* ---- sell conditions ---- */
    if (Open[1] > ma && ma > Close[1]){ // When the price crosses the ma line from up to down
        res = OrderSend(
            Symbol(),        // symbol
            OP_SELL,         // operation
            LotsOptimized(), // volume
            Bid,             // price
            3,               // slippage
            0,               // stop loss
            0,               // take profit
            "",              // comment
            MAGICMA,         // magic number
            0,               // pending order expiration
            Red              // color
        );
        return;
    }

    /* ---- buy conditions ---- */
    if (Open[1] < ma && ma < Close[1]){ // When the price crosses the ma line from down to up
        res = OrderSend(
            Symbol(),        // symbol
            OP_BUY,          // operation
            LotsOptimized(), // volume
            Ask,             // price
            3,               // slippage
            0,               // stop loss
            0,               // take profit
            "",              // comment
            MAGICMA,         // magic number
            0,               // pending order expiration
            Blue             // color
        );
        return;
    }
}

/* ---- Check for close order conditions and execute entry ---- */
void CheckForClose(){
    double ma;
    int ret; // RETurn value

    /* ---- Go trading only for the first tick of a new bar ---- */
    if (Volume[0] > 1) return;

    /* ---- get the value of moving average ---- */
    ma = iMA(
        NULL,           // Symbol. if NULL, it means the current symbol.
        PERIOD_CURRENT, // Timeframe (e.g. M30, H1, D1, ... and so on). Google ENUM_TIMEFRAMES for more info.
        MovingPeriod,   // Moving period
        MovingShift,    // Moving shift
        MODE_SMA,       // Type of moving average
        PRICE_CLOSE,    // Applied price
        0               // Shift of bars. If 0, it means the MA is calculated based on the current bar.
    );

    for (int i = 0; i < OrderTotal(); i++){ // Scan for trading orders from old to new
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) break;
        if (OrderMagicNumber!=MAGICMA || OrderSymbol()!=Symbol()) continue;
        if (OrderType() == OP_BUY){
            if (Open[1] > ma && ma > Close[1]){ // When the price crosses the ma line form up to down
                ret = OrderClose(
                    OrderTicket(), // ticket
                    OrderLots(),   // volume
                    Bid,           // close price
                    3,             // slippage
                    White          // color
                );
                if (!ret){
                    Print("OrderClose error: ", GetLastError());
                    break;
                }
            }
        }
        if (OrderType()==OP_SELL){
            if (Open[1] < ma && ma < Close[1]){ // When the price crosses the ma line from down to up
                ret = OrderClose(
                    OrderTicket(), // ticket
                    OrderLots(),   // volume
                    Ask,           // close price
                    3,             // slippage
                    White          // color
                );
                if (!ret){
                    Print("OrderClose error: ", GetLastError());
                    break;
                }
            }
        }
    }
}

/* ---- OnTick function ---- */
void OnTick(){
    if (Bars<100 || !IsTradeAllowed()) return; // Bars = number of total bars displayed in chart window.
    int crnt_orders = CalculateCurrentOrders();
    if (crnt_orders==0) CheckForOpen(); else CheckForClose();
}

