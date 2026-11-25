# BDA400 Assignment 6 | Bhanu Rachamalla | 25 November 2026
# AI-assisted implementation; actual testing documented in evidence/ and README.
# SECTION 1: Packages and data collection -----------------------------------
library(shiny)
library(ggplot2)
library(quantmod)

validate_ohlcv <- function(d) {
  required <- c('Date','Open','High','Low','Close','Volume')
  if (!all(required %in% names(d))) stop('Provider response lacks required OHLCV columns.')
  d <- d[, required]; d$Date <- as.Date(d$Date)
  for (nm in required[-1]) d[[nm]] <- as.numeric(d[[nm]])
  if (anyNA(d) || any(!is.finite(as.matrix(d[-1])))) stop('Provider response has missing or nonfinite OHLCV values.')
  d <- d[order(d$Date), ]; rownames(d) <- NULL
  if (!nrow(d) || anyDuplicated(d$Date)) stop('Provider returned empty or duplicate dates.')
  if (any(d$High < d$Low | d$High < d$Open | d$High < d$Close |
          d$Low > d$Open | d$Low > d$Close | d$Close <= 0 | d$Volume < 0))
    stop('Invalid price range or volume in provider response.')
  d
}
fetch_stock <- function(symbol, start, end, source, fallback=TRUE) {
  symbol <- toupper(trimws(symbol))
  if (!grepl('^[A-Z][A-Z0-9.-]{0,9}$',symbol)) stop('Use a valid stock ticker, for example AAPL.')
  start <- as.Date(start); end <- as.Date(end)
  if (is.na(start) || is.na(end) || start > end) stop('Start date must be on or before end date.')
  # Buffer supports indicators before the visible date range; no future prices used.
  buffer_start <- start - 600
  cached <- function() {
    path <- file.path('data',paste0(symbol,'.csv'))
    if (!file.exists(path)) stop('No saved Yahoo snapshot exists for this symbol.')
    validate_ohlcv(read.csv(path,stringsAsFactors=FALSE))
  }
  live <- function() {
    if (source == 'Yahoo Finance (live)') {
      # Use system CA trust when present (including managed-network roots).
      ca <- '/etc/ssl/certs/ca-certificates.crt'
      curl_opts <- if(file.exists(ca)) list(cainfo=ca) else list()
      z <- quantmod::getSymbols(symbol,src='yahoo',from=buffer_start,to=end+1,
                               auto.assign=FALSE,warnings=FALSE,curl.options=curl_opts)
      return(validate_ohlcv(data.frame(Date=as.Date(zoo::index(z)),
        Open=as.numeric(Op(z)),High=as.numeric(Hi(z)),Low=as.numeric(Lo(z)),
        Close=as.numeric(Cl(z)),Volume=as.numeric(Vo(z)))))
    }
    if (source == 'Stooq (live)') {
      # US equities use the .us suffix at the independent secondary provider.
      ticker <- paste0(tolower(symbol),'.us')
      url <- paste0('https://stooq.com/q/d/l/?s=',ticker,'&d1=',format(buffer_start,'%Y%m%d'),
                    '&d2=',format(end,'%Y%m%d'),'&i=d')
      tmp <- tempfile(fileext='.csv'); on.exit(unlink(tmp))
      download.file(url,tmp,method='curl',quiet=TRUE)
      return(validate_ohlcv(read.csv(tmp,stringsAsFactors=FALSE)))
    }
    cached()
  }
  warning <- NULL
  d <- tryCatch(live(),error=function(e) {
    if (!fallback || source == 'Saved Yahoo snapshot') stop(conditionMessage(e))
    warning <<- paste('Live request failed:',conditionMessage(e),'Showing saved Yahoo snapshot instead.')
    cached()
  })
  actual_source <- if (!is.null(warning) || source=='Saved Yahoo snapshot') 'Saved Yahoo snapshot' else source
  d <- d[d$Date >= buffer_start & d$Date <= end, ]
  if (!nrow(d) || !any(d$Date >= start & d$Date <= end))
    stop('No observations in the selected dates. Saved snapshots cover 2 Jan–28 Mar 2024.')
  list(data=d,source=actual_source,warning=warning,
       fetched_at=format(Sys.time(),'%Y-%m-%d %H:%M:%S %Z'))
}
aggregate_frame <- function(d,frame) {
  if (frame=='Daily') return(d)
  key <- if(frame=='Weekly') format(d$Date,'%G-%V') else format(d$Date,'%Y-%m')
  out <- do.call(rbind,lapply(split(seq_len(nrow(d)),key),function(ix) {
    x <- d[ix, ]; data.frame(Date=tail(x$Date,1),Open=x$Open[1],High=max(x$High),
      Low=min(x$Low),Close=tail(x$Close,1),Volume=sum(x$Volume))
  }))
  rownames(out) <- NULL; out[order(out$Date), ]
}

