Sys.setenv(BDA400_TEST_MODE='1');source('app.R')
results<-list()
for(provider in c('Yahoo Finance (live)','Stooq (live)')) {
 cat('\nProvider:',provider,'\n')
 z<-tryCatch(fetch_stock('AAPL','2024-01-02','2024-03-28',provider,FALSE),error=function(e)list(error=conditionMessage(e)))
 if(!is.null(z$error)) {cat('ERROR:',z$error,'\n');next}
 cat('Actual source:',z$source,'Rows including buffer:',nrow(z$data),'Range:',as.character(min(z$data$Date)),as.character(max(z$data$Date)),'\n')
 write.csv(z$data,file.path('evidence',if(provider=='Yahoo Finance (live)')'Yahoo_live_check.csv' else 'Stooq_live_check.csv'),row.names=FALSE)
}
