setwd("./")
options(warn = 2)
library("xgboost")
library(data.table)
library(doParallel)
library(foreach)
options(java.parameters = "-Xmx8g") #dont increase dramatically because computer will freeze
library(RSQLite)
m=dbDriver("SQLite")

#qual pasta de modelo usar,qual pasta de slice usar, qual o tamanho da janela
args = commandArgs(trailingOnly=TRUE)
args[1] = "modelo_zero"
args[2] = "slices"

#chainlist é lista de cadeias sintéticas para auxiliar na substituição
chainList = fread(paste0(args[2], "/chainEvaluationListRand.csv"), sep = ",")
chainList = chainList[numocurr > 5,]
chainList$isMobile = 0;
chainList$isDesktop = 0;
chainList$isDesktop[chainList$device == "desktop" | chainList$device == "television"] = 1;
chainList$isMobile[chainList$device == "mobile"] = 1;
chainList = chainList[, -c("device")]
##################################################################################
#ajustando a janela para se tornar uma instância no previsor
normalization = function(dados){
    dados$isMobile = 0;
    dados$isDesktop = 0;
    dados$isDesktop[dados$device == "desktop" | dados$device == "television"] = 1;
    dados$isMobile[dados$device == "mobile"] = 1;
    
    #reordering
    dados = cbind(dados[,-c(6,77,78,79,80,81,82,83,84)],dados[,c("next0minute","next1minute")])
    dados[["next1minute"]] = as.factor(dados[["next1minute"]])
    
    #normalizando pelo total de trocas e segmentos
    dados$tot264 = dados$q264_264+dados$q264_396+dados$q264_594+dados$q264_891+dados$q264_1337+dados$q264_2085+dados$q264_3127
    dados$tot396 = dados$q396_264+dados$q396_396+dados$q396_594+dados$q396_891+dados$q396_1337+dados$q396_2085+dados$q396_3127
    dados$tot594 = dados$q594_264+dados$q594_396+dados$q594_594+dados$q594_891+dados$q594_1337+dados$q594_2085+dados$q594_3127
    dados$tot891 = dados$q891_264+dados$q891_396+dados$q891_594+dados$q891_891+dados$q891_1337+dados$q891_2085+dados$q891_3127
    dados$tot1337 = dados$q1337_264+dados$q1337_396+dados$q1337_594+dados$q1337_891+dados$q1337_1337+dados$q1337_2085+dados$q1337_3127
    dados$tot2085 = dados$q2085_264+dados$q2085_396+dados$q2085_594+dados$q2085_891+dados$q2085_1337+dados$q2085_2085+dados$q2085_3127
    dados$tot3127 = dados$q3127_264+dados$q3127_396+dados$q3127_594+dados$q3127_891+dados$q3127_1337+dados$q3127_2085+dados$q3127_3127
    dados$q264_264[dados$tot264 > 0] = round(dados$q264_264[dados$tot264 > 0]/dados$tot264[dados$tot264 > 0],3);
    dados$q264_396[dados$tot264 > 0] = round(dados$q264_396[dados$tot264 > 0]/dados$tot264[dados$tot264 > 0],3);
    dados$q264_594[dados$tot264 > 0] = round(dados$q264_594[dados$tot264 > 0]/dados$tot264[dados$tot264 > 0],3);
    dados$q264_891[dados$tot264 > 0] = round(dados$q264_891[dados$tot264 > 0]/dados$tot264[dados$tot264 > 0],3);
    dados$q264_1337[dados$tot264 > 0] = round(dados$q264_1337[dados$tot264 > 0]/dados$tot264[dados$tot264 > 0],3);
    dados$q264_2085[dados$tot264 > 0] = round(dados$q264_2085[dados$tot264 > 0]/dados$tot264[dados$tot264 > 0],3);
    dados$q264_3127[dados$tot264 > 0] = round(dados$q264_3127[dados$tot264 > 0]/dados$tot264[dados$tot264 > 0],3);
    dados$q396_264[dados$tot396 > 0] = round(dados$q396_264[dados$tot396 > 0]/dados$tot396[dados$tot396 > 0],3);
    dados$q396_396[dados$tot396 > 0] = round(dados$q396_396[dados$tot396 > 0]/dados$tot396[dados$tot396 > 0],3);
    dados$q396_594[dados$tot396 > 0] = round(dados$q396_594[dados$tot396 > 0]/dados$tot396[dados$tot396 > 0],3);
    dados$q396_891[dados$tot396 > 0] = round(dados$q396_891[dados$tot396 > 0]/dados$tot396[dados$tot396 > 0],3);
    dados$q396_1337[dados$tot396 > 0] = round(dados$q396_1337[dados$tot396 > 0]/dados$tot396[dados$tot396 > 0],3);
    dados$q396_2085[dados$tot396 > 0] = round(dados$q396_2085[dados$tot396 > 0]/dados$tot396[dados$tot396 > 0],3);
    dados$q396_3127[dados$tot396 > 0] = round(dados$q396_3127[dados$tot396 > 0]/dados$tot396[dados$tot396 > 0],3);
    dados$q594_264[dados$tot594 > 0] = round(dados$q594_264[dados$tot594 > 0]/dados$tot594[dados$tot594 > 0],3);
    dados$q594_396[dados$tot594 > 0] = round(dados$q594_396[dados$tot594 > 0]/dados$tot594[dados$tot594 > 0],3);
    dados$q594_594[dados$tot594 > 0] = round(dados$q594_594[dados$tot594 > 0]/dados$tot594[dados$tot594 > 0],3);
    dados$q594_891[dados$tot594 > 0] = round(dados$q594_891[dados$tot594 > 0]/dados$tot594[dados$tot594 > 0],3);
    dados$q594_1337[dados$tot594 > 0] = round(dados$q594_1337[dados$tot594 > 0]/dados$tot594[dados$tot594 > 0],3);
    dados$q594_2085[dados$tot594 > 0] = round(dados$q594_2085[dados$tot594 > 0]/dados$tot594[dados$tot594 > 0],3);
    dados$q594_3127[dados$tot594 > 0] = round(dados$q594_3127[dados$tot594 > 0]/dados$tot594[dados$tot594 > 0],3);
    dados$q891_264[dados$tot891 > 0] = round(dados$q891_264[dados$tot891 > 0]/dados$tot891[dados$tot891 > 0],3);
    dados$q891_396[dados$tot891 > 0] = round( dados$q891_396[dados$tot891 > 0]/dados$tot891[dados$tot891 > 0],3);
    dados$q891_594[dados$tot891 > 0] = round(dados$q891_594[dados$tot891 > 0]/dados$tot891[dados$tot891 > 0],3);
    dados$q891_891[dados$tot891 > 0] = round(dados$q891_891[dados$tot891 > 0]/dados$tot891[dados$tot891 > 0],3);
    dados$q891_1337[dados$tot891 > 0] = round(dados$q891_1337[dados$tot891 > 0]/dados$tot891[dados$tot891 > 0],3);
    dados$q891_2085[dados$tot891 > 0] = round(dados$q891_2085[dados$tot891 > 0]/dados$tot891[dados$tot891 > 0],3);
    dados$q891_3127[dados$tot891 > 0] = round(dados$q891_3127[dados$tot891 > 0]/dados$tot891[dados$tot891 > 0],3);
    dados$q1337_264[dados$tot1337 > 0] = round(dados$q1337_264[dados$tot1337 > 0]/dados$tot1337[dados$tot1337 > 0],3);
    dados$q1337_396[dados$tot1337 > 0] = round(dados$q1337_396[dados$tot1337 > 0]/dados$tot1337[dados$tot1337 > 0],3);
    dados$q1337_594[dados$tot1337 > 0] = round(dados$q1337_594[dados$tot1337 > 0]/dados$tot1337[dados$tot1337 > 0],3);
    dados$q1337_891[dados$tot1337 > 0] = round(dados$q1337_891[dados$tot1337 > 0]/dados$tot1337[dados$tot1337 > 0],3);
    dados$q1337_1337[dados$tot1337 > 0] = round(dados$q1337_1337[dados$tot1337 > 0]/dados$tot1337[dados$tot1337 > 0],3);
    dados$q1337_2085[dados$tot1337 > 0] = round(dados$q1337_2085[dados$tot1337 > 0]/dados$tot1337[dados$tot1337 > 0],3);
    dados$q1337_3127[dados$tot1337 > 0] = round( dados$q1337_3127[dados$tot1337 > 0]/dados$tot1337[dados$tot1337 > 0],3);
    dados$q2085_264[dados$tot2085 > 0] = round(dados$q2085_264[dados$tot2085 > 0]/dados$tot2085[dados$tot2085 > 0],3);
    dados$q2085_396[dados$tot2085 > 0] = round(dados$q2085_396[dados$tot2085 > 0]/dados$tot2085[dados$tot2085 > 0],3);
    dados$q2085_594[dados$tot2085 > 0] = round(dados$q2085_594[dados$tot2085 > 0]/dados$tot2085[dados$tot2085 > 0],3);
    dados$q2085_891[dados$tot2085 > 0] = round(dados$q2085_891[dados$tot2085 > 0]/dados$tot2085[dados$tot2085 > 0],3);
    dados$q2085_1337[dados$tot2085 > 0] = round(dados$q2085_1337[dados$tot2085 > 0]/dados$tot2085[dados$tot2085 > 0],3);
    dados$q2085_2085[dados$tot2085 > 0] = round(dados$q2085_2085[dados$tot2085 > 0]/dados$tot2085[dados$tot2085 > 0],3);
    dados$q2085_3127[dados$tot2085 > 0] = round(dados$q2085_3127[dados$tot2085 > 0]/dados$tot2085[dados$tot2085 > 0],3);
    dados$q3127_264[dados$tot3127 > 0] = round(dados$q3127_264[dados$tot3127 > 0]/dados$tot3127[dados$tot3127 > 0],3);
    dados$q3127_396[dados$tot3127 > 0] = round(dados$q3127_396[dados$tot3127 > 0]/dados$tot3127[dados$tot3127 > 0],3);
    dados$q3127_594[dados$tot3127 > 0] = round(dados$q3127_594[dados$tot3127 > 0]/dados$tot3127[dados$tot3127 > 0],3);
    dados$q3127_891[dados$tot3127 > 0] = round(dados$q3127_891[dados$tot3127 > 0]/dados$tot3127[dados$tot3127 > 0],3);
    dados$q3127_1337[dados$tot3127 > 0] = round(dados$q3127_1337[dados$tot3127 > 0]/dados$tot3127[dados$tot3127 > 0],3);
    dados$q3127_2085[dados$tot3127 > 0] = round(dados$q3127_2085[dados$tot3127 > 0]/dados$tot3127[dados$tot3127 > 0],3);
    dados$q3127_3127[dados$tot3127 > 0] = round(dados$q3127_3127[dados$tot3127 > 0]/dados$tot3127[dados$tot3127 > 0],3);
    dados$q264 = round(dados$q264/dados$segmentnumber,3);
    dados$q396 = round(dados$q396/dados$segmentnumber,3);
    dados$q594 = round(dados$q594/dados$segmentnumber,3);
    dados$q891 = round(dados$q891/dados$segmentnumber,3);
    dados$q1337 = round(dados$q1337/dados$segmentnumber,3);
    dados$q2085 = round(dados$q2085/dados$segmentnumber,3);
    dados$q3127 = round(dados$q3127/dados$segmentnumber,3);
    dados$avgBitrate = round(dados$avgBitrate/dados$segmentnumber);
    return(dados[,-c(80:86)]);
}
####################################################################################################
####################################################################################################
#rotina de troca de regime de adaptação. 
#essa função tem a finalidade de selecionar o conjunto de slices de substituição ao original
changeAllocation <- function(activeNextMinuteSessions){
    
    modifiedWindows = data.frame()
    
    #para todas as sessões preditas como ativas
    for(x in c(1:nrow(activeNextMinuteSessions))){
        
        #pega as janelas L com bitrate abaixo, mas mais da metade, e desse e mesmo device
        #tenho que pegar o bitrate real, porque senão vai cair indefinidamente
        realBitrate = currentData[currentData$sessionid == activeNextMinuteSessions[x,]$sessionid,]$estBand 
        
        candidateChains = chainList[avgbitrate < realBitrate[1] &
                                        #avgbitrate > (realBitrate[1]/1.5)  & 
                                        isDesktop == activeNextMinuteSessions[x,]$isDesktop,]
        
        #se for 264, então nao tem como reduzir mais
        if(nrow(candidateChains) > 0){
            #escolhe a cadeia que ira substituir a original, aleatoriamente
            set.seed(10)
            candidateChains =  candidateChains[sample(x = nrow(candidateChains), size = 1, replace = FALSE),];
            
            #verifica se essa cadeia tem similar nos dados (similaridade de até 95%) 
            #se tiver, a cadeia atual vai ser substituida, senão vai manter a atual
            chosenWindow = traceBasedValidation(activeNextMinuteSessions[x,], candidateChains[1], realBitrate[1])
            if(ncol(chosenWindow) > 1){
                modifiedWindows = rbindlist(list(modifiedWindows,chosenWindow), use.names = TRUE, fill = FALSE)
            }
        }
    }
    return(modifiedWindows)
}
####################################################################################################
#Esse conjunto de funções pega a cadeia substituta C e seleciona todas as similares S a C
#depois é sorteada uma de S e ela é atribuida ao slice original. Ou seja não é C que substituirá, mas sim uma de S
jshann <- function(p,q) sqrt(0.5 * sum(p * log2(p/(0.5 * (p + q))), na.rm = TRUE) + 0.5 * sum(q * log2(q/(0.5 * (p + q))), na.rm = TRUE))

