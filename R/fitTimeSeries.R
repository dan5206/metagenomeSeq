#' @name trapz
#' @title Trapezoidal Integration
#' 
#' Compute the area of a function with values 'y' at the points 'x'.
#' Function comes from the pracma package.
#' 
#' @param x x-coordinates of points on the x-axis
#' @param y y-coordinates of function values
#' @return Approximated integral of the function from 'min(x)' to 'max(x)'. 
#'  Or a matrix of the same size as 'y'.
#' @rdname trapz
#' @export
#' @examples
#' 
#' # Calculate the area under the sine curve from 0 to pi:
#'  n <- 101
#'  x <- seq(0, pi, len = n)
#'  y <- sin(x)
#'  trapz(x, y)          #=> 1.999835504
#' 
#' # Use a correction term at the boundary: -h^2/12*(f'(b)-f'(a))
#'  h  <- x[2] - x[1]
#'  ca <- (y[2]-y[1]) / h
#'  cb <- (y[n]-y[n-1]) / h
#'  trapz(x, y) - h^2/12 * (cb - ca)  #=> 1.999999969
#'
trapz <- function(x,y){
    if (missing(y)) {
        if (length(x) == 0) 
            return(0)
        y <- x
        x <- 1:length(x)
    }
    if (length(x) == 0) 
        return(0)
    if (!(is.numeric(x) || is.complex(x)) || !(is.numeric(y) || 
        is.complex(y))) 
        stop("Arguments 'x' and 'y' must be real or complex.")
    m <- length(x)
    xp <- c(x, x[m:1])
    yp <- c(numeric(m), y[m:1])
    n <- 2 * m
    p1 <- sum(xp[1:(n - 1)] * yp[2:n]) + xp[n] * yp[1]
    p2 <- sum(xp[2:n] * yp[1:(n - 1)]) + xp[1] * yp[n]
    return(0.5 * (p1 - p2))
}

#' @name ssFit
#' @title smoothing-splines anova fit
#' 
#' @details Sets up a data-frame with the feature abundance, 
#' class information, time points, sample ids and returns
#' the fitted values for the fitted model.
#' 
#' @param formula Formula for ssanova.
#' @param abundance Numeric vector of abundances.
#' @param class Class membership (factor of group membership).
#' @param time Time point vector of relative times (same length as abundance).
#' @param id Sample / patient id.
#' @param include Parameters to include in prediction.
#' @param pd Extra variable.
#' @param ... Extra parameters for ssanova function (see ?ssanova).
#' @return \itemize{A list containing:
#' \item     data        : Inputed data
#' \item     fit         : The interpolated / fitted values for timePoints
#' \item     se          : The standard error for CI intervals
#' \item     timePoints  : The time points interpolated over
#' }
#' @seealso \code{\link{cumNorm}} \code{\link{fitTimeSeries}} \code{\link{ssPermAnalysis}} \code{\link{ssPerm}} \code{\link{ssIntervalCandidate}}
#' @rdname ssFit
#' @export
#' @examples
#'
#' # Not run
#'
ssFit <- function(formula,abundance,class,time,id,include=c("class", "time:class"),pd,...) {
    df = data.frame(abundance = abundance, class = factor(class),
       time=time,id = factor(id),pd)
    
    # The smoothing splines anova model
    if(missing(formula)){
        mod = gss::ssanova(abundance ~ time * class, data=df,...)
    } else{
        mod = gss::ssanova(formula,data=df,...)
    }

    fullTime = seq(min(df$time), max(df$time), by=1)
    values = data.frame(time=fullTime, class=factor(levels(df[,"class"]))[2])
    fit = predict(mod, values, include=include, se=TRUE)
    
    res = list(data=df, fit=fit$fit, se=fit$se, timePoints=fullTime)
    return(res)
}

#' @name ssPerm
#' @title class permutations for smoothing-spline time series analysis
#' 
#' Creates a list of permuted class memberships for the time series permuation tests.
#' 
#' @param df Data frame containing class membership and sample/patient id label.
#' @param B Number of permutations.
#' @return A list of permutted class memberships
#' @seealso \code{\link{cumNorm}} \code{\link{fitTimeSeries}} \code{\link{ssFit}} \code{\link{ssPermAnalysis}} \code{\link{ssIntervalCandidate}}
#' @rdname ssPerm
#' @examples
#'
#' # Not run
#'
ssPerm <- function(df,B) {
    dat = data.frame(class=df$class, id=df$id)
    # id  = table(dat$id)
    id = table(interaction(dat$class,dat$id))
    id = id[id>0]
    classes = unique(dat)[,"class"]
    permList = lapply(1:B,function(i){
        rep(sample(classes, replace=FALSE),id)
    })
    return(permList) 
}

