library(shiny)
library(lpSolve)
library(quadprog)
library(ggplot2)
library(reshape2)

library(plotly)

#Annualized asset class returns, 2004-2015; See README
Intl_EmerMkts <- c(0.2595, 0.3454, 0.3255, 0.3982, -0.5318, 0.7902, 0.1920, -0.1817, 0.1863, -0.0227, -0.0182, -0.1522)
Intl_NorAmer_ex_US <- c(0.2278, 0.2886, 0.1835, 0.3024, -0.4515, 0.5736, 0.2121, -0.1216, 0.0990, 0.0644, 0.0222, -0.1964)
US_Small <- c(0.2265, 0.0768, 0.1512, -0.0030, -0.3107, 0.2557, 0.2631, 0.0102, 0.1633, 0.4131, 0.0576, -0.0549)
Intl_Europe_plus_Israel <- c(0.2159, 0.1084, 0.3405, 0.1532, -0.4716, 0.3869, 0.0508, -0.1141, 0.1995, 0.2430, -0.0659, -0.0486)
Intl_Pacific <- c(0.1930, 0.2301, 0.1251, 0.0561, -0.3617, 0.2424, 0.1608, -0.1361, 0.1460, 0.1843, -0.0247, -0.0534)
FI_Corp_Cred <- c(0.0524, 0.0196, 0.0426, 0.0511, -0.0308, 0.1604, 0.0847, 0.0835, 0.0937, -0.0201, 0.0753, -0.0026)
FI_Securitized <- c(0.0459, 0.0253, 0.0515, 0.0664, 0.0464, 0.0778, 0.0652, 0.0622, 0.0301, -0.0131, 0.0588, 0.0166)
FI_Treasury <- c(0.0354, 0.0279, 0.0308, 0.0901, 0.1374, -0.0357, 0.0587, 0.0981, 0.0199, -0.0275, 0.0505, 0.0180)
US_LargeCap <- c(0.1092, 0.0491, 0.1591, 0.0556, -0.3707, 0.2638, 0.1508, 0.0209, 0.1615, 0.3237, 0.1363, -0.0542)
US_MidCap <- c(0.1647, 0.1253, 0.1022, 0.0808, -0.3624, 0.3741, 0.2668, -0.0169, 0.1790, 0.3351, 0.0984, -0.0477)

returns <- data.frame(Intl_EmerMkts, Intl_NorAmer_ex_US, US_Small, Intl_Europe_plus_Israel, Intl_Pacific,
                      FI_Corp_Cred, FI_Securitized, FI_Treasury, US_LargeCap, US_MidCap)

#delete individual class vectors, which are no longer needed
rm(Intl_EmerMkts, Intl_NorAmer_ex_US, US_Small, Intl_Europe_plus_Israel, Intl_Pacific,
   FI_Corp_Cred, FI_Securitized, FI_Treasury, US_LargeCap, US_MidCap)

#compute standard deviation, then express in percentage terms
returnSD <- apply(returns, 2, sd)
returnSDPCT <- returnSD * 100

nObs <- nrow(returns)
nAssets <- length(returns)

opt.constraints <- matrix(c(1,1,1,1,1,1,1,1,1,1,  #constrain sum of weights to 1
                            1,0,0,0,0,0,0,0,0,0,  #constrain w1
                            0,1,0,0,0,0,0,0,0,0,  #constrain w2
                            0,0,1,0,0,0,0,0,0,0,  #constrain w3
                            0,0,0,1,0,0,0,0,0,0,  #constrain w4
                            0,0,0,0,1,0,0,0,0,0,  #constrain w5
                            0,0,0,0,0,1,0,0,0,0,  #constrain w6
                            0,0,0,0,0,0,1,0,0,0,  #constrain w7
                            0,0,0,0,0,0,0,1,0,0,  #constrain w8
                            0,0,0,0,0,0,0,0,1,0,  #constrain w9
                            0,0,0,0,0,0,0,0,0,1), #constrain w10
                          nrow = 11, byrow=TRUE)

#because our concentration constraint involves setting a minimum % weight for each asset
#class, we use the ">=" operator for values 2-n; alternatively, if you want to rewrite the app
#so that this constraint is a MAX amount for each class, replace ">=" with "<="
opt.operator <- c("=", ">=", ">=", ">=", ">=", ">=", ">=", ">=", ">=", ">=", ">=")

