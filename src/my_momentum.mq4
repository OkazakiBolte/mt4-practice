#property description "My Momentum"
#property strict

#property indicator_separate_window // Show your custom indicator in a sub window
#property indicator_buffers 1 // The number of indicators we're going to create, I guess
#property indicator_color1 DodgerBlue // The colour of the first indicator

input int InpMomPeriod = 14;
double ExtMomBuffer[];

// ---- Initialization function ----
int OnInit(void) {
    // indicator line
    SetIndexStyle(0, DRAW_LINE); // indicator buffer index = 0, shape style = line
    SetIndexBuffer(0, ExtMomBuffer); // Set the index of ExtMomBuffer as 0
    // Show indicator name on the window
    string short_name = "Mom(" + IntegerToString(InpMomPeriod) + ")";
    IndicatorShortName(short_name);
    SetIndexLabel(0, short_name);
    // Check for the input parameter
    if (InpMomPeriod <= 0) {
        Print("Wrong input parameter, momentum period = ", InpMomPeriod);
        return(INIT_FAILED);
    }

    SetIndexDrawBegin(0, InpMomPeriod);
    // initialization done
    return(INIT_SUCCEEDED);
}

// ---- Momentum ----
int OnCalculate(
    // See the blog written in Japanese below for what each variable means.
    // https://mt4program.blogspot.com/2016/01/mql013-oncalculate.html
    const int rates_total,
    const int prev_calculated,
    const datetime &time[],
    const double &open[],
    const double &high[],
    const double &low[],
    const double &close[],
    const long &tick_volume[],
    const long &volume[],
    const int &spread[]
) {
    // Check the number of bars and if it's less than the period, do nothing
    if (rates_total <= InpMomPeriod) return (0);

    // Use ExtMomBuffer and "close" as ime series arrays (AS_SERIES).
    // If the second argument is false,
    // data aligns from the oldest to the newest (the current bar corresponds to the largest index).
    // In MT4 software, it is common that we use a time series array whose elements align from the newest to the oldest
    // (the second argument = true).
    // If the second arguemt is true, the current bar corresponds to the index 0.
    ArraySetAsSeries(ExtMomBuffer, false);
    ArraySetAsSeries(close, false);

    // Initialize to zero
    int i, limit;
    if (prev_calculated <= 0) {
        // prev_calculated returns the number of OnCalculate called,
        // i.e., the number of calculated elements in retes_total.
        // If the OnCalculate function is called for the first time,
        // prev_calculated equals to zero.
        for (i = 0; i < InpMomPeriod; i++) ExtMomBuffer[i] = 0.0;
        limit = InpMomPeriod;
    } else {
        limit = prev_calculated - 1;
    }

    // The main loop of calculations
    for (i = limit; i < rates_total; i++) {
        ExtMomBuffer[i] = 100 * close[i] / close[i - InpMomPeriod];
    }

    // Done
    return(rates_total);
}