#' @name ssPermAnalysis
#' @title smoothing-splines anova fits for each permutation
#' 
#' @details Calculates the fit for each permutation and estimates 
#' the area under the null (permutted) model for interesting time 
#' intervals of differential abundance.
#' 
#' @param data Data used in estimation.
#' @param formula Formula for ssanova.
#' @param permList A list of permutted class memberships
#' @param intTimes Interesting time intervals.
#' @param timePoints Time points to interpolate over.
#' @param include Parameters to include in prediction.
#' @param ... Options for ssanova
#' @return A matrix of permutted area estimates for time intervals of interest.
#' @seealso \code{\link{cumNorm}} \code{\link{fitTimeSeries}} \code{\link{ssFit}} \code{\link{ssPerm}} \code{\link{ssIntervalCandidate}}
#' @rdname ssPermAnalysis
#' @export
#' @examples
#'
#' # Not run
#'
ssPermAnalysis <- function(data,formula,permList,intTimes,timePoints,include=c("class", "time:class"),...){
    resPerm=matrix(NA, length(permList), nrow(intTimes))
    permData=data
    case = data.frame(time=timePoints, class=factor(levels(data$class)[2]))
    for (j in 1:length(permList)){
        
        permData$class = permList[[j]]
        # The smoothing splines anova model
        if(!missing(formula)){
            permModel = gss::ssanova(formula, data=permData,...)
        } else{
            permModel = gss::ssanova(abundance ~ time * class,data=permData,...)
        }

        permFit = cbind(timePoints, (2*predict(permModel,case,include=include, se=TRUE)$fit))
            for (i in 1:nrow(intTimes)){
                permArea=permFit[which(permFit[,1]==intTimes[i,1]) : which(permFit[,1]==intTimes[i, 2]), ]
                resPerm[j, i]=metagenomeSeq::trapz(x=permArea[,1], y=permArea[,2])
            }
        if(j%%100==0) show(j)
    }
    return(resPerm)
}

#' @name ssIntervalCandidate
#' @title calculate interesting time intervals
#' 
#' Calculates time intervals of interest using SS-Anova fitted confidence intervals.
#' 
#' @param fit SS-Anova fits.
#' @param standardError SS-Anova se estimates.
#' @param timePoints Time points interpolated over.
#' @param positive Positive region or negative region (difference in abundance is positive/negative).
#' @param C Value for which difference function has to be larger or smaller than (default 0).
#' @return Matrix of time point intervals of interest
#' @seealso \code{\link{cumNorm}} \code{\link{fitTimeSeries}} \code{\link{ssFit}} \code{\link{ssPerm}} \code{\link{ssPermAnalysis}}
#' @rdname ssIntervalCandidate
#' @export
#' @examples
#'
#' # Not run
#'
ssIntervalCandidate <- function(fit, standardError, timePoints, positive=TRUE,C=0){
    lowerCI = (2*fit - (1.96*2*standardError))
    upperCI = (2*fit + (1.96*2*standardError))
    if (positive){
        abundanceDifference = which( lowerCI>=0 & abs(lowerCI)>=C )
    }else{
        abundanceDifference = which( upperCI<=0 & abs(upperCI)>=C )
    }
    if (length(abundanceDifference)>0){
        intIndex=which(diff(abundanceDifference)!=1)
        intTime=matrix(NA, (length(intIndex)+1), 4)
        if (length(intIndex)==0){
            intTime[1,1]=timePoints[abundanceDifference[1]]
            intTime[1,2]=timePoints[tail(abundanceDifference, n=1)]
        }else{
            i=1
            while(length(intTime)!=0 & length(intIndex)!=0){
                intTime[i,1]=timePoints[abundanceDifference[1]]
                intTime[i,2]=timePoints[abundanceDifference[intIndex[1]]]
                abundanceDifference=abundanceDifference[-c(1:intIndex[1])]
                intIndex=intIndex[-1]
                i=i+1
            }
        intTime[i,1] = timePoints[abundanceDifference[1]]
        intTime[i,2] = timePoints[tail(abundanceDifference, n=1)]
        }
    }else{
        intTime=NULL   
    }   
    return(intTime)    
}