traceBasedValidation <- function(originalSlice, candidChain, maxBitrate){
    
    #pega apenas janelas dos dados do mesmo tipo de dispositivo do slice original
    windowDataDvc = windowDataNorm[windowDataNorm$isDesktop == originalSlice$isDesktop & 
                                       windowDataNorm$os == originalSlice$os &
                                       windowDataNorm$avgBitrate <= maxBitrate,]
    
    #preparando as distribuições para calcular a distância
    p <- matrix (c(candidChain$q264, candidChain$q396, candidChain$q594, candidChain$q891, candidChain$q1337, candidChain$q2085, candidChain$q3127), ncol = 7, byrow = TRUE)
    q <- matrix(c(windowDataDvc$q264, windowDataDvc$q396, windowDataDvc$q594, windowDataDvc$q891, windowDataDvc$q1337, windowDataDvc$q2085, windowDataDvc$q3127), ncol = 7, byrow = FALSE)
    
    #Calcula a semelhança da janela candidata de referência e as janelas dos dados
    distancias = apply(q,1,FUN=jshann,'p' = p)
    
    #seleciona as janelas com proximidade acima de 95%
    windowDataTemp = cbind(windowDataDvc, "distancia" = distancias)
    windowDataTemp = windowDataTemp[windowDataTemp$distancia <= 0.05,]
    
    #4.0 faça votacao se os clientes do minuto n-1 vao ficar no minuto n+1
    if(nrow(windowDataTemp[windowDataTemp$next1minute == 0,]) > nrow(windowDataTemp[windowDataTemp$next1minute == 1,])){
        windowDataTemp = windowDataTemp[windowDataTemp$next1minute == 0,]
    }
    if(nrow(windowDataTemp[windowDataTemp$next1minute == 0,]) <= nrow(windowDataTemp[windowDataTemp$next1minute == 1,])){
        windowDataTemp = windowDataTemp[windowDataTemp$next1minute == 1,]
    }
    
    if(nrow(windowDataTemp) > 0){
        #seleciona as mais similares das candidatas
        windowDataTemp = windowDataTemp[windowDataTemp$distancia == min(windowDataTemp$distancia),]
        #pega uma sessao depois da votacao
        set.seed(10)
        selectedSessionRelative = windowDataTemp[sample(1:nrow(windowDataTemp), 1, replace=F),]
        selectedSessionId = selectedSessionRelative$sessionid
        selectedSliceId = selectedSessionRelative$slicenumber
        
        #a cadeia escolhida com o novo fluxo de adaptação, mas os dados contextuais originais
        chosenWindow = windowData[windowData$sessionid == selectedSessionId & windowData$slicenumber == selectedSliceId,]
        chosenWindow$distancia = selectedSessionRelative$distancia
        chosenWindow$sessionid = originalSlice$sessionid
        chosenWindow$slicenumber = originalSlice$slicenumber + 2
        chosenWindow$ip = originalSlice$ip                       
        chosenWindow$codedAgent = originalSlice$codedAgent
        chosenWindow$os = originalSlice$os
        chosenWindow$osversion = originalSlice$osversion
        chosenWindow$browser = originalSlice$browser
        chosenWindow$browserversion = originalSlice$browserversion
        chosenWindow$asnumber = originalSlice$asnumber
        chosenWindow$city = originalSlice$city
        chosenWindow$uf = originalSlice$uf
        chosenWindow$country = originalSlice$country
        chosenWindow$bcastminute = originalSlice$bcastminute + 2
        return(chosenWindow)
    }
    
    #se não achou ninguem, retorna NA
    return(data.frame("error" = 0))
}
####################################################################################################
####################################################################################################
####################################################################################################
####################################################################################################
####################################################################################################
for(minuto in c(4:297))
{
    print(paste("Minuto:", minuto))
    write.csv(paste0("current,",minuto), file = paste0(args[2], "/current_engagement_rand.txt"), row.names = FALSE)
    
    #pega minuto corrente e janela de 10 minutos ao redor
    print(paste("Dados originais para validação trace based"))
    con = dbConnect(m, dbname=paste0(args[2], "/dataset.db"))
    dbExecute(con, "PRAGMA synchronous = OFF")
    dbExecute(con, "PRAGMA count_changes = OFF;")
    dbExecute(con, "PRAGMA locking_mode = EXCLUSIVE;")
    rs=dbSendQuery(con, paste0("select * from slices where device in ('mobile', 'desktop', 'television') and bcastminute between ", minuto - 10, " and ", minuto - 1))
    windowData=fetch(rs,n=-1)
    dbClearResult(rs)
    dbDisconnect(con)
    
    #set.seed(10)
    #windowData =  windowData[sample(x = nrow(windowData), size = round(nrow(windowData)*0.5), replace = FALSE),];
    
    print(paste("Dados sinteticos para realocação"))
    con = dbConnect(m, dbname=paste0(args[2], "/bases_sinteticas/dataset_eng_rand.db"))
    dbExecute(con, "PRAGMA synchronous = OFF")
    dbExecute(con, "PRAGMA count_changes = OFF;")
    dbExecute(con, "PRAGMA locking_mode = EXCLUSIVE;")
    #4.0 pega no minuto atual as sessões do minuto anterior desde que elas estejam ativas ainda durante o minuto atual
    #rs=dbSendQuery(con, paste0("select * from slices where device in ('mobile', 'desktop', 'television') and bcastminute = ", minuto - 1 , " and next0minute = 1"))
    rs=dbSendQuery(con, paste0("select * from (select * from slices  where bcastminute = ",minuto,") curr inner join (select * from slices where bcastminute = ",minuto-1,") prev
                                on prev.sessionid = curr.sessionid where curr.device in ('mobile', 'desktop', 'television');"))
    currentData=fetch(rs,n=-1)
    dbClearResult(rs)
    dbDisconnect(con)
    currentData = currentData[, c(1:84)]
    
    #se existe alguna janela na consulta acima
    if(nrow(windowData) > 0)
    {
        #preprocessamento e normalização para virar instancias de previsão
        currentDataNorm = normalization(currentData)
        windowDataNorm = normalization(windowData)
        
        
        #cluster vazio. Não é usado no randomico
        currentDataNorm = cbind("cluster" = 0, currentDataNorm)
        
        #faz a previsão dos clientes correntes que ficarão ou não no proximo minuto. Retorna um coluna com as classes
        set.seed(10)
        currentDataNorm = cbind(currentDataNorm, "predicted" = sample(x = c(0,1), size = nrow(currentDataNorm), replace = TRUE)) 
        
        ### AGORA ESTOU INTERESSADO NOS CLIENTES QUE IRÃO ABANDONAR DAQUI A 1 MINUTO ### 
        activeProxMinuteSessions = currentDataNorm[currentDataNorm$predicted == 0,]
        print(paste0("Ausencia real: ", nrow(currentDataNorm[currentDataNorm$next1minute == 0,])))
        print(paste0("Presença real: ", nrow(currentDataNorm[currentDataNorm$next1minute == 1,])))
        print(paste0("Ausências corretas: ", nrow(merge(currentDataNorm[currentDataNorm$next1minute == 0,], currentDataNorm[currentDataNorm$predicted == 0,], by = "sessionid"))/nrow(currentDataNorm[currentDataNorm$next1minute == 0,])))
        print(paste0("Permanências corretas: ", nrow(merge(currentDataNorm[currentDataNorm$next1minute == 1,], currentDataNorm[currentDataNorm$predicted == 1,], by = "sessionid"))/nrow(currentDataNorm[currentDataNorm$next1minute == 1,])))
        
        #inicia a rotina de troca de regime de adaptação
        print("iniciando")
        chunks = split(activeProxMinuteSessions, (seq(nrow(activeProxMinuteSessions))-1) %/% (round(nrow(activeProxMinuteSessions)/4))) 
        cl <- parallel::makeForkCluster(4)
        doParallel::registerDoParallel(cl)
        newAllocated = foreach (x = 1:length(chunks), .combine = "rbind") %dopar% {changeAllocation(chunks[[x]])}
        parallel::stopCluster(cl)
        #newAllocated = changeAllocation(activeProxMinuteSessions)
        
        #### #ALGUMAS ESCOLHAS PRODUZIRÃO AUMENTO DE ENGAJAMENTO, OUTRAS NÃO ####
        if(nrow(newAllocated) > 0){
            
            #sessões cuja votação deu permanência
            #problema: muitas dessas sessões já iam permanecer de qualquer jeito. O engajamento delas deve ser mantido
            newAllocated.stay = newAllocated[newAllocated$next1minute == 1, -c("distancia")]
            
            #4.0 PRECISO SABER COMO AS SESSOES SERAO GRAVADAS DE VOLTA. 
            #SE O CLIENTE ABANDONOU NO MINUTO SEGUINTE OS SLICES SERAO CRIADOS
            #SE O CLIENTE PERMANECEU, ENTAO A JANELA TEM QUE SER ATUALIZADA
            #PROBLEMA: AS JANELAS A SEREM ATUALIZADAS PODEM NAO TER NUMERAÇÃO CONSECUTIVA
            #quais sessões das que foram previstas como ausentes e recuperadas, mas que na verdade não sao ausentes e nao precisavam ser recuperadas?
            newAllocated.existing = newAllocated[newAllocated$next1minute == 1, c("sessionid","bcastminute")]
            print(paste("Searching false recovered sessions"))
            con = dbConnect(m, dbname=paste0(args[2], "/dataset.db"))
            dbExecute(con, "PRAGMA synchronous = OFF")
            dbExecute(con, "PRAGMA count_changes = OFF;")
            dbExecute(con, "PRAGMA locking_mode = EXCLUSIVE;")
            rs=dbSendQuery(con, "select sessionid, slicenumber,bcastminute from slices where sessionid = :sessionid and bcastminute = :bcastminute limit 1", newAllocated.existing)
            sliceExisting=fetch(rs,n=-1)
            dbClearResult(rs)
            dbDisconnect(con)
            
            #4.0 para as sessoes recuperadas que na verdade nao precisava eu so preciso atualizar a adaptação, mas tenho que manter o next0minute e o next1minute intocados
            #tambem tenho que trocar o slicenumber e o bcastminute. Faço isso com um merge
            newAllocated.stay.meged = merge(x = sliceExisting[, -c(4)], y = newAllocated.stay, by = "sessionid", all.y = TRUE)
            
            #4.0 all.y Sessões que foram corretamente previstas como prestes a abandonar, vai ter NA nelas
            #cria novas janelas.
            newAllocated.stay.correct.prediction = newAllocated.stay.meged[is.na(newAllocated.stay.meged$slicenumber.x) & is.na(newAllocated.stay.meged$bcastminute.x),]
            
            #4.0 atualiza janelas existentes
            newAllocated.stay.wrong.prediction = newAllocated.stay.meged[!is.na(newAllocated.stay.meged$slicenumber.x) & !is.na(newAllocated.stay.meged$bcastminute.x),]
            
            #4.0 sessões que serão descartadas porque a votação determinou que a cadeia escolhida faz o cliente abandonar
            newAllocated.leave = newAllocated[newAllocated$next1minute == 0, c("sessionid", "slicenumber")]
            
            ### Qual a quantidade das sessões que iriam abandonar mas foram recuperadas? (previstas como 0 e geram novas janelas)
            logData = data.frame(
                nrow(currentDataNorm[currentDataNorm$next1minute == 0,]),
                nrow(currentDataNorm[currentDataNorm$next1minute == 1,]),
                nrow(merge(currentDataNorm[currentDataNorm$next1minute == 0,], currentDataNorm[currentDataNorm$predicted == 0,], by = "sessionid"))/nrow(currentDataNorm[currentDataNorm$next1minute == 0,]),
                nrow(merge(currentDataNorm[currentDataNorm$next1minute == 1,], currentDataNorm[currentDataNorm$predicted == 1,], by = "sessionid"))/nrow(currentDataNorm[currentDataNorm$next1minute == 1,]),
                nrow(newAllocated.leave))
            
            print(paste("sessoes perdidas:", logData[,5]))
    
            #4.0 cria novas janelas. next0minute e o next1minute vão estar inconsistentes NÃO USAR ESSES ATRIBUTOS PARA SELECIONAR JANELAS
            if(nrow(newAllocated.stay.correct.prediction) > 0){ 
                colnames(newAllocated.stay.correct.prediction)[4] <- "slicenumber"
                colnames(newAllocated.stay.correct.prediction)[17] <- "bcastminute"
                
                print("criando janelas recuperadas")
                con = dbConnect(m, dbname=paste0(args[2], "/bases_sinteticas/dataset_eng_rand.db"))
                dbExecute(con, "PRAGMA synchronous = OFF")
                dbExecute(con, "PRAGMA journal_mode = MEMORY;")
                dbExecute(con, "PRAGMA count_changes = OFF;")
                dbExecute(con, "PRAGMA locking_mode = EXCLUSIVE;")
                dbBegin(con)
                res <- dbSendQuery(con, "insert into slices values (:sessionid, :slicenumber, :segmentnumber, :ip, 
                :codedAgent, :device, :os, :osversion, :browser, :browserversion,
                :asnumber, :city, :uf, :country, :bcastminute, :adppos, :adpneg, :numStalls, :avgBitrate, :arrivAvg,      
                :q264, :q396, :q594, :q891, :q1337, :q2085, :q3127, :q264_264, :q264_396, :q264_594,      
                :q264_891, :q264_1337, :q264_2085, :q264_3127, :q396_264, :q396_396, :q396_594, :q396_891, :q396_1337, :q396_2085,     
                :q396_3127, :q594_264, :q594_396, :q594_594, :q594_891, :q594_1337, :q594_2085, :q594_3127, :q891_264, :q891_396,      
                :q891_594, :q891_891, :q891_1337, :q891_2085, :q891_3127, :q1337_264, :q1337_396, :q1337_594, :q1337_891, :q1337_1337,    
                :q1337_2085, :q1337_3127, :q2085_264, :q2085_396, :q2085_594, :q2085_891, :q2085_1337, :q2085_2085, :q2085_3127, :q3127_264,     
                :q3127_396, :q3127_594, :q3127_891, :q3127_1337, :q3127_2085, :q3127_3127, :next0minute, :next1minute, :next2minute, :next3minute, 
                :next4minute, :next5minute, :remEngagement, :estBand);", newAllocated.stay.correct.prediction[,-c(2,3)])
                dbClearResult(res)
                dbCommit(con)
                dbDisconnect(con)
            }
            
            if(nrow(newAllocated.stay.wrong.prediction) > 0){ 
                
                colnames(newAllocated.stay.wrong.prediction)[4] <- "slicenumber"
                colnames(newAllocated.stay.wrong.prediction)[17] <- "bcastminute"
                
                newAllocated.stay.wrong.prediction = newAllocated.stay.wrong.prediction[, c("sessionid", "slicenumber", "segmentnumber","adppos","adpneg","numStalls","avgBitrate",
                "q264","q396","q594","q891","q1337","q2085","q3127",
                "q264_264","q264_396","q264_594","q264_891","q264_1337","q264_2085","q264_3127","q396_264","q396_396","q396_594","q396_891","q396_1337","q396_2085","q396_3127",
                "q594_264","q594_396","q594_594","q594_891","q594_1337","q594_2085","q594_3127","q891_264","q891_396","q891_594","q891_891","q891_1337","q891_2085","q891_3127",
                "q1337_264","q1337_396","q1337_594","q1337_891","q1337_1337","q1337_2085","q1337_3127","q2085_264","q2085_396","q2085_594","q2085_891","q2085_1337","q2085_2085","q2085_3127",
                "q3127_264","q3127_396","q3127_594","q3127_891","q3127_1337","q3127_2085","q3127_3127","next0minute","next1minute","next2minute","next3minute","next4minute","next5minute",
                "remEngagement")]
                
                print("Atualizando janelas falsamente recuperadas")
                con = dbConnect(m, dbname=paste0(args[2], "/bases_sinteticas/dataset_eng_rand.db"))
                dbExecute(con, "PRAGMA synchronous = OFF")
                dbExecute(con, "PRAGMA journal_mode = MEMORY;")
                dbExecute(con, "PRAGMA count_changes = OFF;")
                dbExecute(con, "PRAGMA locking_mode = EXCLUSIVE;")
                dbBegin(con)
                res <- dbSendQuery(con, 'update slices 
            	set segmentnumber = :segmentnumber, adppos =:adppos, adpneg = :adpneg, numStalls = :numStalls, avgBitrate = :avgBitrate, 
            	q264 = :q264, q396 = :q396, q594 = :q594, q891 = :q891, q1337 = :q1337, q2085 = :q2085, q3127 = :q3127,
            	q264_264 = :q264_264, q264_396 = :q264_396, q264_594 = :q264_594, q264_891 = :q264_891, q264_1337 = :q264_1337, 
		        q264_2085 = :q264_2085, q264_3127 = :q264_3127,
            	q396_264 = :q396_264, q396_396 = :q396_396, q396_594 = :q396_594, q396_891 = :q396_891, q396_1337 = :q396_1337, 
		        q396_2085 = :q396_2085, q396_3127 = :q396_3127,
            	q594_264 = :q594_264, q594_396 = :q594_396, q594_594 = :q594_594, q594_891 = :q594_891, q594_1337 = :q594_1337, 
		        q594_2085 = :q594_2085, q594_3127 = :q594_3127,
            	q891_264 = :q891_264, q891_396 = :q891_396, q891_594 = :q891_594, q891_891 = :q891_891, q891_1337 = :q891_1337, 
		        q891_2085 = :q891_2085, q891_3127 = :q891_3127,
            	q1337_264 = :q1337_264, q1337_396 = :q1337_396, q1337_594 = :q1337_594, q1337_891 = :q1337_891, q1337_1337 = :q1337_1337, 
		        q1337_2085 = :q1337_2085, q1337_3127 = :q1337_3127,
            	q2085_264 = :q2085_264, q2085_396 = :q2085_396, q2085_594 = :q2085_594, q2085_891 = :q2085_891, q2085_1337 = :q2085_1337, 
		        q2085_2085 = :q2085_2085, q2085_3127 = :q2085_3127,
            	q3127_264 = :q3127_264, q3127_396 = :q3127_396, q3127_594 = :q3127_594, q3127_891 = :q3127_891, q3127_1337 = :q3127_1337, 
		        q3127_2085 = :q3127_2085, q3127_3127 = :q3127_3127,
            	next0minute = :next0minute, next1minute = :next1minute, next2minute = :next2minute, next3minute = :next3minute, 
		        next4minute = :next4minute, next5minute = :next5minute,remEngagement = :remEngagement 
            	where sessionid = :sessionid and slicenumber = :slicenumber', newAllocated.stay.wrong.prediction)
                dbClearResult(res)
                dbCommit(con)
                dbDisconnect(con)
            }
            
            if(nrow(newAllocated.leave) > 0){
                print("storing changes - delete")
                con = dbConnect(m, dbname=paste0(args[2], "/bases_sinteticas/dataset_eng_rand.db"))
                dbExecute(con, "PRAGMA synchronous = OFF")
                dbExecute(con, "PRAGMA journal_mode = MEMORY;")
                dbExecute(con, "PRAGMA count_changes = OFF;")
                dbExecute(con, "PRAGMA locking_mode = EXCLUSIVE;")
                dbBegin(con)
                res <- dbSendQuery(con, 'delete from slices where sessionid = :sessionid and slicenumber > :slicenumber', newAllocated.leave)
                dbClearResult(res)
                dbCommit(con)
                dbDisconnect(con)
            }
            remove(newAllocated,newAllocated.stay,newAllocated.existing, sliceExisting, newAllocated.stay.meged, newAllocated.stay.correct.prediction, newAllocated.stay.wrong.prediction, newAllocated.leave)
        }
        print("cleaning")
        remove(currentDataNorm,windowDataNorm,activeProxMinuteSessions)
        gc()
    }
    
    remove(windowData,currentData)
    gc()
}


