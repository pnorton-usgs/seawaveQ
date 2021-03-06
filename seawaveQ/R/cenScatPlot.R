#' Function to generate a scatter plot that indicates censored and 
#' estimated water-quality concentrations.
#'
#' This function uses the qualification, or remark, column associated
#' with water-quality concentration values to indicate which samples are 
#' unqualified, which are estimated, and which are censored.
#' A blank remark field or an "_" indicates that the concentration 
#' value is not qualified; an "E" indicates the value has been 
#' estimated; and a less than symbol, "<", indicates the value has been 
#' censored as less than a minimum reporting level.  See Oblinger 
#' Childress (1999) for information on the minimum reporting level and 
#' the definition of "E" for U.S. Geological Survey data.  Other users may 
#' have a different definition of the minimum reporting level, but 
#' censored values need to be qualified with a "<".  Using the "E" code is 
#' optional.
#' 
#' @name cenScatPlot
#' @title Scatter plot of water-quality data
#' @param data The dataset with columns that begin with P followed 
#' by alphanumeric characters indicating concentration data and columns 
#' that begin with R followed by alphanumeric characters that match those 
#' of the concentration data indicating qualification codes. See example 
#' datasets for more information about the data format  
#' (\code{\link{IllRivValleyCty}} and \code{\link{qwMoRivOmaha}}).
#' @param datescol The column label for the dates column.
#' @param pname The the column heading (parameter name) for the 
#' particular water-quality constituent to be plotted (omit 
#' the starting character, for example for sulfate data indicated by 
#' P00945, enter "00945").  
#' @param qwcols A character vector with the beginning of the
#' column headers for remarks code (default is R), and beginning of 
#' column headers for concentration data (default is P for parameter).
#' @param site A label for the plot title indicating the site where
#' the water-quality samples were collected.
#' @param xlabel The label for the x-axis, defaults to no label.
#' @param ylabel The label for the y-axis.
#' @param legpos The position of the legend, see \link{legend}.
#' @param legcex A numerical value giving the amount by which the 
#' legend text and symbols should be magnified relative to the default, 1.
#' @param ... Arguments to be passed to \link{plot} method.
#' @return A scatter plot
#' @keywords hplot
#' @author Karen R. Ryberg
#' @references
#' Oblinger Childress, C.J., Foreman, W.T., Connor, B.F., and Maloney, 
#' T.J., 1999, New reporting procedures based on long-term method 
#' detection levels and some considerations for interpretations of 
#' water-quality data provided by the U.S. Geological Survey: U.S. 
#' Geological Survey Open-File Report 99--193, 19 p.,
#' \url{https://water.usgs.gov/owq/OFR_99-193/index.html}.
#' @export
#' @examples
#' data(swData)
#' # scatter plot of Simazine concentrations
#' cenScatPlot(IllRivValleyCty, pname = "04035")
#' # scatter plot with many additional plotting arguments
#' par(las = 1, tcl = 0.5)
#' cenScatPlot(IllRivValleyCty, pname = "04035", 
#'             site = "05586100 Illinois River at Valley City, IL",
#'             ylabel = "Simazine concentration, in micrograms per liter", 
#'             legcex = 0.7, ylim = c(0, 0.4), yaxs = "i", cex.lab = 0.9, 
#'             cex.axis = 0.9, xlim = c(as.Date("1996-01-01", "%Y-%m-%d"), 
#'             as.Date("2012-01-01", "%Y-%m-%d")), xaxs = "i", xaxt = "n")
#' axdates <- c("1996-01-01", "2000-01-01", "2004-01-01", "2008-01-01",
#'            "2012-01-01")
#' axis(1, as.Date(axdates, "%Y-%m-%d"), 
#'      labels = c("1996", "2000", "2004", "2008", "2012"), cex.axis = 0.9)
cenScatPlot <- function(data, datescol = "dates", pname,
                        qwcols = c("R", "P"), site = "", xlabel = "",
                        ylabel = "Concentration", legpos = "topright", 
                        legcex = 1, ...) {
  qualcode <- paste(qwcols[1], pname, sep = "")
  parameter <- paste(qwcols[2], pname, sep = "")
  subdat <- data[ , c(datescol, qualcode, parameter)]
  plot(subdat[, 1], subdat[, 3], type = "n", xlab = xlabel, ylab = ylabel, ...)
  sub1 <- subset(subdat, subdat[, 2] == "" | subdat[, 2] == "_")
  points(sub1[, 1], sub1[, 3], col = "black", pch = 16)
  sub2 <- subset(subdat, subdat[,2] == "E")
  points(sub2[, 1], sub2[, 3], col = "green", pch = 8)
  sub3 <- subset(subdat, subdat[,2] == "<")
  points(sub3[, 1], sub3[, 3], col = "red")
  leg.txt <- c("Quantified concentrations", "Estimated concentrations",
               "Censored concentrations, less thans")
  
  legend(legpos, leg.txt, col = c("black", "green", "red"), 
         pch = c(16, 8, 1), cex = legcex, bty = "n")
  if (nchar(site) >= 1) {
    title(main = site)
  }
}