#' @name fitSSTimeSeries
#' @title Discover differentially abundant time intervals using SS-Anova
#' 
#' @details Calculate time intervals of interest using SS-Anova fitted models.
#' Fitting is performed uses Smoothing Spline ANOVA (SS-Anova) to find interesting intervals of time. 
#' Given observations at different time points for two groups, fitSSTimeSeries 
#' calculates a  function that models the difference in abundance between two 
#' groups across all time. Using permutations we estimate a null distribution 
#' of areas for the time intervals of interest and report significant intervals of time.
#' Use of the function for analyses should cite:
#' "Finding regions of interest in high throughput genomics data using smoothing splines"
#' Talukder H, Paulson JN, Bravo HC. (Submitted)
#' 
#' @param obj metagenomeSeq MRexperiment-class object.
#' @param formula Formula for ssanova.
#' @param feature Name or row of feature of interest.
#' @param class Name of column in phenoData of MRexperiment-class object for class memberhip.
#' @param time Name of column in phenoData of MRexperiment-class object for relative time.
#' @param id Name of column in phenoData of MRexperiment-class object for sample id.
#' @param lvl Vector or name of column in featureData of MRexperiment-class object for aggregating counts (if not OTU level).
#' @param include Parameters to include in prediction.
#' @param C Value for which difference function has to be larger or smaller than (default 0).
#' @param B Number of permutations to perform
#' @param norm When aggregating counts to normalize or not.
#' @param log Log2 transform.
#' @param sl Scaling value.
#' @param ... Options for ssanova
#' @return List of matrix of time point intervals of interest, Difference in abundance area and p-value, fit, area permutations, and call.
#' @return A list of objects including:
#' \itemize{
#'  \item{timeIntervals - Matrix of time point intervals of interest, area of differential abundance, and pvalue.}
#'  \item{data  - Data frame of abundance, class indicator, time, and id input.}
#'  \item{fit - Data frame of fitted values of the difference in abundance, standard error estimates and timepoints interpolated over.}
#'  \item{perm - Differential abundance area estimates for each permutation.}
#'  \item{call - Function call.}
#' }
#' @rdname fitSSTimeSeries
#' @seealso \code{\link{cumNorm}} \code{\link{ssFit}} \code{\link{ssIntervalCandidate}} \code{\link{ssPerm}} \code{\link{ssPermAnalysis}} \code{\link{plotTimeSeries}}
#' @export
#' @examples
#'
#' data(mouseData)
#' res = fitSSTimeSeries(obj=mouseData,feature="Actinobacteria",
#'    class="status",id="mouseID",time="relativeTime",lvl='class',B=2)
#'
fitSSTimeSeries <- function(obj,formula,feature,class,time,id,lvl=NULL,include=c("class", "time:class"),C=0,B=1000,norm=TRUE,log=TRUE,sl=1000,...) {
    
    if(!is.null(lvl)){
        aggData = aggregateByTaxonomy(obj,lvl,norm=norm,sl=sl)
        abundance = MRcounts(aggData,norm=FALSE,log=log,sl=1)[feature,]
    } else { 
        abundance = MRcounts(obj,norm=norm,log=log,sl=sl)[feature,]
    }
    class = pData(obj)[,class]
    time  = pData(obj)[,time]
    id    = pData(obj)[,id]

    if(!missing(formula)){
        prep=ssFit(formula=formula,abundance=abundance,class=class,
            time=time,id=id,include=include,pd=pData(obj),...)
    } else {
        prep=ssFit(abundance=abundance,class=class,time=time,id=id,
            include=include,pd=pData(obj),...)
    }
    indexPos = ssIntervalCandidate(fit=prep$fit, standardError=prep$se, 
        timePoints=prep$timePoints, positive=TRUE,C=C)
    indexNeg = ssIntervalCandidate(fit=prep$fit, standardError=prep$se, 
        timePoints=prep$timePoints, positive=FALSE,C=C)
    indexAll = rbind(indexPos, indexNeg)

    if(sum(indexAll[,1]==indexAll[,2])>0){
        indexAll=indexAll[-which(indexAll[,1]==indexAll[,2]),]
    }

    fit = 2*prep$fit
    se  = 2*prep$se
    timePoints = prep$timePoints
    fits = data.frame(fit = fit, se = se, timePoints = timePoints)
    
    if(!is.null(indexAll)){
      if(length(indexAll)>0){
        indexAll=matrix(indexAll,ncol=4)
        colnames(indexAll)=c("Interval start", "Interval end", "Area", "p.value")
        predArea    = cbind(prep$timePoints, (2*prep$fit))
        permList    = ssPerm(prep$data,B=B)
        if(!missing(formula)){
            permResult  = ssPermAnalysis(data=prep$data,formula=formula,permList=permList,
                intTimes=indexAll,timePoints=prep$timePoints,include=include,...)
        } else {
            permResult  = ssPermAnalysis(data=prep$data,permList=permList,
                intTimes=indexAll,timePoints=prep$timePoints,include=include,...)
        }
        
        for (i in 1:nrow(indexAll)){
            origArea=predArea[which(predArea[,1]==indexAll[i,1]):which(predArea[,1]==indexAll[i, 2]), ]
            actArea=trapz(x=origArea[,1], y=origArea[,2])
            indexAll[i,3] = actArea
            if(actArea>0){
                indexAll[i,4] = 1 - length(which(actArea>permResult[,i]))/B
            }else{
                indexAll[i,4] = length(which(actArea>permResult[,i]))/B
            }

        }

        res = list(timeIntervals=indexAll,data=prep$data,fit=fits,perm=permResult)
        return(res)
      }
    }else{
        indexAll = "No statistically significant time intervals detected"
        res = list(timeIntervals=indexAll,data=prep$data,fit=fits,perm=NULL)
        return(res)
    }
}

