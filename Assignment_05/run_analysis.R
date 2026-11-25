# Run from Assignment_05; only core/base R and its graphics devices are used.
source('load_all.R')
dir.create('outputs', showWarnings=FALSE)
read_stock <- function(symbol) {
  d <- read.csv(file.path('data', paste0(symbol,'.csv')), stringsAsFactors=FALSE)
  d$Date <- as.Date(d$Date); d <- d[order(d$Date), ]
  stopifnot(!anyDuplicated(d$Date), !anyNA(d), all(d$High >= d$Low),
            all(d$Open <= d$High), all(d$Close <= d$High),
            all(d$Open >= d$Low), all(d$Close >= d$Low), all(d$Volume >= 0))
  d$Symbol <- symbol; d$Source <- 'Yahoo Finance'; d
}
filter_data <- function(d, start, end, source='Yahoo Finance') {
  d[d$Date >= as.Date(start) & d$Date <= as.Date(end) & d$Source == source, ]
}
weekly_data <- function(d) {
  # ISO calendar week; aggregate observed sessions, including partial weeks.
  groups <- split(seq_len(nrow(d)), format(d$Date,'%G-%V'))
  out <- do.call(rbind, lapply(groups, function(ix) {
    x <- d[ix, ]; z <- x[nrow(x), ]
    z$Open <- x$Open[1]; z$High <- max(x$High); z$Low <- min(x$Low)
    z$Volume <- sum(x$Volume); z
  }))
  rownames(out) <- NULL; out[order(out$Date), ]
}
pad_sma <- function(x,p) c(rep(NA_real_,p-1),sma(x,p))
frames <- lapply(c('AAPL','MSFT','GOOGL'), read_stock)
names(frames) <- c('AAPL','MSFT','GOOGL')
latest <- list(); signals <- list()
for (symbol in names(frames)) {
  d <- frames[[symbol]]; x <- d$Close; n <- nrow(d)
  d$SMA5 <- pad_sma(x,5); d$SMA20 <- pad_sma(x,20)
  d$EMA12 <- ema(x,12); d$EMA26 <- ema(x,26)
  m <- macd(x,12,26,9); d$MACD <- m$macd_line
  d$Signal <- m$signal_line; d$Histogram <- m$histogram
  d$RSI_spec14 <- rsi(x,14); d$RSI_Wilder14 <- rsi_wilder(x,14)
  s <- stoch_rsi(x,14,3,3)
  d$StochRSI_spec_K <- c(rep(NA_real_,2), s$k_line)
  d$StochRSI_spec_D <- c(rep(NA_real_,4), s$d_line)
  s <- stoch_rsi_rolling(x,14,3,3)
  d$StochRSI_rolling_K <- s$k_line; d$StochRSI_rolling_D <- s$d_line
  d$SMA_cross <- crossover(d$SMA5,d$SMA20)
  d$MACD_cross <- crossover(d$MACD,d$Signal)
  d$SMA_rule <- ifelse(d$SMA_cross=='Up','BUY',ifelse(d$SMA_cross=='Down','SELL','HOLD'))
  d$MACD_rule <- 'HOLD'
  for (i in seq_len(n)) {
    # Skip initial EMA stabilization and RSI warm-up.
    if (i < 34 || is.na(d$RSI_Wilder14[i])) next
    if (d$MACD_cross[i]=='Up' && d$RSI_Wilder14[i] < 70) d$MACD_rule[i] <- 'BUY'
    if (d$MACD_cross[i]=='Down' || d$RSI_Wilder14[i] > 70) d$MACD_rule[i] <- 'SELL'
  }
  d$NextSessionDate <- c(as.character(d$Date[-1]), NA_character_)
  d$NextOpen <- c(d$Open[-1],NA_real_)
  write.csv(d,file.path('outputs',paste0(symbol,'_indicators.csv')),row.names=FALSE,na='')
  write.csv(weekly_data(frames[[symbol]]),file.path('outputs',paste0(symbol,'_weekly.csv')),row.names=FALSE)
  write.csv(filter_data(frames[[symbol]],'2024-02-01','2024-02-29'),
            file.path('outputs',paste0(symbol,'_February.csv')),row.names=FALSE)
  lr <- linreg(x,20,0)
  latest[[symbol]] <- data.frame(Symbol=symbol,Rows=n,Date=tail(d$Date,1),
    Close=tail(x,1),SMA20=tail(d$SMA20,1),EMA12=tail(d$EMA12,1),MACD=tail(d$MACD,1),
    Signal=tail(d$Signal,1),RSI_spec14=tail(d$RSI_spec14,1),RSI_Wilder14=tail(d$RSI_Wilder14,1),
    PopulationSD=stdev(x),RegressionSlope=lr$slope,RegressionIntercept=lr$intercept,
    RegressionPoints=length(lr$predicted_values),WeeklyRows=nrow(weekly_data(d)))
  signals[[symbol]] <- d[d$SMA_rule!='HOLD' | d$MACD_rule!='HOLD',
                         c('Date','Symbol','Close','RSI_Wilder14','SMA_rule','MACD_rule','NextSessionDate','NextOpen')]
  png(file.path('outputs',paste0(symbol,'_dashboard.png')),width=1400,height=1100,res=140)
  par(mfrow=c(3,1),mar=c(3,4,2,1))
  plot(d$Date,x,type='l',xlab='',ylab='USD',main=paste(symbol,'Close and SMA (5 / 20)'))
  lines(d$Date,d$SMA5,col='steelblue'); lines(d$Date,d$SMA20,col='orange3')
  legend('topright',c('Close','SMA5','SMA20'),col=c('black','steelblue','orange3'),lty=1,cex=.7)
  plot(d$Date,d$MACD,type='l',xlab='',ylab='USD',main='MACD (12,26,9): first-price EMA seed')
  lines(d$Date,d$Signal,col='orange3'); abline(h=0,col='grey')
  plot(d$Date,d$RSI_Wilder14,type='l',ylim=c(0,100),xlab='Date',ylab='RSI',main='Standard Wilder RSI14 (used for rule demonstration)')
  lines(d$Date,d$RSI_spec14,col='orange3',lty=2); abline(h=c(30,70),lty=3,col='grey')
  legend('topright',c('Wilder','Supplied pseudocode'),col=c('black','orange3'),lty=c(1,2),cex=.7)
  dev.off()
}
latest <- do.call(rbind,latest); rownames(latest) <- NULL
write.csv(latest,'outputs/latest_summary.csv',row.names=FALSE)
screen <- latest[latest$Close > latest$SMA20 & latest$RSI_Wilder14 >=30 & latest$RSI_Wilder14 <=70 & latest$MACD > latest$Signal, ]
write.csv(screen,'outputs/latest_screen.csv',row.names=FALSE)
write.csv(do.call(rbind,signals),'outputs/trading_signals.csv',row.names=FALSE,na='')
cat('Historical snapshots: 2024-01-02 through 2024-03-28; 61 sessions per symbol.\n')
print(latest,digits=7,row.names=FALSE)
cat('\nLatest screen: Close>SMA20; RSI Wilder in [30,70]; MACD>signal\n')
print(screen,row.names=FALSE)
cat('\nSignal candidates (not a position-aware backtest):\n'); print(do.call(rbind,signals),row.names=FALSE)
cat('\nRuntime:\n'); print(sessionInfo())
