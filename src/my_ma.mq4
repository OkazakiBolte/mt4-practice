/* The example EA "Moving Average.mq4" with explanatory comments */

#property copyright   "K. Okazaki"
#property link        "http://www.mql4.com"
#property description "Moving Average.mq4 with explanatory comments"

#define MAGICMA 20210818

/* ---- inputs ---- */
input double MaximumRisk = 0.02;
input double DecreaseFactor = 3;
input int MovingPeriod = 20;
input int MovingShift = 0;

/* ---- Calculate open positions ---- */
int CalculateCurrentOrders(){
    int buys = 0, sells = 0;
    /* ---- count up positions run buy this EA ---- */
    for (int i=0; i<OrdersTotal(); i++){
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) break;
        if (OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA){
            if (OrderType()==OP_BUY)   buys++;
            if (OrderType()==OP_SELL) sells++;
        }
    }
    /* ---- return orders volume ---- */
    if (buys > 0) return(buys);
    else return (-sells);
}

/* ---- Calculate optimal lot size ---- */
double LotsOptimized(){
    /* double lot = Lots; */
    int orders = OrdersHistoryTotal();
    int losses = 0;

    double lot = NormalizeDouble(
        AccountFreeMargin()*MaximumRisk / 100000.0, // 1 lot = 100,000 currency in XMTrading
        1 // round off to one decimal place. e.g. 3.1415 --> 3.1
    );

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
            if (OrderProfit()>0){
                break;
            }
            if (OrderProfit()<0){
                losses++;
            }
        }
        /* ---- adjust lot size ---- */
        if (losses>1){ // if there are consecutive losing trades, decrease lot size
            lot = NormalizeDouble(lot - lot*losses/DecreaseFactor, 1);
        }
    }

    if (lot < 0.01) lot = 0.01;
    return (lot);
}


/* ---- Check for open order conditions and execute entry ---- */
void CheckForOpen(){
    double ma;
    int res;

    /* ---- go trading only for first tiks of new bar ---- */
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
bool CheckForClose(){
    double ma;
    bool ret = false;

    /* ---- Go trading only for the first tick of a new bar ---- */
    if (Volume[0] > 1) return(ret);

    /* ---- get the value of moving average ---- */
    ma = iMA(
        Symbol(),           // Symbol. if NULL, it means the current symbol.
        PERIOD_CURRENT, // Timeframe (e.g. M30, H1, D1, ... and so on). Google ENUM_TIMEFRAMES for more info.
        MovingPeriod,   // Moving period
        MovingShift,    // Moving shift
        MODE_SMA,       // Type of moving average
        PRICE_CLOSE,    // Applied price
        0               // Shift of bars. If 0, it means the MA is calculated based on the current bar.
    );

    for (int i = 0; i < OrdersTotal(); i++){ // Scan for trading orders from old to new
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) break;
        if ((OrderMagicNumber()!=MAGICMA) || (OrderSymbol()!=Symbol())) continue;
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
    return(ret);
}

/* ---- OnTick function ---- */
void OnTick(){
    if (Bars<100 || !IsTradeAllowed()){ // Bars = number of total bars displayed in chart window.
        Print("Number of displayed bars is smaller that 100, or automatic trade is not allowed.");
        return;
    }
    int crnt_orders = CalculateCurrentOrders();
    bool ret;
    if (crnt_orders==0){
        CheckForOpen();
    } else { // close and then recreate position
        ret = CheckForClose();
        if (ret){
            CheckForOpen();
        }
    }
}