# SECTION 2: Technical indicators and causal trading rules ------------------
# These use the standard/causal choices documented in Assignment 5.
rolling_mean <- function(x,p) {
  out <- rep(NA_real_,length(x))
  if (length(x)>=p) for(i in seq.int(p,length(x))) out[i] <- sum(x[(i-p+1):i])/p
  out
}
ema_price <- function(x,p) {
  out <- numeric(length(x)); if(!length(x)) return(out)
  out[1] <- x[1]; if(length(x)>1) for(i in 2:length(x)) out[i] <- out[i-1]+2/(p+1)*(x[i]-out[i-1])
  out
}
wilder_rsi <- function(x,p) {
  out <- rep(NA_real_,length(x)); if(length(x)<=p) return(out)
  dx <- diff(x); gains <- pmax(dx,0); losses <- pmax(-dx,0)
  ag <- sum(gains[1:p])/p; al <- sum(losses[1:p])/p
  score <- function() if(ag==0 && al==0) 50 else if(al==0) 100 else 100-100/(1+ag/al)
  out[p+1] <- score()
  if(length(x)>p+1) for(i in seq.int(p+2,length(x))) {
    ag <- (ag*(p-1)+gains[i-1])/p; al <- (al*(p-1)+losses[i-1])/p; out[i] <- score()
  }
  out
}
cross_events <- function(a,b) {
  if(length(a)!=length(b)) stop('Cross arrays must have equal lengths.')
  out <- rep('Hold',length(a))
  if(length(a)>1) for(i in 2:length(a)) {
    if(anyNA(c(a[i-1],a[i],b[i-1],b[i]))) next
    if(a[i]>b[i] && a[i-1]<=b[i-1]) out[i] <- 'Buy'
    if(a[i]<b[i] && a[i-1]>=b[i-1]) out[i] <- 'Sell'
  }
  out
}
calculate_indicators <- function(d,fast=5,slow=20,rsi_period=14,macd_fast=12,macd_slow=26,macd_signal=9,strategy='MA crossover',rsi_limit=70) {
  pp <- c(fast,slow,rsi_period,macd_fast,macd_slow,macd_signal)
  if(anyNA(pp)||any(!is.finite(pp))||any(pp<1)||any(pp!=floor(pp))) stop('Indicator periods must be positive integers.')
  if(fast>=slow || macd_fast>=macd_slow) stop('Fast periods must be smaller than slow periods.')
  if(!is.finite(rsi_limit)||rsi_limit<1||rsi_limit>100) stop('RSI entry limit must be between 1 and 100.')
  d$FastMA <- rolling_mean(d$Close,fast); d$SlowMA <- rolling_mean(d$Close,slow)
  d$RSI <- wilder_rsi(d$Close,rsi_period)
  d$MACD <- ema_price(d$Close,macd_fast)-ema_price(d$Close,macd_slow)
  d$MACDSignal <- ema_price(d$MACD,macd_signal); d$Histogram <- d$MACD-d$MACDSignal
  d$Signal <- cross_events(d$FastMA,d$SlowMA)
  if(strategy=='MACD crossover + RSI gate') {
    d$Signal <- cross_events(d$MACD,d$MACDSignal)
    for(i in seq_len(nrow(d))) {
      if(i<macd_slow+macd_signal-1 || is.na(d$RSI[i])) d$Signal[i] <- 'Hold'
      else if(d$Signal[i]=='Buy' && d$RSI[i]>=rsi_limit) d$Signal[i] <- 'Hold'
    }
  }
  # No same-close execution: candidate fill belongs to the next aggregate bar.
  d$NextBarDate <- c(as.character(d$Date[-1]),NA_character_)
  d$NextOpen <- c(d$Open[-1],NA_real_)
  d
}