#other global arguments for linear and/or quadratic programming
opt.rhs2 <- c(1, 0.000001, 0.000001, 0.000001, 0.000001, 0.000001,
              0.000001, 0.000001, 0.000001, 0.000001, 0.000001)
opt.meq <- 1

# define colors by hexidecimal color codes, which are used in transition map graph
dvred <- "#e41a1c";    dvorange <- "#ff7f00"; dvyellow <- "#ffff33";  dvgreen <- "#4daf4a";
dvblue <- "#000099";   dvpurple <- "#984ea3"; dvgray <- "#666666";    dvlightgrn <- "#a0db8e";  
dvpink <- "#ffb6c1";   dvteal <- "#00ced1"

#labels for transition map graph
keep <- c("Risk", "%Emerging Markets", "%Canada", "%US Small Cap","%Developed Europe",
          "%Pacific","%Corporate Bonds", "%Asset-backed Securities","%Treasury Bonds",
          "%US Large Cap", "%US Mid Cap")



shinyServer(function(input, output, session) {
  observeEvent(input$goButton, {

  #DEFINE USER-INPUTTED VARIABLES
  
  ExpReturnsPCT <- reactive({
    c(input$ER_IntlEmerging, input$ER_IntlNorAm, input$ER_USSmall, input$ER_IntlEurope, 
      input$ER_Pacific, input$ER_FixedCorporate, input$ER_FixedSectized, 
      input$ER_FixedTrsy, input$ER_USLarge, input$ER_USMidCap)
    })
  ExpReturns <- reactive({ExpReturnsPCT()/100})    #converted to numeric form
  min_allocPCT <- reactive({input$min_allocPCT})
  min_alloc <- reactive({min_allocPCT()/100})      #converted to numeric form
  
  
  
  #FIND CONSTRAINED MAX RETURN PORTFOLIO USING LINEAR PROGRAMMING
  
  #objects used for linear program inputs (opt.constraints & opt.operator defined above 
  #shinyServer function)
  opt.objective <- isolate({ExpReturns()})
  opt.rhs <- isolate({c(1, rep(min_alloc(), nAssets))})

  solution.maxret <- lp(direction = "max",
                        opt.objective,
                        opt.constraints,
                        opt.operator,
                        opt.rhs)
  
  wts.maxret <- solution.maxret$solution   #portfolio weights for max port returns
  ret.maxret <- solution.maxret$objval     #return for max portfolio
  covmatrix <- cov(returns,                #covariance matrix used to determine port vol
                   use="complete.obs",
                   method="pearson")
  var.maxret <- wts.maxret %*%             #multiply w*cov*w, giving variance
                covmatrix %*%
                wts.maxret
  vol.maxret <- sqrt(var.maxret)           #calculates standard deviation
  
  test <- ret.maxret + min_alloc()         #delete in final draft
  
  
  
  #FIND CONSTRAINED MINIMUM-VOLATILITY PORTFOLIO USING QUADRATIC PROGRAMMING
  
  #objects used for quad prog inputs (opt.rhs2, opt.meq defined above 
  #shinyServer function)
  
  zeros <- array(0, dim=c(nAssets,1))
  
  solution.minvol <- solve.QP(covmatrix,                                                     #Dmat
                              zeros,                                                         #dvec
                              cbind(t(opt.constraints), diag(nrow(covmatrix))),              #Amat
                              isolate({c(opt.rhs2, rep(min_alloc(), nrow(covmatrix)))}),     #bvec
                              meq=opt.meq)                                                   #meq
  
  wts.minvol <- solution.minvol$solution
  var.minvol <- solution.minvol$value * 2
  ret.minvol <- isolate({ExpReturns()}) %*% wts.minvol
  vol.minvol <- sqrt(var.minvol)
  
  
  #FILL IN THE POINTS ON THE EFFICIENT FRONTIER
  
  #generate a sequence of 50 evenly-spaced returns between min var and max returns
  lowreturn <- ret.minvol
  highreturn <- ret.maxret
  minreturns <- seq(lowreturn, highreturn, length.out = 50)
  
  #add a return constraint: sum of weight * return >= x
  retconst <- rbind(opt.constraints, ExpReturns())
  retrhs <- c(opt.rhs, ret.minvol[1])
  
  #create return, vols and weight vectors along the frontier, beginning w/ min vol portfolio
  out.ret <- c(ret.minvol)
  out.vol <- c(vol.minvol)
  
  out.ER_IntlEmerging <- c(wts.minvol[1])
  out.ER_IntlNorAm <- c(wts.minvol[2])
  out.ER_USSmall <- c(wts.minvol[3])
  out.ER_IntlEurope <- c(wts.minvol[4])
  out.ER_Pacific <- c(wts.minvol[5])
  out.ER_FixedCorporate <- c(wts.minvol[6])
  out.ER_FixedSectized <- c(wts.minvol[7])
  out.ER_FixedTrsy <- c(wts.minvol[8])
  out.ER_USLarge <- c(wts.minvol[9])
  out.ER_USMidCap <- c(wts.minvol[10])
  
  #loop and run a min vol optimization for each return level from 2-49
  for(i in 2:(length(minreturns)-1)) {
    print(i)
    tmp.constraints <- retconst
    tmp.rhs <- retrhs
    tmp.rhs[12] <- minreturns[i]         #set return constraint
    
    tmpsol <- solve.QP(covmatrix, 
                       zeros, 
                       cbind(t(tmp.constraints), diag(nrow(covmatrix))),
                       c(tmp.rhs, rep(min_alloc(),nrow(covmatrix))),
                       meq <- opt.meq)
    
    tmp.wts <- tmpsol$solution
    tmp.var <- tmpsol$value * 2
    out.ret[i] <- ExpReturns() %*% tmp.wts
    out.vol[i] <- sqrt(tmp.var)
    out.ER_IntlEmerging[i] <- tmp.wts[1]
    out.ER_IntlNorAm[i] <- tmp.wts[2]
    out.ER_USSmall[i] <- tmp.wts[3] 
    out.ER_IntlEurope[i] <- tmp.wts[4]
    out.ER_Pacific[i] <- tmp.wts[5]
    out.ER_FixedCorporate[i] <- tmp.wts[6]
    out.ER_FixedSectized[i] <- tmp.wts[7]
    out.ER_FixedTrsy[i] <- tmp.wts[8]
    out.ER_USLarge[i] <- tmp.wts[9]
    out.ER_USMidCap[i] <- tmp.wts[10]
  }
  
  #put maxreturn portfolio in return series for max return, index=50
  out.ret[50] <- c(ret.maxret)
  out.vol[50] <- c(vol.maxret)
  
  out.ER_IntlEmerging[50] <- c(wts.maxret[1])
  out.ER_IntlNorAm[50] <- c(wts.maxret[2])
  out.ER_USSmall[50] <- c(wts.maxret[3])
  out.ER_IntlEurope[50] <- c(wts.maxret[4])
  out.ER_Pacific[50] <- c(wts.maxret[5])
  out.ER_FixedCorporate[50] <- c(wts.maxret[6])
  out.ER_FixedSectized[50] <- c(wts.maxret[7])
  out.ER_FixedTrsy[50] <- c(wts.maxret[8])
  out.ER_USLarge[50] <- c(wts.maxret[9])
  out.ER_USMidCap[50] <- c(wts.maxret[10])
  
  efrontier <- data.frame(out.ret*100)
  efrontier$vol <- out.vol*100
  
  efrontier$ER_IntlEmerging <- out.ER_IntlEmerging*100
  efrontier$ER_IntlNorAm <- out.ER_IntlNorAm*100
  efrontier$ER_USSmall <- out.ER_USSmall*100
  efrontier$ER_IntlEurope <- out.ER_IntlEurope*100
  efrontier$ER_Pacific <- out.ER_Pacific*100
  efrontier$ER_FixedCorporate <- out.ER_FixedCorporate*100
  efrontier$ER_FixedSectized <- out.ER_FixedSectized*100
  efrontier$ER_FixedTrsy <- out.ER_FixedTrsy*100
  efrontier$ER_USLarge <- out.ER_USLarge*100
  efrontier$ER_USMidCap <- out.ER_USMidCap*100
  
  names(efrontier) <- c("Return", "Risk", "%Emerging Markets", "%Canada", "%US Small Cap",
                        "%Developed Europe", "%Pacific", "%Corporate Bonds",
                        "%Asset-backed Securities", "%Treasury Bonds", "%US Large Cap", 
                        "%US Mid Cap")
  
  efrontier.tmp <- efrontier[keep]
  efrontier.m <- melt(efrontier.tmp, id='Risk')
  
  
  #EFFICIENT FRONTIER PLOT
  apoints <- data.frame(returnSDPCT)
  apoints$returns <- ExpReturnsPCT()
  
  graphEF <- ggplot(data=efrontier, aes(x=Risk, y=Return)) +
    labs(title="Efficient Frontier") +
    theme(plot.title = element_text(hjust = 0.5)) +
    geom_line(size=1.4) +
    geom_point(data=apoints, aes(x=apoints$returnSDPCT, y=apoints$returns)) +
    #scale_x_continuous(limits=c(1,24)) +
    annotate("text", apoints[1,1], apoints[1,2],label=" Emerging \n Markets", hjust=1) +
    annotate("text", apoints[2,1], apoints[2,2],label=" Canada", hjust=0) +
    annotate("text", apoints[3,1], apoints[3,2],label=" US Small Cap", hjust=0) +
    annotate("text", apoints[4,1], apoints[4,2],label=" Developed Europe", hjust=0) +
    annotate("text", apoints[5,1], apoints[5,2],label=" Pacific", hjust=0) +
    annotate("text", apoints[6,1], apoints[6,2],label=" Corporate Bonds", hjust=0) +
    annotate("text", apoints[7,1], apoints[7,2],label=" Asset-backed \n Securities", hjust=0) +
    annotate("text", apoints[8,1], apoints[8,2],label=" Treasury Bonds", hjust=0) +
    annotate("text", apoints[9,1], apoints[9,2],label=" US Large Cap", hjust=0) +
    annotate("text", apoints[10,1], apoints[10,2],label=" US Mid Cap", hjust=0)
    #annotate("text", 19,0.3,label="Insp. Butters", hjust=0, alpha=0.5)
  
  
  #EFFICIENT FRONTIER PLOT
  graphTM <- ggplot(data=efrontier.m, aes(x=Risk, y=value, colour=variable, fill=variable)) +
    theme_bw() +
    theme(legend.position="bottom") +
    #labs(title="Transition Map") +
    theme(plot.title = element_text(hjust = 0.5)) +
    ylab('% Portfolio') +
    geom_area() +
    scale_colour_manual("", breaks=c("%Emerging Markets", "%Canada", "%US Small Cap",
                                     "%Developed Europe", "%Pacific","%Corporate Bonds", 
                                     "%Asset-backed Securities","%Treasury Bonds",
                                     "%US Large Cap", "%US Mid Cap"), 
                        values = c(dvred,dvorange,dvyellow,dvgreen,dvblue,dvpurple,
                                   dvgray,dvlightgrn,dvpink,dvteal), 
                        labels=c('%Emerging Markets', '%Canada', '%US Small Cap',
                                 '%Developed Europe', '%Pacific','%Corporate Bonds', 
                                 '%Asset-backed Securities','%Treasury Bonds',
                                 '%US Large Cap', '%US Mid Cap')) +
    scale_fill_manual("", breaks=c("%Emerging Markets", "%Canada", "%US Small Cap",
                                   "%Developed Europe", "%Pacific","%Corporate Bonds", 
                                   "%Asset-backed Securities","%Treasury Bonds",
                                   "%US Large Cap", "%US Mid Cap"), 
                      values = c(dvred,dvorange,dvyellow,dvgreen,dvblue,dvpurple,
                                 dvgray,dvlightgrn,dvpink,dvteal), 
                      labels=c('%Emerging Markets', '%Canada', '%US Small Cap',
                               '%Developed Europe', '%Pacific','%Corporate Bonds', 
                               '%Asset-backed Securities','%Treasury Bonds',
                               '%US Large Cap', '%US Mid Cap'))
    #annotate("text", 16,-2.5,label="Insp. Butters", hjust=0, alpha=0.5)
  
  
  output$graphEF <- renderPlot({graphEF})
  output$graphTM <- renderPlotly({graphTM})
  #output$graphTM <- renderPlot({graphTM})
  

    })
  })