\name{gamlr}
\alias{gamlr}
\alias{predict.gamlr}
\alias{plot.gamlr}
\alias{coef.gamlr}
\alias{logLik.gamlr}
\title{Gamma-Lasso regression}
\description{ Adaptive L1 penalized regression estimation. }
\usage{
gamlr(x, y, 
   family=c("gaussian","binomial","poisson"),
   gamma=0,
   nlambda=100, lambda.start=Inf,  
   lambda.min.ratio=0.01, free=NULL, 
   standardize=TRUE, doxx=FALSE,
   tol=1e-7, maxit=1e4,
   verb=FALSE, ...)

\method{plot}{gamlr}(x, against=c("pen","dev"), 
    col="navy", select=TRUE, df=TRUE, ...)
\method{coef}{gamlr}(object, select=NULL, k=log(object$nobs), ...)
\method{predict}{gamlr}(object, newdata,
            type = c("link", "response"), ...)
\method{logLik}{gamlr}(object, ...)
}
\arguments{
  \item{x}{ A dense \code{matrix} 
      or sparse \code{Matrix} of covariates,
      with \code{ncol(x)} variables and 
      \code{nrow(x)==length(y)} observations.
      This should not include the intercept.}
  \item{y}{A vector of response values. 
      There is almost no argument checking, 
      so be careful to match \code{y} with the appropriate \code{family}. 
      }
  \item{family}{ Response model type; 
  either "gaussian", "poisson", or "binomial".  
  Note that for "binomial", \code{y} is in \eqn{[0,1]}. }
  \item{gamma}{ Penalty concavity tuning parameter; see details. 
      Zero (default) yields the lasso,
      and higher values correspond to a more concave penalty.  
       }
  \item{nlambda}{ Number of regularization path segments. }
  \item{lambda.start}{ Initial penalty value.  Default of \code{Inf}
  implies the infimum lambda that returns all zero
  coefficients.  This is the largest absolute coefficient gradient at the null model. }
  \item{lambda.min.ratio}{ The smallest penalty weight 
    (expected L1 cost) as a ratio of the path start value.  
    Our default is always 0.01; note that this differs from \code{glmnet}
    whose default depends upon the dimension of \code{x}. }
  \item{free}{ Free variables: indices of the columns of \code{x} which will be unpenalized.}
  \item{standardize}{ Whether to standardize 
    the coefficients to have standard deviation of one.  
    This is equivalent to multiplying the L1 penalty 
    by each coefficient standard deviation. }
  \item{doxx}{ For \code{family="gaussian"} only, whether to pre-calculate \eqn{x'x} 
      and use gradient caluculations based on this inner product.  This can lead to massive speed-ups for big-n datasets.}
  \item{verb}{ Whether to print some output for each path segment. }
  \item{tol}{ Optimization convergence tolerance relative to the null model deviance for each 
    inner coordinate-descent loop.  This is measured against the 
    maximum coordinate change times deviance curvature after full parameter-set update. }
  \item{maxit}{ Max iterations for a single segment
         coordinate descent routine. }
   \item{object}{ A gamlr object.}
  \item{against}{ Whether to plot paths 
  against log penalty or deviance.}
\item{select}{ In \code{coef} (and \code{predict}, which calls \code{coef}), the index of path segments
  for which you want coefficients or prediction.  If null, the segments are selected via \code{AIC} with \code{k} as specified.  If \code{select=0} all segments are returned.

  In \code{plot},
  \code{select} is just a flag for whether to add lines marking AIC and BIC selected models.}
\item{k}{ If \code{select=NULL} in \code{coef} or \code{predict}, the \code{AIC} complexity penalty.  \code{k} defaults to the BIC's log(n). }
\item{newdata}{ New \code{x} data for prediction.}
\item{type}{ Either "link" for the linear equation, 
or "response" for predictions transformed 
to the same domain as \code{y}.}
\item{col}{ A single plot color, 
  or vector of length \code{ncol(x)} colors for each coefficient
    regularization path. \code{NULL} uses the \code{matplot} default. }
\item{df}{ Whether to add to the plot degrees of freedom along the top axis.}
\item{...}{ Extra arguments to each method.  Most importantly, from 
\code{predict.gamlr} these are arguments to \code{coef.gamlr}. }
}
\details{ Finds posterior modes along a regularization path
		   of \emph{adapted L1 penalties} via coordinate descent.

  Each path segment \eqn{t} minimizes the objective -\eqn{(\phi/n)}logLHD\eqn{(\beta_1
  ... \beta_p) + \sum \omega_j\lambda|\beta_j|}, where \eqn{\phi} is the
  exponential family dispersion parameter (\eqn{\sigma^2} for
  \code{family="gaussian"}, one otherwise).  Weights \eqn{\omega_j} are  
  set as \eqn{1/(1+\gamma|b_j^{t-1}|)} where \eqn{b_j^{t-1}} is our estimate of \eqn{\beta_j} for the previous path segment (or zero if \eqn{t=0}).  This adaptation is what makes the penalization `concave'; see Taddy (2013) for details.

      \code{plot.gamlr} can be used to graph the results: it 
      shows the regularization paths for penalized \eqn{\beta}, with degrees of freedom along the top axis, and marks  minimum AIC and BIC models.  
}
\value{
  \item{lambda}{The path of fitted \emph{prior expected} L1 penalties.}
  \item{nobs}{ The number of observations.}
  \item{alpha}{Intercepts.}
  \item{beta}{Regression coefficients.}
  \item{df}{Approximate degrees of freedom.}
  \item{deviance}{Fitted deviance: 
  -2( logLHD.fitted - logLHD.saturated). }
  \item{totalpass}{Total number of coordinate descent cycles. }
  \item{family}{The exponential family model.}
}
\author{
  Matt Taddy \email{taddy@chicagobooth.edu}
}
\references{Taddy (2013), The Gamma Lasso, http://arxiv.org/abs/1308.5623}

\examples{

### a low-D test (highly multi-collinear)

n <- 1000
p <- 3
xvar <- matrix(0.9, nrow=p,ncol=p)
diag(xvar) <- 1
x <- matrix(rnorm(p*n), nrow=n)\%*\%chol(xvar)
y <- 4 + 3*x[,1] + -1*x[,2] + rnorm(n)

## run models to extra small lambda 1e-3xlambda.start
fitlasso <- gamlr(x, y, gamma=0, lambda.min.ratio=1e-3) # lasso
fitgl <- gamlr(x, y, gamma=2, lambda.min.ratio=1e-3) # small gamma
fitglbv <- gamlr(x, y, gamma=10, lambda.min.ratio=1e-3) # big gamma

par(mfrow=c(1,3))
ylim = range(c(fitglbv$beta@x))
plot(fitlasso, ylim=ylim)
plot(fitgl, ylim=ylim, col="maroon")
plot(fitglbv, ylim=ylim, col="darkorange")

 }
\seealso{cv.gamlr, hockey}
