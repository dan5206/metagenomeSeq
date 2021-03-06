#' Plot of either PCA or MDS coordinates for the distances of normalized or unnormalized counts.
#' 
#' This function plots the PCA / MDS coordinates for the "n" features of interest. Potentially uncovering batch
#' effects or feature relationships.
#' 
#' 
#' @param obj A MRexperiment object or count matrix.
#' @param tran Transpose the matrix.
#' @param comp Which components to display
#' @param usePCA TRUE/FALSE whether to use PCA  or MDS coordinates (TRUE is PCA).
#' @param useDist TRUE/FALSE whether to calculate distances.
#' @param distfun Distance function, default is stats::dist
#' @param dist.method If useDist==TRUE, what method to calculate distances.
#' @param norm Whether or not to normalize the counts - if MRexperiment object.
#' @param log Whether or not to log2 the counts - if MRexperiment object.
#' @param n Number of features to make use of in calculating your distances.
#' @param ... Additional plot arguments.
#' @return coordinates
#' @seealso \code{\link{cumNormMat}}
#' @examples
#' 
#' data(mouseData)
#' cl = pData(mouseData)[,3]
#' plotOrd(mouseData,tran=TRUE,useDist=TRUE,pch=21,bg=factor(cl),usePCA=FALSE)
#' 
plotOrd<-function(obj,tran=TRUE,comp=1:2,norm=TRUE,log=TRUE,usePCA=TRUE,useDist=FALSE,distfun=stats::dist,dist.method="euclidian",n=NULL,...){
    mat = returnAppropriateObj(obj,norm,log)
    if(useDist==FALSE & usePCA==FALSE) stop("Classical MDS requires distances")
    if(is.null(n)) n = min(nrow(mat),1000)
    if(length(comp)>2) stop("Can't display more than two components")

    otusToKeep <- which(rowSums(mat)>0)
    otuVars<-rowSds(mat[otusToKeep,])
    otuIndices<-otusToKeep[order(otuVars,decreasing=TRUE)[seq_len(n)]]
    mat <- mat[otuIndices,]

    if(tran==TRUE){
        mat = t(mat)
    }
    if(useDist==TRUE){
        d <- distfun(mat,method=dist.method)
    } else{ d = mat }
    
    if(usePCA==FALSE){
        ord = cmdscale(d,k = max(comp))
        xl = paste("MDS component:",comp[1])
        yl = paste("MDS component:",comp[2])
    } else{
        pcaRes <- prcomp(d)
        ord <- pcaRes$x
        vars <- pcaRes$sdev^2
        vars <- round(vars/sum(vars),5)*100
        xl <- sprintf("PCA %s: %.2f%% variance",colnames(ord)[comp[1]], vars[comp[1]])
        yl <- sprintf("PCA %s: %.2f%% variance",colnames(ord)[comp[2]], vars[comp[2]])
    }

	plot(ord[,comp],ylab=yl,xlab=xl,...)
    invisible(ord[,comp])
}