#' @name fitTimeSeries
#' @title Discover differentially abundant time intervals
#' 
#' @details Calculate time intervals of significant differential abundance.
#' Currently only one method is implemented (ssanova). fitSSTimeSeries is called with method="ssanova".
#' Use of the function for analyses should cite:
#' "Finding regions of interest in high throughput genomics data using smoothing splines"
#' Talukder H, Paulson JN, Bravo HC. (Submitted)
#' 
#' @param obj metagenomeSeq MRexperiment-class object.
#' @param formula Formula for ssanova.
#' @param feature Name or row of feature of interest.
#' @param class Name of column in phenoData of MRexperiment-class object for class memberhip.
#' @param time Name of column in phenoData of MRexperiment-class object for relative time.
#' @param id Name of column in phenoData of MRexperiment-class object for sample id.
#' @param method Method to estimate time intervals of differentially abundant bacteria (only ssanova method implemented currently).
#' @param lvl Vector or name of column in featureData of MRexperiment-class object for aggregating counts (if not OTU level).
#' @param include Parameters to include in prediction.
#' @param C Value for which difference function has to be larger or smaller than (default 0).
#' @param B Number of permutations to perform
#' @param norm When aggregating counts to normalize or not.
#' @param log Log2 transform.
#' @param sl Scaling value.
#' @param ... Options for ssanova
#' @return List of matrix of time point intervals of interest, Difference in abundance area and p-value, fit, area permutations, and call.
#' @return A list of objects including:
#' \itemize{
#'  \item{timeIntervals - Matrix of time point intervals of interest, area of differential abundance, and pvalue.}
#'  \item{data  - Data frame of abundance, class indicator, time, and id input.}
#'  \item{fit - Data frame of fitted values of the difference in abundance, standard error estimates and timepoints interpolated over.}
#'  \item{perm - Differential abundance area estimates for each permutation.}
#'  \item{call - Function call.}
#' }
#' @rdname fitTimeSeries
#' @seealso \code{\link{cumNorm}} \code{\link{fitSSTimeSeries}} \code{\link{plotTimeSeries}}
#' @export
#' @examples
#'
#' data(mouseData)
#' res = fitTimeSeries(obj=mouseData,feature="Actinobacteria",
#'    class="status",id="mouseID",time="relativeTime",lvl='class',B=2)
#'
fitTimeSeries <- function(obj,formula,feature,class,time,id,method=c("ssanova"),
                        lvl=NULL,include=c("class", "time:class"),C=0,B=1000,
                        norm=TRUE,log=TRUE,sl=1000,...) {
    if(method=="ssanova"){
        if(requireNamespace("gss")){
            if(missing(formula)){
                res = fitSSTimeSeries(obj=obj,feature=feature,class=class,time=time,id=id,
                        lvl=lvl,C=C,B=B,norm=norm,log=log,sl=sl,include=include,...)
            } else {
                res = fitSSTimeSeries(obj=obj,formula=formula,feature=feature,class=class,
                        time=time,id=id,lvl=lvl,C=C,B=B,norm=norm,log=log,sl=sl,
                        include=include,...)
            }
        }
    }
    res = c(res,call=match.call())
    return(res)
}

