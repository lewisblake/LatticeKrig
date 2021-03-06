# LatticeKrig  is a package for analysis of spatial data written for
# the R software environment .
# Copyright (C) 2016
# University Corporation for Atmospheric Research (UCAR)
# Contact: Douglas Nychka, nychka@ucar.edu,
# National Center for Atmospheric Research, PO Box 3000, Boulder, CO 80307-3000
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the R software environment if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
# or see http://www.r-project.org/Licenses/GPL-2

print.LKrig <- function(x, digits = 4, ...) {
    LKinfo <- x$LKinfo
    
    if (is.matrix(x$residuals)) {
        n <- nrow(x$residuals)
        NData <- ncol(x$residuals)
    }
    else {
        n <- length(x$residuals)
        NData <- 1
    }
    c1 <- "Number of Observations:"
    c2 <- n
    if (NData > 1) {
        c1 <- c(c1, "Number of data sets fit:")
        c2 <- c(c2, NData)
    }
    c1 <- c(c1, "Number of parameters in the fixed component")
    c2 <- c(c2, x$nt)
    if (x$nZ > 0) {
        c1 <- c(c1, "Number of covariates")
        c2 <- c(c2, x$nZ)
    }
    if (!is.null(x$eff.df)) {
        c1 <- c(c1, " Effective degrees of freedom (EDF)")
        c2 <- c(c2, signif(x$eff.df, digits))
        c1 <- c(c1, "   Standard Error of EDF estimate: ")
        c2 <- c(c2, signif(x$trA.SE, digits))
    }
    c1 <- c(c1, "Smoothing parameter (lambda)")
    c2 <- c(c2, signif(x$lambda, digits))
    
        c1 <- c(c1, "MLE sigma ")
        c2 <- c(c2, signif(x$sigma.MLE.FULL, digits))
        
        c1 <- c(c1, "MLE rho")
        c2 <- c(c2, signif(x$rho.MLE.FULL, digits))
       
    
    
    c1 <- c(c1, "Total number of basis functions")
    c2 <- c(c2,  LKinfo$latticeInfo$m)
    
    c1 <- c(c1, "Multiresolution levels")
    c2 <- c(c2,  LKinfo$nlevel)
    
    c1<- c(c1,"log Profile Likelihood")
    c2<- c( c2, signif(x$lnProfileLike.FULL,10))
    c1<- c(c1,"log  Likelihood (if applicable)")
    c2<- c( c2, x$lnLike.FULL)
    
    c1 <- c(c1, "Nonzero entries in Ridge regression matrix")
    c2 <- c(c2, x$nonzero.entries)
    
    summary <- cbind(c1, c2)
    dimnames(summary) <- list(rep("", dim(summary)[1]), rep("", dim(summary)[2]))
#    cat("Call:\n")
#    dput(x$call)
    if( x$inverseModel){
    	 cat("NOTE: This is an 'inverse' model because U and  X matrices are supplied", fill=TRUE)}
    print(summary, quote = FALSE)
    cat(" ", fill = TRUE)
#  
    if (NData > 1) {
      cat(" ", fill = TRUE)
      if( x$collapseFixedEffect){
        cat("Estimated fixed effects pooled across
            replicates", fill=TRUE)
      }
      else{
        cat("Estimated fixed effects found separately
            for each replicate", fill=TRUE) 
      }
      cat("collapseFixedEffect :", x$collapseFixedEffect, fill=TRUE)
    }
    
    if( NData > 1){
      cat("Note: MLEs are the combined estimates across replicates.",
          fill=TRUE)
    }
    if( is.null( x$LKinfo$fixedFunction)){  
        cat("No fixed part of model", fill = TRUE)
    }
    else{
      
        if( x$LKinfo$fixedFunction == "LKrigDefaultFixedFunction"){
            cat("Fixed part of model is a polynomial of degree",
                x$LKinfo$fixedFunctionArgs$m - 1, "(m-1)", fill=TRUE)
        }  
        else{  
          cat("Fixed part of model uses the function:",
                      x$LKinfo$fixedFunction, fill = TRUE)
          cat("with the argument list:", fill = TRUE)
          print( x$LKinfo$fixedFunctionArgs)
        }
    }
    cat("Basis function type: ", LKinfo$basisInfo$BasisType, 
        fill = TRUE)
    cat("Basis function used: ", LKinfo$basisInfo$BasisFunction, 
        fill = TRUE)
    cat(" ", fill = TRUE)

      cat( LKinfo$nlevel, " Levels" ,  LKinfo$latticeInfo$m, "total basis functions", 
          "with overlap of ", 
        LKinfo$basisInfo$overlap, "(in lattice units)", fill = TRUE)
    cat(" ", fill = TRUE)
#
  temp<- cbind(  1:LKinfo$nlevel, LKinfo$latticeInfo$mLevel,  LKinfo$latticeInfo$delta)
    dimnames(temp)<- list( rep("", LKinfo$nlevel), c("Level", "Lattice points", "Spacing") )
   print( temp)
    
    cat("Type of distance metric used: ", LKinfo$distance.type, 
        fill = TRUE)
#
    cat(" ", fill = TRUE)
    if (length(LKinfo$alpha[[1]]) == 1) {
        cat("Value(s) for weighting (alpha parameters): ",
            "\n", unlist(LKinfo$alpha), 
            fill = TRUE)
    }
    else {
        cat("alpha values passed as a vector for each level", 
            fill = TRUE)
    }
#    
    cat(" ", fill = TRUE)
    if (length(LKinfo$a.wght[[1]]) == 1) {
        a.wght <- unlist(LKinfo$a.wght)
        cat("Value(s) for lattice dependence (a.wght parameters): ",
            "\n", a.wght, 
            fill = TRUE)
    }
    else {
        cat("Value(s) for weighting in GMRF (a.wght): ", unlist(LKinfo$alpha), 
            fill = TRUE)
    }
#    
    cat(" ", fill = TRUE)
    if (LKinfo$normalize) {
        cat("Basis functions normalized so marginal process variance is stationary", 
            fill = TRUE)
    }
  invisible(x)
}

