% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/defunct.R
\name{defunct}
\alias{defunct}
\alias{downsample}
\alias{segment}
\alias{interpolate_tbl}
\alias{event_to_ch_NA}
\alias{eeg_intervals_to_NA}
\alias{ch_filt_low_pass}
\alias{ch_filt_high_pass}
\alias{ch_filt_band_pass}
\alias{ch_filt_stop_pass}
\alias{events}
\alias{events<-}
\alias{summarize_all_ch}
\alias{summarize_at_ch}
\alias{plot_gg}
\alias{ch_baseline}
\title{Defunct functions in eeguana}
\usage{
downsample(x, q = 2, max_sample = NULL, ...)

segment(x, ...)

interpolate_tbl(.data, ...)

event_to_ch_NA(x, ...)

eeg_intervals_to_NA(x, ...)

ch_filt_low_pass(x, ...)

ch_filt_high_pass(x, ...)

ch_filt_band_pass(x, ...)

ch_filt_stop_pass(x, ...)

events(x, ...)

events(x) <- value

summarize_all_ch(x, ...)

summarize_at_ch(x, ...)

plot_gg(x, ...)

ch_baseline(x, ...)
}
\arguments{
\item{x}{Variable storing the x coordinate, generally \code{.x} (default).}

\item{q}{integer factor(s) to downsample by.}

\item{max_sample}{Optionally, the (approximated) maximum sample number can be defined here, which is at least half of the total number of samples}

\item{...}{Not in use.}

\item{.data}{An eeg_lst object.}

\item{value}{Values used for the interpolation, generally \code{.value} (default).}
}
\description{
These functions are defunct.
}
\details{
\itemize{
\item 'downsample()' should be changed to 'eeg_downsample()'.
\item 'segment()' should be changed to 'eeg_segment()'.
\item 'interpolate_tbl()' should be changed to 'eeg_interpolate_tbl()'.
\item 'event_to_ch_NA()' should be changed to 'eeg_intervals_to_NA()'.
\item 'ch_filt_low_pass()' should be changed to 'eeg_filt_low_pass()'.
\item 'ch_filt_high_pass()' should be changed to 'eeg_filt_high_pass()'.
\item 'ch_filt_band_pass()' should be changed to 'eeg_filt_band_pass()'.
\item 'ch_filt_stop_pass()' should be changed to 'eeg_filt_band_stop()'.
\item 'ch_baseline()' should be changed to 'eeg_baseline()'.
\item 'events()' should be changed to 'events_tbl()'.
\item 'plot_gg()' should be changed to 'ggplot(aes(x=.time, y=.value))'.
\item 'summarize_all_ch(...)' should be changed to \code{summarize_at(channel_names(.),...)}.
\item 'summarize_at_ch(...)' should be changed to \code{summarize_at(...)}.
}
}
\keyword{internal}