# SECTION 3: Charts, indicators and event annotations -----------------------
make_chart <- function(d,chart='Candlestick',indicators=c('Moving Averages','RSI','MACD'),annotate=TRUE,symbol='AAPL',frame='Daily',date_range=range(d$Date)) {
  # RSI and MACD share the date axis with price in vertically aligned panels.
  # Their distinct units are preserved rather than plotted as dollar prices.
  d$Panel <- 'Price (USD)'
  panel_names <- c('Price (USD)',if('RSI'%in%indicators)'RSI (0–100)',if('MACD'%in%indicators)'MACD (USD)')
  panel <- function(x,name) {x$Panel<-name;x}
  p <- ggplot()+theme_minimal(base_size=12)+
    theme(legend.position='bottom',panel.grid.minor=element_blank(),strip.text=element_text(face='bold'),plot.title=element_text(face='bold'))+
    labs(title=paste(symbol,'·',frame,'·',chart),x=NULL,y=NULL,colour=NULL,fill=NULL)+
    scale_x_date(date_labels='%d %b')+coord_cartesian(xlim=as.Date(date_range))
  if(chart=='Line') p<-p+geom_line(data=d,aes(Date,Close),colour='#153d65',linewidth=.7)
  if(chart=='Area') p<-p+geom_area(data=d,aes(Date,Close),fill='#c8def0',colour='#153d65',alpha=.8)
  if(chart=='Candlestick') {
    width <- if(frame=='Daily') .65 else if(frame=='Weekly') 4 else 16
    d$Direction <- ifelse(d$Close>=d$Open,'Up','Down')
    p<-p+geom_linerange(data=d,aes(x=Date,ymin=Low,ymax=High,colour=Direction),linewidth=.45,show.legend=FALSE)+
      geom_rect(data=d,aes(xmin=Date-width/2,xmax=Date+width/2,ymin=pmin(Open,Close),ymax=pmax(Open,Close),fill=Direction),colour=NA)+
      scale_fill_manual(values=c(Up='#14836b',Down='#d65d5d'))
  }
  cols<-c(Up='#14836b',Down='#d65d5d','Fast MA'='#2b7fc0','Slow MA'='#e89b26',MACD='#2b7fc0','Signal line'='#e89b26')
  if('Moving Averages'%in%indicators) p<-p+
    geom_line(data=d,aes(Date,FastMA,colour='Fast MA'),linewidth=.6,na.rm=TRUE)+
    geom_line(data=d,aes(Date,SlowMA,colour='Slow MA'),linewidth=.7,na.rm=TRUE)
  if(annotate) {
    events<-d[d$Signal!='Hold', ]
    events$Anchor <- ifelse(events$Signal=='Buy',events$Low,events$High)
    p<-p+geom_text(data=events,aes(Date,Anchor,label=Signal),vjust=ifelse(events$Signal=='Buy',1.8,-.7),size=3,colour='#172e47',fontface='bold')
  }
  if('RSI'%in%indicators) {
    r<-panel(d,'RSI (0–100)')
    p<-p+geom_line(data=r,aes(Date,RSI),colour='#8153a7',na.rm=TRUE)+
      geom_hline(data=data.frame(Panel='RSI (0–100)',y=c(30,70)),aes(yintercept=y),linetype=3,colour='grey50')+
      geom_blank(data=data.frame(Panel='RSI (0–100)',Date=rep(d$Date[1],2),y=c(0,100)),aes(Date,y))
  }
  if('MACD'%in%indicators) {
    m<-panel(d,'MACD (USD)')
    p<-p+geom_col(data=m,aes(Date,Histogram),fill='#b3c3d3',width=if(frame=='Daily').65 else if(frame=='Weekly')4 else 16)+
      geom_line(data=m,aes(Date,MACD,colour='MACD'),linewidth=.6)+
      geom_line(data=m,aes(Date,MACDSignal,colour='Signal line'),linewidth=.6)
  }
  # An ordered factor controls facet order even when indicators are disabled.
  for(i in seq_along(p$layers)) if(is.data.frame(p$layers[[i]]$data) && 'Panel'%in%names(p$layers[[i]]$data))
    p$layers[[i]]$data$Panel<-factor(p$layers[[i]]$data$Panel,levels=panel_names)
  p+scale_colour_manual(values=cols)+facet_grid(rows=vars(Panel),scales='free_y')
}

