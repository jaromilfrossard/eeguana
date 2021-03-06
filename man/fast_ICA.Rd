% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ica_funs.R
\name{fast_ICA}
\alias{fast_ICA}
\title{Wrapper for FastICA method for Independent Component Analysis from fastICA package}
\usage{
fast_ICA(
  X,
  n.comp = NULL,
  alg.typ = "parallel",
  fun = "logcosh",
  alpha = 1,
  method = "C",
  row.norm = FALSE,
  maxit = 1000,
  tol = 1e-06,
  w.init = NULL
)
}
\arguments{
\item{X}{A matrix or data frame.}

\item{n.comp}{number of components to be extracted}

\item{alg.typ}{if \code{alg.typ == "parallel"} the components are extracted
    simultaneously (the default). if \code{alg.typ == "deflation"} the
    components are extracted one at a time.}

\item{fun}{the functional form of the \eqn{G} function used in the
    approximation to neg-entropy (see \sQuote{details}).}

\item{alpha}{constant in range [1, 2] used in approximation to
    neg-entropy when \code{fun == "logcosh"}}

\item{method}{if \code{method == "R"} then computations are done
    exclusively in \R (default). The code allows the interested \R user to
    see exactly what the algorithm does.
    if \code{method == "C"} then C code is used to perform most of the
    computations, which makes the algorithm run faster.  During
    compilation the C code is linked to an optimized BLAS library if
    present, otherwise stand-alone BLAS routines are compiled.}

\item{row.norm}{a logical value indicating whether rows of the data
  matrix \code{X} should be standardized beforehand.}

\item{maxit}{maximum number of iterations to perform.}

\item{tol}{a positive scalar giving the tolerance at which the
    un-mixing matrix is considered to have converged.}

\item{w.init}{Initial un-mixing matrix of dimension
    \code{c(n.comp, n.comp)}. If \code{NULL} (default) then a matrix of
    normal r.v.'s is used.}
}
\value{
A list with the unmixing matrix W and the mixing matrix A.
}
\description{
\code{fast_ICA()} is a wrapper for \link[fastICA:fastICA]{fastICA::fastICA}, with different defaults (runs in C,
maximum teration = 1000, tolerance = 1e-04, verbose), and that throws a warning in case of non-convergence.
It returns an estimated unmixing matrix W (equivalent to the original \code{K \%*\% W}), and the mixing matrix A,
consistent with the formulation \code{X= S \%*\% A}, and \code{X \%*\% W = S} where X is the matrix of data with
N_samples by N_channels, and S is a matrix of sources with N_samples by N_sources.
They are meant to be  used with \code{\link[=eeg_ica]{eeg_ica()}}.
}
\seealso{
Other ica methods: 
\code{\link{fICA}}
}
\concept{ica methods}
