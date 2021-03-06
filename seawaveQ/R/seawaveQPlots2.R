#' Internal function that generates plots of data and model results.
#' 
#' seawaveQPlots2 is usually called from within \code{\link{fitMod}} but
#' can be invoked directly. It generates plots of data and model results, 
#' as well as diagnostic plots, and returns the observed and predicted 
#' concentrations so that users may plot the concentrations using 
#' their own functions. This is the version for models that use
#' restricted cubic splines.
#' @note The plotting position used for representing censored values in 
#' the plots produced by \code{\link{seawaveQPlots2}} is an important 
#' consideration for interpreting model fit. Plotting values obtained by 
#' using the censoring limit, or something smaller such as one-half of the 
#' censoring limit, produce plots that are difficult to interpret if there 
#' are a large number of censored values. Therefore, to make the plots 
#' more representative of diagnostic plots used for standard 
#' (non-censored) regression, a method for substituting randomized 
#' residuals in place of censored residuals was used. If a 
#' log-transformed concentration is censored at a particular limit, 
#' \code{logC < L}, then the residual for that concentration is censored 
#' as well, \code{logC - fitted(logC) < L - fitted(logC) = rescen}. In 
#' that case, a randomized residual was generated from a conditional 
#' normal distribution \cr \cr
#' \code{resran  <-  scl * qnorm(runif(1) * pnorm(rescen / scl))}, \cr \cr
#' where \code{scl} is the scale parameter from the survival regression model, 
#' \code{pnorm} is the R function for computing cumulative normal 
#' probabilities, \code{runif} is the R function for generating a 
#' random variable from the uniform distribution, and \code{qnorm} 
#' is the R function for computing quantiles of the normal distribution.  
#' Under the assumption that the model residuals are uncorrelated, 
#' normally distributed random variables with mean zero and standard 
#' deviation \code{scl}, the randomized residuals generated in this manner are an 
#' unbiased sample of the true (but unknown) residuals for the censored 
#' data. This is an application of the probability integral transform 
#' (Mood and others, 1974) to generate random variables from continuous 
#' distributions. The plotting position used for a censored concentration is 
#' \code{fitted(logC) + resran}. Note that each time a new model fit is 
#' performed, a new set of randomized residuals is generated and thus the 
#' plotting positions for censored values can change.
#' @param stpars A matrix of information about the best seawaveQ model
#' for the concentration data, see \code{\link{examplestpars}}.
#' @param cmaxt The decimal season of maximum chemical concentration.
#' @param tseas The decimal season of each concentration value in cdatsub.
#' @param tseaspr The decimal season date used to model concentration 
#' using the continuous data set cavdat.
#' @param tndrcs The decimal time centered on the midpoint of the trend
#' for the sample data, cdatasub, then converted to a linear tail-restricted 
#' cubic spline with a particular number of knots (Harrell, Jr., 2010 and 2018).
#' @param tndrcspr The decimal time centered on the midpoint of the 
#' trend for the continuous data, cavdat, then converted to a linear 
#' tail-restricted cubic spline using the knots from tndrcs.
#' @param cdatsub The concentration data.
#' @param cavdat The continuous (daily) ancillary data.
#' @param cavmat A matrix containing the continuous ancillary variables.
#' @param clog A vector of the base-10 logarithms of the concentration data.
#' @param centmp A logical vector indicating which concentration values are censored.
#' @param yrstart The starting year of the analysis (treated as January
#' 1 of that year).  
#' @param yrend The ending year of the analysis (treated as December 31
#' of that year).  
#' @param tyr A vector of decimal dates for the concentration data.
#' @param tyrpr A vector of decimal dates for the continuous ancillary
#' variables.
#' @param pnames The parameter (water-quality constituents) to 
#' analyze (if using USGS parameters, omit the the starting 'P', such as 
#' "00945" for sulfate).  
#' @param tanm A character identifier that names the trend 
#' analysis run. It is used to label output files.
#' @param mclass Indicates the class of model to use.
#' A class 1 model is the the traditional SEAWAVE-Q model that has a
#' linear time trend. A class 2 model is a newer option for longer
#' trend periods that uses a set of restricted cubic splines on the 
#' time variable to provide a more flexible model. 
#' @param numk The number of knots in the restricted cubic spline model.
#' The default is 4, and the recommended number is 3--7.
#' @keywords dplot hplot
#' @author Aldo V. Vecchia and Karen R. Ryberg
#' @return A pdf file containing plots of the data and modeled 
#' concentrations and regression diagnostic plots and a list containing
#' the observed concentrations (censored and uncensored) and the predicted
#' concentrations used for the plot.
#' @export
#' @references
#' Harrell, Jr., F.E., 2010, Regression Modeling Strategies---With
#' Applications to Linear Models, Logistic Regression, and Survival
#' Analysis: New York, Springer-Verlag, 568 p.
#' 
#' Harrell, Jr., F.E., 2018, rms---Regression modeling strategies: 
#' R package version 5.1-2, \url{https://CRAN.R-project.org/package=rms}.
#'
#' Mood, A.M., Graybill, F.A., and Boes, D.C., 1974, Introduction to the 
#' theory of statistics (3rd ed.): New York, McGraw-Hill, Inc., 564 p.
seawaveQPlots2 <- function(stpars, cmaxt, tseas, tseaspr, tndrcs, tndrcspr, 
                           cdatsub, cavdat, cavmat, clog, centmp, yrstart, 
                           yrend, tyr, tyrpr, pnames, tanm, mclass = 2, numk) {
  # produce plots for selected model
  # set up output file for graphs 
  # output graphs to a pdf
  graphfile <- paste(tanm, pnames, ".pdf", sep = "")
  gmes <- paste("Plots saved to ", graphfile, ".", sep = "")
  message(gmes)
  pdf(graphfile, height = 11, width = 8.5)
  par(mfrow = c(2, 1), omi = c(0.5, 0.5, 0.5, 0.2), mai = c(0.5, 
                                                            1, 0.5, 0.2))
  pckone <- stpars[1, 2]
  mod1 <- floor((pckone - 1)/4) + 1
  hlife1 <- pckone - (mod1 - 1) * 4
  ipkt <- floor(360 * tseas)
  ipkt[ipkt == 0] <- 1
  
  # call function to compute seasonal wave
  wavexx <- compwaveconv(cmaxt, mod1, hlife1)
  wavest <- wavexx[ipkt]
  intcpt <- rep(1, length(wavest))
  ipktpr <- floor(360 * tseaspr)
  ipktpr[ipktpr == 0] <- 1
  wavestpr <- wavexx[ipktpr]
  intcptpr <- rep(1, length(wavestpr))
 
  xmat <- cbind(intcpt, wavest, tndrcs)
  if (length(cdatsub[1, ]) > 6) {
    xmat <- cbind(xmat, cavmat)
    cavmatpr <- as.matrix(cavdat[, 5:length(cavdat[1, ])])
  }
  xmatpr <- cbind(intcptpr, wavestpr, tndrcspr)
  if (length(cdatsub[1, ]) > 6) {
    xmatpr <- cbind(xmatpr, cavmatpr)
  }
  
  # continous fitted concentrations
  partmp <- stpars[1, 5:(5 + length(xmat[1, ]) - 1)]
  fitadjx02 <- xmatpr %*% partmp
  
  # trend line
  rcscols <- grep("tndlinpr", dimnames(xmatpr)[[2]])
  partmprcscols <- partmp[rcscols]
  fitadjx12 <- as.matrix(rowSums(mapply("*", as.data.frame(xmatpr[, c(1, rcscols)]), 
                                        partmp[c(1, rcscols)])))
  # residuals
  cresx02 <- clog - xmat %*% partmp
  # discrete fitted data
  fitadjxdat <- xmat %*% partmp
  # standardized residuals
  scltmp2 <- stpars[1, 3]
  cresx02std <- (cresx02)/scltmp2
  ncenx <- sum(centmp)
  # replace censored residuals with 
  # conditional normal random variables
  cresx02std[centmp] <- qnorm(runif(ncenx) * pnorm(cresx02std[centmp]))
  cadjx0 <- clog
  
  # First plot, observed and predicted concentrations and trend
  ylow <- floor(min(c(cadjx0, fitadjx02, fitadjx12)) - 0.25)
  yup <- ceiling(max(c(cadjx0, fitadjx02, fitadjx12)) + 1)
  ytck <- 0.02 * (yup - ylow)
  xlow <- yrstart
  xup <- yrend
  xtck <- 0.012 * (xup - xlow)
  ytmp <- cadjx0
 
  # ts plot of data and model 
  sp95 <- 1.645 * scltmp2
  plot(c(tyr, tyrpr), c(ytmp, fitadjx02), type = "p", pch = "", 
       xaxs = "i", yaxs = "i", xaxt = "n", yaxt = "n", xlab = "", 
       ylab = "", xlim = c(xlow, xup), ylim = c(ylow, yup))
  points(tyr[centmp], ytmp[centmp], pch = 1, cex = 1, col = 2)
  points(tyr[!centmp], ytmp[!centmp], pch = 16, cex = 0.9, 
         col = 2)
  
  # plot discrete predictions for days with observations
  # points(tyr, fitadjxdat, pch = 16, cex = 1, col = "blue")
  
  lines(tyrpr, fitadjx02, col = 1, lwd = 1.5)
  lines(tyrpr, fitadjx12, lwd = 3, col = "black")
  for (j in seq(xlow, xup - 1, 1)) {
    mtext(side = 1, line = 0.5, at = (j + 0.5), cex = 0.75, 
          as.character(j))
    lines(c(j, j), c(ylow, ylow + ytck), lwd = 1)
    lines(c(j, j), c(yup, yup - ytck), lwd = 1)
  }
  for (j in seq(ylow, yup, 1)) {
    mtext(side = 2, line = 0.5, at = j, adj = 1, cex = 0.75, 
          las = 1, format(10^j, scientific = FALSE, big.mark = ","))
    lines(y = c(j, j), x = c(xlow, xlow + xtck), lwd = 1)
    lines(y = c(j, j), x = c(xup, xup - xtck), lwd = 1)
  }
  text(xlow + 0.5 * (xup - xlow), yup - 2.5 * ytck, adj = 0, 
       cex = 0.7, "Measured concentrations")
  points(xlow + 0.47 * (xup - xlow), yup - 2.5 * ytck, pch = 16, 
         cex = 0.8, col = 2)
  text(xlow + 0.5 * (xup - xlow), yup - 5 * ytck, adj = 0, 
       cex = 0.7, "Nondetections")
  points(xlow + 0.47 * (xup - xlow), yup - 5 * ytck, pch = 1, 
         cex = 0.8, col = 2)
  text(xlow + 0.5 * (xup - xlow), yup - 7.5 * ytck, adj = 0, 
       cex = 0.7, "Fitted concentrations (SWAVE-CAV)")
  lines(c(xlow + 0.45 * (xup - xlow), xlow + 0.49 * (xup - xlow)), 
        c(yup - 7.5 * ytck, yup - 7.5 * ytck), lwd = 1.5, 
        col = 1)
  text(xlow + 0.5 * (xup - xlow), yup - 10 * ytck, adj = 0, 
       cex = 0.65, "Trend")
  lines(c(xlow + 0.45 * (xup - xlow), xlow + 0.49 * (xup - 
                                                       xlow)), c(yup - 10 * ytck, yup - 10 * ytck), lwd = 3, 
        col = 1)
  mtext(pnames, side = 3, line = 0.5, adj = 0.1, cex = 1)
  mtext(tanm, side = 3, line = 0.5, adj = 0.5, cex = 1)
  mtext("Concentration, in micrograms per liter", side = 2, 
        outer = FALSE, line = 3, cex = 0.8)
  
  # Second plot, fitted 95th percentile and median concentrations
  ylow <- 0
  tmpmax <- ceiling(quantile(10^c(fitadjx02 + 1.96 * scltmp2), 
                             prob = 0.999) * 200)/200
  if (tmpmax <= 0.025) {
    yup <- tmpmax
  }
  if (tmpmax > 0.025 & tmpmax <= 0.05) {
    yup <- 0.05
  }
  if (tmpmax > 0.05 & tmpmax <= 0.1) {
    yup <- 0.1
  }
  if (tmpmax > 0.1 & tmpmax <= 0.15) {
    yup <- 0.15
  }
  if (tmpmax > 0.15 & tmpmax <= 0.2) {
    yup <- 0.2
  }
  if (tmpmax > 0.2 & tmpmax <= 0.25) {
    yup <- 0.25
  }
  if (tmpmax > 0.25 & tmpmax <= 0.5) {
    yup <- 0.5
  }
  if (tmpmax > 0.5 & tmpmax <= 1) {
    yup <- 1
  }
  if (tmpmax > 1 & tmpmax <= 1.5) {
    yup <- 1.5
  }
  if (tmpmax > 1.5 & tmpmax <= 2) {
    yup <- 2
  }
  if (tmpmax > 2 & tmpmax <= 2.5) {
    yup <- 2.5
  }
  if (tmpmax > 2.5 & tmpmax <= 5) {
    yup <- 5
  }
  if (tmpmax > 5) {
    yup <- ceiling(tmpmax / 5) * 5
  }
  ystp <- yup / 5
  ytck <- 0.02 * (yup - ylow)
  xlow <- yrstart
  xup <- yrend
  xtck <- 0.012 * (xup - xlow)
  ytmpxx <- 10^fitadjx02
  ytmpxx95 <- 10^(fitadjx02 + 1.96 * scltmp2)
  plot(c(tyrpr), c(ytmpxx), type = "p", pch = "", xaxs = "i", 
       yaxs = "i", xaxt = "n", yaxt = "n", xlab = "", ylab = "", 
       xlim = c(xlow, xup), ylim = c(ylow, yup))
  lines(tyrpr, ytmpxx, col = 1, lwd = 2)
  lines(tyrpr, ytmpxx95, col = 2, lwd = 2)
  for (j in seq(xlow, xup - 1, 1)) {
    mtext(side = 1, line = 0.5, at = (j + 0.5), cex = 0.75, 
          as.character(j))
    lines(c(j, j), c(ylow, ylow + ytck), lwd = 1)
    lines(c(j, j), c(yup, yup - ytck), lwd = 1)
  }
  for (j in seq(ylow, yup, ystp)) {
    mtext(side = 2, line = 0.5, at = j, adj = 1, cex = 0.75, 
          las = 1, format(j, scientific = FALSE, big.mark = ","))
    lines(y = c(j, j), x = c(xlow, xlow + xtck), lwd = 1)
    lines(y = c(j, j), x = c(xup, xup - xtck), lwd = 1)
  }
  text(xlow + 0.5 * (xup - xlow), yup - 3 * ytck, adj = 0, 
       cex = 0.8, "Fitted 95th percentile concentration")
  lines(c(xlow + 0.45 * (xup - xlow), xlow + 0.49 * 
            (xup - xlow)), c(yup - 3 * ytck, yup - 3 * ytck), lwd = 2, col = 2)
  text(xlow + 0.5 * (xup - xlow), yup - 6 * ytck, adj = 0, 
       cex = 0.8, "Fitted median concentration")
  lines(c(xlow + 0.45 * (xup - xlow), xlow + 0.49 * 
            (xup - xlow)), c(yup - 6 * ytck, yup - 6 * ytck), lwd = 2, col = 1)
  mtext(pnames, side = 3, line = 0.5, adj = 0.1, cex = 1)
  mtext(tanm, side = 3, line = 0.5, adj = 0.5, cex = 1)
  mtext("Concentration, in micrograms per liter", side = 2, 
        outer = FALSE, line = 3, cex = 0.8)
  
  # Third plot, fitted concentrations vs measured concentrations
  # replace censored values with 
  # conditional normal random variables
  cadjx0 <- clog
  cadjx0[centmp] <- fitadjxdat[centmp] + cresx02std[centmp] * 
    scltmp2
  ylow <- floor(min(c(cadjx0, fitadjxdat)) - 0.05)
  yup <- ceiling(max(c(cadjx0, fitadjxdat)) + 0.05)
  ytck <- 0.02 * (yup - ylow)
  xlow <- ylow
  xup <- yup
  xtck <- 0.5 * ytck
  plot(fitadjxdat, cadjx0, type = "p", pch = "", xlim = c(xlow, xup), 
       ylim = c(ylow, yup), xaxs = "i", yaxs = "i", xaxt = "n", 
       yaxt = "n", xlab = "", ylab = "")
  points(fitadjxdat[centmp], cadjx0[centmp], pch = 1, cex = 1, 
         col = 2)
  points(fitadjxdat[!centmp], cadjx0[!centmp], pch = 16, cex = 0.9, 
         col = 2)
  lines(c(xlow, xup), c(xlow, xup), col = 1, lwd = 2)
  for (j in seq(xlow, xup, 1)) {
    mtext(side = 1, line = 0.5, at = j, cex = 0.75, 
          format(10^j, scientific = FALSE, big.mark = ","))
    lines(c(j, j), c(ylow, ylow + ytck), lwd = 1)
    lines(c(j, j), c(yup, yup - ytck), lwd = 1)
  }
  for (j in seq(ylow, yup, 1)) {
    mtext(side = 2, line = 0.5, at = j, adj = 1, cex = 0.75, 
          las = 1, format(10^j, scientific = FALSE, big.mark = ","))
    lines(y = c(j, j), x = c(xlow, xlow + xtck), lwd = 1)
    lines(y = c(j, j), x = c(xup, xup - xtck), lwd = 1)
  }
  mtext(side = 3, line = 0.5, adj = 0.1, cex = 1, pnames)
  mtext(side = 3, line = 0.5, adj = 0.5, cex = 1, tanm)
  mtext("Fitted Concentration, in micrograms per liter", side = 1, 
        outer = FALSE, line = 1.5, cex = 0.8)
  mtext("Measured Concentration, in micrograms per liter\n(censored data randomized)", 
        side = 2, outer = FALSE, line = 3.5, cex = 0.8)
  
  # Fourth plot
  xlow0 <- xlow
  xup0 <- xup
  ylow <- floor(min(c(cresx02std)) - 0.25)
  yup <- ceiling(max(c(cresx02std)) + 0.25)
  ytck <- 0.02 * (yup - ylow)
  for (rplt in 1:3) {
    #  residuals versus fitted
    ytmpsr <- cresx02std
    if (rplt == 1) {
      xlow <- xlow0
      xup <- xup0
      xstp <- 1
      xtck <- 0.012 * (xup - xlow)
    }
    #  residuals versus time
    if (rplt == 2) {
      xlow <- yrstart
      xup <- yrend
      xstp <- 1
      xtck <- 0.012 * (xup - xlow)
    }
    if (rplt == 3) {
      xlow <- 0
      xup <- 12
      xstp <- 1
      xtck <- 0.012 * (xup - xlow)
    }
    plot(tyr, ytmpsr, pch = "", xaxs = "i", yaxs = "i", xaxt = "n", 
         yaxt = "n", xlab = "", ylab = "", xlim = c(xlow, 
                                                    xup), ylim = c(ylow, yup))
    lines(c(xlow, xup), c(0, 0), col = 1, lwd = 2)
    if (rplt == 1) {
      points(fitadjxdat[centmp], ytmpsr[centmp], pch = 1, 
             cex = 1, col = 2)
      points(fitadjxdat[!centmp], ytmpsr[!centmp], pch = 16, 
             cex = 0.9, col = 2)
    }
    if (rplt == 2) {
      points(tyr[centmp], ytmpsr[centmp], pch = 1, cex = 1, 
             col = 2)
      points(tyr[!centmp], ytmpsr[!centmp], pch = 16, cex = 0.9, 
             col = 2)
    }
    if (rplt == 3) {
      points(tseas[centmp] * 12, ytmpsr[centmp], pch = 1, 
             cex = 1, col = 2)
      points(tseas[!centmp] * 12, ytmpsr[!centmp], pch = 16, 
             cex = 0.9, col = 2)
    }
    for (j in seq(xlow, xup, xstp)) {
      if (rplt == 1) {
        mtext(side = 1, line = 0.5, at = j, cex = 0.75, 
              format(10^j, scientific = FALSE, big.mark = ","))
      }
      if (rplt == 2 & j < xup) {
        mtext(side = 1, line = 0.5, at = j + 0.5, cex = 0.75, 
              as.character(j))
      }
      lines(c(j, j), c(ylow, ylow + ytck), lwd = 1)
      lines(c(j, j), c(yup, yup - ytck), lwd = 1)
    }
    if (rplt == 3) {
      mtext(c("Jan", "Feb", "Mar", "Apr", "May", "June", 
              "July", "Aug", "Sept", "Oct", "Nov", "Dec"), 
            side = 1, line = 0.5, at = seq(0.5, 11.5, 1), 
            cex = 0.75)
    }
    for (j in seq(ylow, yup, 1)) {
      mtext(as.character(j), side = 2, line = 0.5, at = j, 
            adj = 1, las = 1, cex = 0.75)
      lines(y = c(j, j), x = c(xlow, xlow + xtck), lwd = 1)
      lines(y = c(j, j), x = c(xup, xup - xtck), lwd = 1)
    }
    mtext("Standardized residual\n(censored residuals randomized)", 
          side = 2, outer = FALSE, line = 3, cex = 0.8)
    mtext(pnames, side = 3, line = 0.5, adj = 0.1, cex = 1)
    mtext(tanm, side = 3, line = 0.5, adj = 0.5, cex = 1)
    if (rplt == 1) {
      mtext("Fitted Concentration, in micrograms per liter", 
            side = 1, line = 1.5, cex = 0.8)
    }
  }
  dev.off()
  dectime = NULL
  if (sum(centmp) > 0) {
    censDat <- data.frame(cbind(dectime = tyr[centmp], rmk = "<", 
                                val = 10^ytmp[centmp]), 
                          stringsAsFactors = FALSE)
    censDat$dectime <- as.numeric(censDat$dectime)
    censDat$val <- as.numeric(censDat$val)
    dimnames(censDat)[[2]][2] <- paste("R", pnames, sep = "")
    dimnames(censDat)[[2]][3] <- paste("P", pnames, sep = "")
  }
  uncensDat <- data.frame(cbind(dectime = tyr[!centmp], rmk = "", 
                                val = 10^ytmp[!centmp]), 
                          stringsAsFactors = FALSE)
  uncensDat$dectime <- as.numeric(uncensDat$dectime)
  uncensDat$val <- as.numeric(uncensDat$val)
  dimnames(uncensDat)[[2]][2] <- paste("R", pnames, sep = "")
  dimnames(uncensDat)[[2]][3] <- paste("P", pnames, sep = "")
  if (sum(centmp) > 0) {
    obsDat <- merge(censDat, uncensDat, all = TRUE)
    obsDat <- subset(obsDat, dectime <= yrend & dectime >= 
                       yrstart)
  }
  else {
    obsDat <- uncensDat
    obsDat <- subset(obsDat, dectime <= yrend & dectime >= 
                       yrstart)
  }
  obsDat$dectime <- round(obsDat$dectime, digits = 3)
  predDat <- data.frame(cbind(dectime = tyrpr, pred = ytmpxx))
  dimnames(predDat)[[2]][2] <- paste0("P", pnames)
  predDat <- subset(predDat, dectime <= yrend & dectime >= 
                      yrstart)
  predDat$dectime <- round(predDat$dectime, digits = 3)
  trendLine <- data.frame(trendLine = 10 ^ (fitadjx12))
  dimnames(trendLine)[[2]][1] <- paste0("P", pnames, "TL")
  plotDat <- list(obsDat, predDat, trendLine)
  plotDat
}