# SECTION 4: Shiny interface and reactive server -----------------------------
ui <- fluidPage(
  tags$head(tags$style(HTML('body{background:#f4f7fb;color:#18344c}.well{background:white;border:1px solid #dce5ee;border-radius:12px}.hero{background:#173655;color:white;padding:20px 26px;margin:0 -15px 18px}.card{background:white;border-radius:12px;padding:16px;margin-bottom:16px;border:1px solid #dce5ee}.status{font-weight:600;color:#22658a} h4{font-weight:700}'))),
  div(class='hero',h2('Stock Analysis Dashboard'),p('Bhanu Rachamalla · BDA400 · Technical Analysis / Visualization Phase')),
  sidebarLayout(sidebarPanel(width=3,
    selectInput('symbol','Stock',c('Apple — AAPL'='AAPL','Microsoft — MSFT'='MSFT','Alphabet — GOOGL'='GOOGL')),
    selectInput('source','Data source',c('Saved Yahoo snapshot','Yahoo Finance (live)','Stooq (live)')),
    checkboxInput('fallback','Use saved Yahoo data if live request fails',TRUE),
    dateRangeInput('dates','Visible dates',start='2024-01-02',end='2024-03-28'),
    selectInput('frame','Time frame',c('Daily','Weekly','Monthly')),
    selectInput('chart','Price chart',c('Candlestick','Line','Area')),
    checkboxGroupInput('indicators','Indicators',c('Moving Averages','RSI','MACD'),selected=c('Moving Averages','RSI','MACD')),
    checkboxInput('annotations','Show Buy / Sell annotations',TRUE),
    selectInput('strategy','Trading rule',c('MA crossover','MACD crossover + RSI gate')),
    fluidRow(column(6,numericInput('fast','Fast MA',5,min=1,max=200)),column(6,numericInput('slow','Slow MA',20,min=2,max=250))),
    numericInput('rsi','RSI period',14,min=1,max=100),numericInput('rsi_limit','RSI entry ceiling',70,min=1,max=100),
    fluidRow(column(4,numericInput('mf','MACD fast',12,min=1,max=100)),column(4,numericInput('ms','Slow',26,min=2,max=200)),column(4,numericInput('sig','Signal',9,min=1,max=100))),
    actionButton('refresh','Fetch / refresh data',class='btn-primary'),br(),br(),downloadButton('download','Download visible CSV')),
    mainPanel(width=9,
      div(class='card',textOutput('status'),verbatimTextOutput('summary')),
      div(class='card',plotOutput('stock_chart',height='740px')),
      div(class='card',h4('Signal candidates'),p('Only crossover events create actions; other bars are Hold. Signals are computed at close. Next-bar open is shown only if that next bar is fully inside the visible end date.'),tableOutput('events')),
      div(class='card',h4('Reading the dashboard'),p('Moving averages overlay price. RSI and MACD use aligned panels because their units differ. Indicators are calculated on buffered data before the visible-date filter. Periods refer to the selected daily, weekly or monthly bars.'),
        p('This is a stock watchlist and signal demonstration, not a holdings ledger or a performance backtest. Candidate orders are not executed. Fees, slippage, taxes and position sizing are omitted. A saved snapshot is historical and may not cover the requested dates.'),p('Yahoo is the primary provider; Stooq is an optional secondary provider whose prices/adjustments may differ. Source and coverage are shown above.')))))
server <- function(input,output,session) {
  loaded <- reactive({
    input$refresh
    tryCatch(fetch_stock(input$symbol,input$dates[1],input$dates[2],input$source,input$fallback),error=function(e) list(error=conditionMessage(e)))
  })
  full <- reactive({
    z<-loaded(); validate(need(is.null(z$error),z$error))
    validate(need(input$fast<input$slow,'Fast MA must be below slow MA.'),need(input$mf<input$ms,'MACD fast must be below slow.'))
    tryCatch(calculate_indicators(aggregate_frame(z$data,input$frame),input$fast,input$slow,input$rsi,input$mf,input$ms,input$sig,input$strategy,input$rsi_limit),error=function(e) validate(need(FALSE,conditionMessage(e))))
  })
  visible <- reactive({
    d<-full(); d<-d[d$Date>=input$dates[1] & d$Date<=input$dates[2], ]
    validate(need(nrow(d)>0,'No aggregate bars in the selected date range.'))
    # Do not show a next-bar fill beyond the selected end date.
    hidden<-!is.na(d$NextBarDate) & as.Date(d$NextBarDate)>input$dates[2]
    d$NextBarDate[hidden]<-NA_character_;d$NextOpen[hidden]<-NA_real_;d
  })
  output$status <- renderText({z<-loaded();validate(need(is.null(z$error),z$error));paste(z$source,'|',if(is.null(z$warning))'Loaded successfully' else z$warning,'|',z$fetched_at)})
  output$summary <- renderText({d<-visible();paste0(input$symbol,' | ',nrow(d),' visible ',tolower(input$frame),' bars | ',min(d$Date),' to ',max(d$Date),'\nLatest close: $',format(round(tail(d$Close,1),2),nsmall=2),' | Latest action: ',tail(d$Signal,1),'\nBuy events: ',sum(d$Signal=='Buy'),' | Sell events: ',sum(d$Signal=='Sell'),' | Hold bars: ',sum(d$Signal=='Hold'),if(all(is.na(d$SlowMA))) '\nInsufficient bars for slow MA; crossover rule remains Hold.' else '')})
  output$stock_chart <- renderPlot({make_chart(visible(),input$chart,input$indicators,input$annotations,input$symbol,input$frame,input$dates)})
  output$events <- renderTable({d<-visible();d<-d[d$Signal!='Hold',c('Date','Close','Signal','NextBarDate','NextOpen')];d$Date<-as.character(d$Date);d},digits=2,rownames=FALSE,na='—')
  output$download <- downloadHandler(filename=function()paste0(input$symbol,'_',input$frame,'_indicators.csv'),content=function(file)write.csv(visible(),file,row.names=FALSE,na=''))
}
app <- shinyApp(ui,server)
if(Sys.getenv('BDA400_TEST_MODE')!='1') app
