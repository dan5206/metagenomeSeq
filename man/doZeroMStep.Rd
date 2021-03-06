% Generated by roxygen2 (4.1.0): do not edit by hand
% Please edit documentation in R/doZeroMStep.R
\name{doZeroMStep}
\alias{doZeroMStep}
\title{Compute the zero Maximization step.}
\usage{
doZeroMStep(z, zeroIndices, mmZero)
}
\arguments{
\item{z}{Matrix (m x n) of estimate responsibilities (probabilities that a
count comes from a spike distribution at 0).}

\item{zeroIndices}{Index (matrix m x n) of counts that are zero/non-zero.}

\item{mmZero}{The zero model, the model matrix to account for the change in
the number of OTUs observed as a linear effect of the depth of coverage.}
}
\value{
List of the zero fit (zero mean model) coefficients, variance -
scale parameter (scalar), and normalized residuals of length
sum(zeroIndices).
}
\description{
Performs Maximization step calculation for the mixture components. Uses
least squares to fit the parameters of the mean of the logistic
distribution. $$ pi_j = sum_i^M frac1Mz_ij $$ Maximum-likelihood estimates
are approximated using the EM algorithm where we treat mixture membership
$delta_ij$ = 1 if $y_ij$ is generated from the zero point mass as latent
indicator variables. The density is defined as $f_zig(y_ij = pi_j(S_j) cdot
f_0(y_ij) +(1-pi_j (S_j))cdot f_count(y_ij;mu_i,sigma_i^2)$. The
log-likelihood in this extended model is $(1-delta_ij) log
f_count(y;mu_i,sigma_i^2 )+delta_ij log pi_j(s_j)+(1-delta_ij)log (1-pi_j
(sj))$. The responsibilities are defined as $z_ij = pr(delta_ij=1 | data)$.
}
\seealso{
\code{\link{fitZig}}
}

