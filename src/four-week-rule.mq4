#property copyright "K. Okazaki"
#property link "https://github.com/JoyBolte/mt4-practice"
#property description "Four-week rule"
#property version "1.00"


#define MAGIC_NUMBER 0xAAAA

/* ==== Inputs ==== */
input int window_open  = 20;
input int window_close = 10;
input double MaximumRisk = 0.02;
input double DecreaseFactor = 0.25;

/* ==== OnInit function ==== */
int OnInit(){
    /* ---- Check inputs values ---- */
    if (window_open*window_close <= 0){
        Print("ERROR: Window width must be positive.");
        return(INIT_FAILED);
    }
    return(INIT_SUCCEEDED);
}

/* ==== OnDeinit function ==== */
// void OnDeinit(){} // Does nothing

/* ==== Count up opened positions ==== */
int CalculateCurrentOrders(){
    int buys = 0, sells = 0;
    /* ---- Count up opened positions run by this EA ---- */
    for (int i = 0; i < OrdersTotal(); i++){
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) break;
        if (OrderSymbol()==Symbol() && OrderMagicNumber()==MAGIC_NUMBER){
            if (OrderType()==OP_BUY) buys++;
            if (OrderType()==OP_SELL) sells++;
        }
    }
    /* ---- return orders volume ---- */
    if (buys > 0) return(buys);
    else return (-sells);
}

/* ==== Decide lot size ==== */
double LotsOptimized(){
    int orders = OrdersHistoryTotal();
    int losses = 0;
    double lot_size = NormalizeDouble(
        AccountFreeMargin()*MaximumRisk/100000.0, // 1 lot = 100,000 units of currency in XMTrading
        2
    );
    /* ---- Adjust lot size according to the number of consecutive losing trades ---- */
    if (DecreaseFactor>0){
        /* ---- Count up consecutive losing trades ---- */
        for (int i = orders-1; i >= 0; i--){
            if (!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)){
                Print("Error in history!");
                break;
            }
            if (OrderSymbol()!=Symbol() || OrderType()>OP_SELL/* (The order type is either limit or stop order) */){
                continue;
            }
            if (OrderProfit()>0) break;
            if (OrderProfit()<0) losses++;
        }
        /* ---- If there are consecutive losing trades, decrease lot size  ---- */
        if (losses>1){
            lot_size = NormalizeDouble(lot_size - lot_size*losses*DecreaseFactor, 2);
        }
    }
    if (lot_size < 0.01) lot_size = 0.01;
    return(lot_size);
}

/* ==== Get the highest price value in window width ==== */
double Highest(int width){
    int bar_index;
    double highest = -1;
    bar_index = iHighest(Symbol(), Period(), MODE_HIGH, width+1, 2);
    if (bar_index != -1){
        highest = iHigh(Symbol(), Period(), bar_index);
    } else {
        Print("iHighest error: ", GetLastError());
    }
    return(highest);
}

/* ==== Get the lowest price value in window width ==== */
double Lowest(int width){
    int bar_index;
    double lowest = -1;
    bar_index = iLowest(Symbol(), Period(), MODE_LOW, width+1, 2);
    if (bar_index != -1){
        lowest = iLow(Symbol(), Period(), bar_index);
    } else {
        Print("iLowest error: ", GetLastError());
    }
    return(lowest);
}

/* ==== Check for open order conditions and trade ==== */
bool PositionOpen(){
    bool ret = false;
    int res;
    double highest = Highest(window_open);
    double lowest = Lowest(window_open);

    // Go trading only for the first tick of a new bar
    if (Volume[0] > 1) return(ret);

    // buy
    if (highest <= Close[1]){
        res = OrderSend(
            Symbol(),        // symbol
            OP_BUY,          // operation
            LotsOptimized(), // volume
            Ask,             // price
            3,               // slippage
            0,               // stop loss
            0,               // take profit
            "",              // comment
            MAGIC_NUMBER,    // magic number
            0,               // pending order expiration
            Blue             // color
        );
        if (res >= 0) ret = true;
    }

    // sell
    if (Close[1] <= lowest){
        res = OrderSend(
            Symbol(),        // symbol
            OP_SELL,         // operation
            LotsOptimized(), // volume
            Bid,             // price
            3,               // slippage
            0,               // stop loss
            0,               // take profit
            "",              // comment
            MAGIC_NUMBER,    // magic number
            0,               // pending order expiration
            Red              // color
        );
        if (res >= 0) ret = true;
    }

    return(ret);
}

/* ==== Check for close order conditions and trade ==== */
bool PositionClose(){
    bool ret = false;
    double highest = Highest(window_close);
    double lowest = Lowest(window_close);

    // Go trading only for the first tick of a new bar
    if (Volume[0] > 1) return(ret);

    // Close position
    for (int i = 0; i < OrdersTotal(); i++){
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) break;
        if ((OrderMagicNumber()!=MAGIC_NUMBER) || (OrderSymbol()!=Symbol())) continue;
        // Close a long position
        if (OrderType()==OP_BUY){
            if (Close[1] <= lowest){
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
        // Close a short position
        if (OrderType()==OP_SELL){
            if (highest <= Close[1]){
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

/* ==== OnTick function ==== */
void OnTick(){
    if (Bars < 100 || !IsTradeAllowed()){
        Print("ERROR: (Bars < 100 || !IsTradeAllowed()) = true");
        return;
    }
    int crnt_orders = CalculateCurrentOrders();
    bool isSuccess;
    if (crnt_orders==0){
        isSuccess = PositionOpen();
    } else {
        isSuccess = PositionClose();
        // if (isSuccess) PositionOpen();
    }
}