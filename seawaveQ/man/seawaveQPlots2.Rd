% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/seawaveQPlots2.R
\name{seawaveQPlots2}
\alias{seawaveQPlots2}
\title{Internal function that generates plots of data and model results.}
\usage{
seawaveQPlots2(stpars, cmaxt, tseas, tseaspr, tndrcs, tndrcspr, cdatsub,
  cavdat, cavmat, clog, centmp, yrstart, yrend, tyr, tyrpr, pnames, tanm,
  mclass = 2, numk)
}
\arguments{
\item{stpars}{A matrix of information about the best seawaveQ model
for the concentration data, see \code{\link{examplestpars}}.}

\item{cmaxt}{The decimal season of maximum chemical concentration.}

\item{tseas}{The decimal season of each concentration value in cdatsub.}

\item{tseaspr}{The decimal season date used to model concentration 
using the continuous data set cavdat.}

\item{tndrcs}{The decimal time centered on the midpoint of the trend
for the sample data, cdatasub, then converted to a linear tail-restricted 
cubic spline with a particular number of knots (Harrell, Jr., 2010 and 2018).}

\item{tndrcspr}{The decimal time centered on the midpoint of the 
trend for the continuous data, cavdat, then converted to a linear 
tail-restricted cubic spline using the knots from tndrcs.}

\item{cdatsub}{The concentration data.}

\item{cavdat}{The continuous (daily) ancillary data.}

\item{cavmat}{A matrix containing the continuous ancillary variables.}

\item{clog}{A vector of the base-10 logarithms of the concentration data.}

\item{centmp}{A logical vector indicating which concentration values are censored.}

\item{yrstart}{The starting year of the analysis (treated as January
1 of that year).}

\item{yrend}{The ending year of the analysis (treated as December 31
of that year).}

\item{tyr}{A vector of decimal dates for the concentration data.}

\item{tyrpr}{A vector of decimal dates for the continuous ancillary
variables.}

\item{pnames}{The parameter (water-quality constituents) to 
analyze (if using USGS parameters, omit the the starting 'P', such as 
"00945" for sulfate).}

\item{tanm}{A character identifier that names the trend 
analysis run. It is used to label output files.}

\item{mclass}{Indicates the class of model to use.
A class 1 model is the the traditional SEAWAVE-Q model that has a
linear time trend. A class 2 model is a newer option for longer
trend periods that uses a set of restricted cubic splines on the 
time variable to provide a more flexible model.}

\item{numk}{The number of knots in the restricted cubic spline model.
The default is 4, and the recommended number is 3--7.}
}
\value{
A pdf file containing plots of the data and modeled 
concentrations and regression diagnostic plots and a list containing
the observed concentrations (censored and uncensored) and the predicted
concentrations used for the plot.
}
\description{
seawaveQPlots2 is usually called from within \code{\link{fitMod}} but
can be invoked directly. It generates plots of data and model results, 
as well as diagnostic plots, and returns the observed and predicted 
concentrations so that users may plot the concentrations using 
their own functions. This is the version for models that use
restricted cubic splines.
}
\note{
The plotting position used for representing censored values in 
the plots produced by \code{\link{seawaveQPlots2}} is an important 
consideration for interpreting model fit. Plotting values obtained by 
using the censoring limit, or something smaller such as one-half of the 
censoring limit, produce plots that are difficult to interpret if there 
are a large number of censored values. Therefore, to make the plots 
more representative of diagnostic plots used for standard 
(non-censored) regression, a method for substituting randomized 
residuals in place of censored residuals was used. If a 
log-transformed concentration is censored at a particular limit, 
\code{logC < L}, then the residual for that concentration is censored 
as well, \code{logC - fitted(logC) < L - fitted(logC) = rescen}. In 
that case, a randomized residual was generated from a conditional 
normal distribution \cr \cr
\code{resran  <-  scl * qnorm(runif(1) * pnorm(rescen / scl))}, \cr \cr
where \code{scl} is the scale parameter from the survival regression model, 
\code{pnorm} is the R function for computing cumulative normal 
probabilities, \code{runif} is the R function for generating a 
random variable from the uniform distribution, and \code{qnorm} 
is the R function for computing quantiles of the normal distribution.  
Under the assumption that the model residuals are uncorrelated, 
normally distributed random variables with mean zero and standard 
deviation \code{scl}, the randomized residuals generated in this manner are an 
unbiased sample of the true (but unknown) residuals for the censored 
data. This is an application of the probability integral transform 
(Mood and others, 1974) to generate random variables from continuous 
distributions. The plotting position used for a censored concentration is 
\code{fitted(logC) + resran}. Note that each time a new model fit is 
performed, a new set of randomized residuals is generated and thus the 
plotting positions for censored values can change.
}
\references{
Harrell, Jr., F.E., 2010, Regression Modeling Strategies---With
Applications to Linear Models, Logistic Regression, and Survival
Analysis: New York, Springer-Verlag, 568 p.

Harrell, Jr., F.E., 2018, rms---Regression modeling strategies: 
R package version 5.1-2, \url{https://CRAN.R-project.org/package=rms}.

Mood, A.M., Graybill, F.A., and Boes, D.C., 1974, Introduction to the 
theory of statistics (3rd ed.): New York, McGraw-Hill, Inc., 564 p.
}
\author{
Aldo V. Vecchia and Karen R. Ryberg
}
\keyword{dplot}
\keyword{hplot}