#' @name plotTimeSeries
#' @title Plot difference function for particular bacteria
#' 
#' @details Plot the difference in abundance for significant features.
#' 
#' @param res Output of fitTimeSeries function
#' @param C Value for which difference function has to be larger or smaller than (default 0).
#' @param xlab X-label.
#' @param ylab Y-label.
#' @param main Main label.
#' @param ... Extra plotting arguments.
#' @return Plot of difference in abundance for significant features.
#' @rdname plotTimeSeries
#' @seealso \code{\link{fitTimeSeries}}
#' @export
#' @examples
#'
#' data(mouseData)
#' res = fitTimeSeries(obj=mouseData,feature="Actinobacteria",
#'    class="status",id="mouseID",time="relativeTime",lvl='class',B=10)
#' plotTimeSeries(res)
#'
plotTimeSeries<-function(res,C=0,xlab="Time",ylab="Difference in abundance",main="SS difference function prediction",...){
    fit = res$fit$fit
    se  = res$fit$se
    timePoints = res$fit$timePoints
    confInt95 = 1.96
    sigDiff = res$timeIntervals

    minValue=min(fit-(confInt95*se))-.5
    maxValue=max(fit+(confInt95*se))+.5

    plot(x=timePoints, y=fit, ylim=c(minValue, maxValue), xlab=xlab, ylab=ylab, main=main, ...)

    for (i in 1:nrow(sigDiff)){
        begin=sigDiff[i,1]
        end=sigDiff[i,2]
        indBegin=which(timePoints==begin)
        indEnd=which(timePoints==end)
        x=timePoints[indBegin:indEnd]
        y=fit[indBegin:indEnd]
        xx=c(x, rev(x))
        yy=c(y, rep(0, length(y)))
        polygon(x=xx, yy, col="grey")
    }
    lines(x=timePoints, y=fit, pch="")
    lines(x=timePoints, y=fit+(confInt95*se), pch="", lty=2)
    lines(x=timePoints, y=fit-(confInt95*se), pch="", lty=2)
    abline(h=C)
}

#' @name plotClassTimeSeries
#' @title Plot abundances by class
#' 
#' @details Plot the abundance of values for each class using 
#' a spline approach on the estimated full model.
#' 
#' @param res Output of fitTimeSeries function
#' @param formula Formula for ssanova.
#' @param xlab X-label.
#' @param ylab Y-label.
#' @param color0 Color of samples from first group.
#' @param color1 Color of samples from second group.
#' @param include Parameters to include in prediction.
#' @param ... Extra plotting arguments.
#' @return Plot for abundances of each class using a spline approach on estimated null model.
#' @rdname plotClassTimeSeries
#' @seealso \code{\link{fitTimeSeries}}
#' @export
#' @examples
#'
#' data(mouseData)
#' res = fitTimeSeries(obj=mouseData,feature="Actinobacteria",
#'    class="status",id="mouseID",time="relativeTime",lvl='class',B=10)
#' plotClassTimeSeries(res,pch=21,bg=res$data$class,ylim=c(0,8))
#'
plotClassTimeSeries<-function(res,formula,xlab="Time",ylab="Abundance",color0="black",
                            color1="red",include=c("1","class", "time:class"),...){
    dat = res$data
    if(missing(formula)){
        mod = gss::ssanova(abundance ~ time * class, data=dat)
    } else{
        mod = gss::ssanova(formula,data=dat)
    }
    
    timePoints = seq(min(dat$time),max(dat$time),by=1)
    group0 = data.frame(time=timePoints,class=levels(dat$class)[1])
    group1 = data.frame(time=timePoints,class=levels(dat$class)[2])

    pred0  = predict(mod, newdata=group0,include=include, se=TRUE)
    pred1  = predict(mod, newdata=group1,include=include, se=TRUE)
    
    plot(x=dat$time,y=dat$abundance,xlab=xlab,ylab=ylab,...)
    lines(x=group0$time,y=pred0$fit,col=color0)
    lines(x=group0$time,y=pred0$fit+(1.96*pred0$se),lty=2,col=color0)
    lines(x=group0$time,y=pred0$fit-(1.96*pred0$se),lty=2,col=color0)

    lines(x=group1$time,y=pred1$fit,col=color1)
    lines(x=group1$time,y=pred1$fit+(1.96*pred1$se),lty=2,col=color1)
    lines(x=group1$time,y=pred1$fit-(1.96*pred1$se),lty=2,col=color1)
}

# load("~/Dropbox/Projects/metastats/package/git/metagenomeSeq/data/mouseData.rda")
# classMatrix = aggregateByTaxonomy(mouseData,lvl='class',norm=TRUE,out='MRexperiment')
# data(mouseData)
# fitTimeSeries(obj=mouseData,feature="Actinobacteria",class="status",id="mouseID",time="relativeTime",lvl='class',B=10)