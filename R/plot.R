#' Create a basic signal plot
#'
#' `plot` creates a ggplot object in which the EEG signal over the whole
#' recording is plotted by electrode. Useful as a quick visual check for major
#' noise issues in the recording.
#'
#' Note that for normal-size datasets, the plot may take some time to compile.
#' If necessary, `plot` will first downsample the `eeg_lst` object so that there is a
#' maximum of 6,400 samples. The `eeg_lst` object is then converted to a long-format
#' tibble via `as_tibble`. In this tibble, the `.key` variable is the
#' channel/component name and `.value` its respective amplitude. The sample
#' number (`.sample` in the `eeg_lst` object) is automatically converted to seconds
#' to create the variable `time`. By default, time is then plotted on the
#' x-axis and amplitude on the y-axis, and uses `scales = "free"`; see [ggplot2::facet_grid()].
#'
#' To add additional components to the plot such as titles and annotations, simply
#' use the `+` symbol and add layers exactly as you would for [ggplot2::ggplot].
#'
#'
#' @param x An `eeg_lst` object.
#' @param max_sample Downsample to approximately 6400 samples by default.
#' @param ... Not in use.
#' @family plotting functions
#'
#' @return A ggplot object
#'
#' @examples
#' 
#' # Basic plot
#' plot(data_faces_ERPs)
#' 
#' # Add ggplot layers
#' library(ggplot2)
#' plot(data_faces_ERPs) +
#'   coord_cartesian(ylim = c(-500, 500))
#' @export
plot.eeg_lst <- function(x, max_sample = 6400, ...) {
  ellipsis::check_dots_unnamed()
  #pick the last channel as reference
  breaks <- x$.signal[[ncol(x$.signal)]]  %>% 
    stats::quantile(probs = c(.025,.975), na.rm=TRUE) %>% 
    signif(2) %>% c(0)
  names(breaks) <- breaks
  lims <-  (breaks * 1.5) %>% 
    range()
  
  plot <- ggplot.eeg_lst(x, ggplot2::aes(x = .time, y = .value, group = .id), max_sample = max_sample) +
    ggplot2::geom_hline(yintercept = 0, color = "gray",alpha =.8) +
    ggplot2::geom_line() +
    ggplot2::facet_grid(.key ~ .id,
      labeller = ggplot2::label_wrap_gen(multi_line = FALSE),
      scales = "free", space= "free"
    ) +
    ggplot2::scale_x_continuous("Time (s)") +
    ggplot2::scale_y_continuous("Amplitude", 
                                #breaks = breaks,
                                ) +
    ggplot2::coord_cartesian(ylim = lims, clip = FALSE, expand = FALSE) +
    theme_eeguana()
  plot
}





#' Create a topographic plot
#'
#' `plot_topo` initializes a ggplot object which takes an `eeg_lst` object
#' as its input data. Layers can then be added in the same way as for a
#' `ggplot2::ggplot` object.
#'
#' Before calling `plot_topo`, the `eeg_lst` object object must be appropriately
#' grouped (e.g. by condition) and/or
#' summarized into mean values such that each .x .y coordinate has only one
#' amplitude value. By default, `plot_topo` interpolates amplitude values via
#' `eeg_interpolate_tbl`, which generates a tibble with `.key` (channel),
#'  `.value` (amplitude), and .x .y coordinate variables. .x .y coordinates are
#' extracted from the `eeg_lst` object, which in turn reads the coordinates logged
#' by your EEG recording software. By default, `plot_topo` will display electrodes
#' in polar arrangement, but can be changed with the `projection`
#' argument. Alternatively, if `eeg_interpolate_tbl` is called after grouping/summarizing
#' but before `plot_topo`, the resulting electrode layout will be stereographic.
#'
#' `plot_topo` called alone
#' without any further layers will create an unannotated topographical plot.
#' To add a head and nose, add the layer `annotate_head`. Add
#' contour lines with `ggplot2::geom_contour` and electrode labels
#' with `ggplot2::geom_text`. These arguments are deliberately not
#' built into the function so as to allow flexibility in choosing color, font
#' size, and even head size, etc.
#'
#' To add additional components to the plot such as titles and annotations, simply
#' use the `+` symbol and add layers exactly as you would for [ggplot2::ggplot].
#'
#'
#' @param data A table of interpolated electrodes as produced by `eeg_interpolate_tbl`, or an `eeg_lst`, or `ica_lst` appropiately grouped.
#' @param ... If data are an `eeg_lst` or `ica_lst`, these are arguments passed to `eeg_interpolate_tbl`, such as, radius, size, etc.
#'
#' @family plotting functions
#' @family topographic plots and layouts
#' @return A ggplot object
#'
#' @examples
#' library(dplyr)
#' library(ggplot2)
#' # Calculate mean amplitude between 100-200 ms and plot the topography
#' data_faces_ERPs %>%
#'   # select the time window of interest
#'   filter(between(as_time(.sample, unit = "milliseconds"), 100, 200)) %>%
#'   # compute mean amplitude per condition
#'   group_by(condition) %>%
#'   summarize_at(channel_names(.), mean, na.rm = TRUE) %>%
#'   plot_topo() +
#'   # add a head and nose shape
#'   annotate_head() +
#'   # add contour lines
#'   geom_contour() +
#'   # add electrode labels
#'   geom_text(color = "black") +
#'   facet_grid(~condition)
#' 
#' # The same but with interpolation
#' data_faces_ERPs %>%
#'   filter(between(as_time(.sample, unit = "milliseconds"), 100, 200)) %>%
#'   group_by(condition) %>%
#'   summarize_at(channel_names(.), mean, na.rm = TRUE) %>%
#'   eeg_interpolate_tbl() %>%
#'   plot_topo() +
#'   annotate_head() +
#'   geom_contour() +
#'   geom_text(color = "black") +
#'   facet_grid(~condition)
#' @export
plot_topo <- function(data, ...) {
  UseMethod("plot_topo")
}
#' @rdname plot_topo
#' @export
plot_topo.tbl_df <- function(data, value = .value, label = .key, ...) {
  if(all(is.na(data$.x)) && all(is.na(data$.y)) ) {
    stop("X and Y coordinates missing. You probably need to add a layout to the data.", call. = FALSE)}
  if(all(is.na(data$.x))) {stop("X coordinate missing.", call. = FALSE)}
  if(all(is.na(data$.y))) {stop("Y coordinate missing.", call. = FALSE)}
  value <- rlang::enquo(value)
  label <- rlang::enquo(label)
  data <- data %>%  dplyr::ungroup()
  # Labels positions mess up with geom_raster, they need to be excluded
  # and then add the labels to the data that was interpolated
  d <- dplyr::filter(data, !is.na(.x), !is.na(.y), is.na(!!label)) %>%
    dplyr::select(-!!label)
  label_pos <- dplyr::filter(data, !is.na(.x), !is.na(.y), !is.na(!!label)) %>%
    dplyr::distinct(.x, .y, !!label)
  label_corrected_pos <- purrr::map_df(label_pos %>% 
                                         dplyr::select(.x, .y, !!label) %>%
                                         purrr::transpose(), function(l) {
    d %>%
      dplyr::select(-!!value) %>%
      dplyr::filter((.x - l$.x)^2 + (.y - l$.y)^2 == min((.x - l$.x)^2 + (.y - l$.y)^2)) %>%
      # does the original grouping so that I add a label to each group
      dplyr::group_by_at(dplyr::vars(colnames(.)[!colnames(.) %in% c(".x", ".y")])) %>%
      dplyr::slice(1) %>%
      dplyr::mutate(!!label := l[[".key"]])
  })
  d <- suppressMessages(dplyr::left_join(d, label_corrected_pos))


  # remove all the AES from the geoms, to remove later the geoms
  # see if geom_text can work with NA or something
  plot <-
    ggplot2::ggplot(d, ggplot2::aes(
      x = .x, y = .y,
      fill = !!value, z = !!value, label = dplyr::if_else(!is.na(!!label), !!label, "")
    )) +
    ggplot2::geom_raster(interpolate = TRUE, hjust = 0.5, vjust = 0.5) +
    # Non recommended "rainbow" Matlab palette from https://www.mattcraddock.com/blog/2017/02/25/erp-visualization-creating-topographical-scalp-maps-part-1/
    #    scale_fill_gradientn(colors = colorRampPalette(c("#00007F", "blue", "#007FFF", "cyan", "#7FFF7F", "yellow", "#FF7F00", "red", "#7F0000")),guide = "colourbar",oob = scales::squish)+
    # Not that bad scale:
    #    scale_fill_distiller(palette = "Spectral", guide = "colorbar", oob = scales::squish) + #
    ggplot2::scale_fill_distiller(type = "div", palette = "RdBu", guide = "colorbar", oob = scales::squish) +
    theme_eeguana2()
  plot
}

#' @inheritParams plot_in_layout
#' @inheritParams eeg_interpolate_tbl
#' @rdname plot_topo
#' @export
plot_topo.eeg_lst <- function(data, projection = "polar", ...) {
  channels_tbl(data) <- change_coord(channels_tbl(data), projection)
  eeg_interpolate_tbl(data, ...) %>%
    plot_topo()
}

#' Generates topographic plots of the components after running ICA on an eeg_lst
#'
#' Note that unlike [plot_topo], there is no need for faceting, or adding layers.
#'
#' @param data An eeg_ica_lst
#'
#'
#' @family plotting functions
#' @family ICA functions
#' @family topographic plots and layouts
#' @inheritParams plot_topo
#' @param standardize Whether to standardize the color scale of each topographic plot.
#' @rdname plot_components
#' @export
plot_components <- function(data, ...,projection = "polar",standardize= TRUE) {
  UseMethod("plot_components")
}
#' @export
plot_components.eeg_ica_lst <- function(data,...,projection = "polar",standardize= TRUE) {
  comp_sel <- sel_comp(data,...)
  channels_tbl(data) <- change_coord(channels_tbl(data), projection)
  ## TODO: move to data.table, ignore group, just do it by .recording
  long_table <- map_dtr(data$.ica, ~ {
    dt <- .x$mixing_matrix[comp_sel,, drop=FALSE] %>%
      data.table::as.data.table(keep.rownames = TRUE) 
    dt[, .ICA := factor(rn, levels = rn)][ , rn := NULL][]
  },
  .id = ".recording") %>%
    data.table::melt(
      variable.name = ".key",
      id.vars = c(".ICA", ".recording"),
      value.name = ".value"
    )
  long_table[, .key := as.character(.key)]

  long_table <- left_join_dt(long_table, data.table::as.data.table(channels_tbl(data)), by = c(".key" = ".channel")) %>%
    dplyr::group_by(.recording, .ICA)
  
long_table %>%
    eeg_interpolate_tbl() %>%
    dplyr::group_by(.recording, .ICA) %>%
    dplyr::mutate(.value = c(scale(.value, center = standardize, scale = standardize))) %>% 
    dplyr::ungroup() %>%
    plot_topo() +
    ggplot2::facet_wrap(~.recording + .ICA) +
    annotate_head() +
    ggplot2::geom_contour() +
    ggplot2::geom_text(color = "black") +
    ggplot2::theme(legend.position = "none")
}


#' @family plotting functions
#' @family ICA functions
plot_ica <- function(data, ...) {
  UseMethod("plot_ica")
}
#' @inheritParams plot_topo
plot_ica.eeg_ica_lst <- function(data,
                                 samples = 1:4000,
                                 components = 1:16,
                                 eog=c(),
                                 .recording=NULL,
                                 scale_comp = 2,
                                 order = c("var","cor"),
                                 max_sample =2400,
                                 topo_config = list(projection = "polar",standardize= TRUE),
                                 interp_config =list()) {
# to avoid no visible binding for global variable
  cor <- NULL
  var <- NULL
  EOG <- NULL
  cor_t <- NULL
  pvar_t <- NULL
  text <- NULL
  x <- NULL
  y <- NULL
  type <- NULL
  .group <- NULL
  i..final <- NULL
  x..upper <- NULL
  incomplete <- NULL
  
  warning("This is an experimental function, and it might change or dissapear in the future. (Or it might be transformed into a shinyapp)")
  #first filter then this is applied:
  if(!is.null(.recording)){
    data <- dplyr::filter(data, .recording == .recording)
  } else {
    .recording <- segments_tbl(data)$.recording[1]
    message("Using recording: ",.recording)
      data <- dplyr::filter(data, .recording == .recording)
    }

  if (length(eog) == 0) {
    eog <-  sel_ch(data, c(tidyselect::starts_with("eog"), tidyselect::ends_with("eog")))
      #fixtidyselect::vars_select(channel_names(data), c(tidyselect::starts_with("eog"), tidyselect::ends_with("eog")))
    message("EOG channels detected as: ", toString(eog))
  } else {
    eog <-  sel_ch(data, tidyselect::all_of(eog))
  }
    
  message("Calculating the correlation of ICA components with filtered EOG channels...")
  sum <- eeg_ica_summary_tbl(data %>% eeg_filt_band_pass(eog, freq = c(.1, 30)),eog) 
  data.table::setorderv(sum, order, order = -1)
  ICAs <- unique(sum$.ICA)[components] 
  
  sum <- sum[.ICA %in% ICAs]
  
  new_data <- data %>% 
   slice_signal(samples) %>%
    eeg_ica_show(dplyr::one_of(ICAs)) %>%
    ## we select want we want to show:
    dplyr::select(tidyselect::all_of(c(ICAs,eog))) %>%
    dplyr::group_by(.id)%>%  
    dplyr::mutate_at(eog, ~ .- mean(.)) %>%
    dplyr::mutate_if(is_component_dbl, ~ . * scale_comp) 
  
 ampls <- new_data %>%
    plot() + 
    annotate_events()+ 
    ggplot2::theme(legend.position='none')
  
  
  topo <- plot_components(data,ICAs)
  
  c_text <- sum %>%
    dplyr::mutate(cor_t = as.character(round(cor,2)), pvar_t = as.character(round(var*100))) %>%
    dplyr::group_by(.recording, .ICA) %>%
    dplyr::summarize(text = paste0(stringr::str_extract(EOG,"^."),": ", cor_t, collapse ="\n") %>%
                paste0("\n",unique(pvar_t),"%")) %>%
    dplyr::mutate(x=1,y=1,.value= NA, .key = NA) %>% 
    dplyr::left_join(dplyr::distinct(topo$data,.recording,.ICA) %>% 
                       dplyr::mutate(.ICA= as.character(.ICA)),., by =c(".recording",".ICA"))%>%
    dplyr::mutate(.ICA = factor(.ICA, levels = .$.ICA))
  
  topo <-    topo + 
    ggplot2::geom_text(data=c_text, ggplot2::aes(label=text,x=x,y=y), inherit.aes=FALSE) + 
    ggplot2::coord_cartesian(clip=FALSE) + 
    ggplot2::facet_wrap(~.ICA, ncol=4) +
    ggplot2::theme(strip.text=ggplot2::element_text(size=12))
  
  topo$layers[[5]] <- NULL
  
  ## right <- cowplot::plot_grid(topo, legend_p1, ncol=1, rel_heights=c(.8,.2))
  plot <- cowplot::plot_grid(ampls, topo, ncol=2,rel_widths=c(.6,.4))
 plot  
}

#' Arrange ERP plots according to scalp layout
#'
#' Arranges a ggplot so that the facet for each channel appears in its position
#' on the scalp.
#'
#' This function requires two steps: first, a ggplot object must be created with
#' ERPs facetted by channel (`.key`).
#' Then, the ggplot object is called in `plot_in_layout`. The function uses grobs
#' arranged according to .x .y coordinates extracted from the `eeg_lst` object, by
#' default in polar arrangement. The arrangement can be changed with the `projection`
#' argument. White space in the plot can be reduced by changing `ratio`.
#'
#' Additional components such as titles and annotations should be added to the
#' plot object using `+` exactly as you would for [ggplot2::ggplot].
#' Title and legend adjustments will be treated as applying to the
#' whole plot object, while other theme adjustments will be treated as applying
#' to individual facets. x-axis and y-axis labels cannot be added at this stage.
#'
#' @param plot A ggplot object with channels
#'
#' @family plotting functions
#' @family topographic plots and layouts
#' @return A ggplot object
#'
#'
#' @examples
#' library(ggplot2)
#' library(dplyr)
#' 
#' # Create a ggplot object with some grand averaged ERPs
#' ERP_plot <- data_faces_ERPs %>%
#'   # select a few electrodes
#'   select(Fz, FC1, FC2, C3, Cz, C4, CP1, CP2, Pz) %>%
#'   # group by time point and condition
#'   group_by(.sample, condition) %>%
#'   # compute averages
#'   summarize_at(channel_names(.), mean, na.rm = TRUE) %>%
#'   ggplot(aes(x = .time, y = .value)) +
#'   # plot the averaged waveforms
#'   geom_line(aes(color = condition)) +
#'   # facet by channel
#'   facet_wrap(~.key) +
#'   # add a legend and title
#'   theme(legend.position = "bottom") +
#'   ggtitle("ERPs for faces vs non-faces")
#' 
#' # Call the ggplot object with the layout function
#' plot_in_layout(ERP_plot)
#' @export
plot_in_layout <- function(plot, ...) {
  UseMethod("plot_in_layout")
}


#' @param projection Projection type for converting the 3D coordinates of the electrodes into 2d coordinates. Projection types available: "polar" (default), "orthographic", or  "stereographic"
#' @param ratio Ratio of the individual panels
#' @param ... Not in use.
#'
#' @rdname plot_in_layout
#' @export
plot_in_layout.gg <- function(plot, projection = "polar", ratio = c(1, 1), ...) {
  size_x <- ratio[[1]]
  size_y <- ratio[[2]]
  ch_location <- plot$data_channels
  ## if (!"channel" %in% colnames(ch_location)) {
  ##   stop("Channels are missing from the data.")
  ## }
  if (!all(c(".x", ".y", ".z") %in% colnames(ch_location))) {
    stop("Coordinates are missing from the data.")
  }
  plot <- plot + ggplot2::facet_wrap(. ~ .key)
  plot_grob <- ggplot2::ggplotGrob(plot)
  layout <- ggplot2::ggplot_build(plot)$layout$layout

  ## PANEL ROW COL channel SCALE_X SCALE_Y
  ## 1      1   1   1     Fp1       1       1
  ## 2      2   1   2     Fpz       1       1
  ## 3      3   1   3     Fp2       1       1
  ## 4      4   1   4      F7       1       1
  ## 5      5   1   5      F3       1       1
  ## 6      6   1   6      Fz       1       1
  ## 7      7   2   1      F4       1       1

  # The facet in the bottom left has both axis, I'll extract and use everywhere:
  maxrow <- max(layout$ROW) # bottom
  # first I extract the axis and I fill the grob with it.
  axisl <- g_filter(plot_grob, paste0("axis-l-", maxrow, "-1"))
  axisb <- g_filter(plot_grob, paste0("axis-b-1-", maxrow))

  # # then I also extract the labels, which I'll use for each facet
  axes_labels <- g_filter(plot_grob, ".lab-.")

  # This the complete facet with axis
  panel_txt <- paste0("panel-", maxrow, "-1")
  strip_txt <- paste0("strip-t-1-", maxrow)
  axisl_txt <- paste0("axis-l-", maxrow, "-1")
  axisb_txt <- paste0("axis-b-1-", maxrow)
  pattern_txt <- paste0(c(panel_txt, strip_txt, axisl_txt, axisb_txt), collapse = "|")
  full_facet_grob <- g_filter(plot_grob, pattern_txt, trim = TRUE)

  rowsize <- full_facet_grob$heights[3] # bottom
  colsize <- full_facet_grob$widths[1] # left

  # needed for passing checks:
  b <- NULL
  l <- NULL
  # THESE ARE NOT IN ORDER!!!
  panels <- subset(plot_grob$layout, grepl("panel", plot_grob$layout$name)) %>%
    dplyr::arrange(b, l)
  strips <- subset(plot_grob$layout, grepl("strip", plot_grob$layout$name)) %>%
    dplyr::arrange(b, l)

  # won't work for free scales, need to add an if-else inside

  channel_grobs <- purrr::map(layout$.key, function(ch) {
    ## pos <- which(facet_names==ch, arr.ind =  TRUE)
    ch_pos <- layout %>% dplyr::filter(.key == ch)
    # panel_txt <- paste0("panel-", ch_pos$ROW, "-", ch_pos$COL)
    # strip_txt <- paste0("strip-t-", ch_pos$COL, "-", ch_pos$ROW)
    # axisl_txt <- paste0("axis-l-", ch_pos$ROW, "-", ch_pos$COL)
    # axisb_txt <- paste0("axis-b-", ch_pos$COL, "-", ch_pos$ROW)
    # # pattern_txt <- paste0(c(panel_txt,strip_txt,axisl_txt,axisb_txt), collapse = "|")
    # pattern_txt <- paste0(c(panel_txt, strip_txt), collapse = "|")
    # # plot_grob[[1]][[which(plot_grob$layout$name == axisl_txt)]] <- axisl[[1]][[1]]
    # # plot_grob[[1]][[which(plot_grob$layout$name == axisb_txt)]] <- axisb[[1]][[1]]
    pattern_txt <- paste0(panels[ch_pos$PANEL, ]$name, "|", strips[ch_pos$PANEL, ]$name)
    ch_grob <- g_filter(plot_grob, pattern_txt, trim = TRUE) %>%
      gtable::gtable_add_rows(rowsize) %>%
      gtable::gtable_add_grob(axisb[[1]][[1]], 3, 1) %>%
      gtable::gtable_add_cols(colsize, 0) %>%
      gtable::gtable_add_grob(axisl[[1]][[1]], 2, 1)

    #  #if there is no bottom axis, add one:
    #  if(is.null(g_filter(ch_grob,"axis-b")[[1]][[1]]$height)){
    #    ch_grob <- ch_grob %>%
    #     gtable::gtable_add_grob( axisb[[1]][[1]],3,2) %>%
    #     gtable::gtable_add_rows(rowsize)
    #  }
    #  if(is.null(g_filter(ch_grob,"axis-l")[[1]][[1]]$width)){
    #    ch_grob <- ch_grob %>% gtable::gtable_add_grob(axisl[[1]][[1]],2,1) %>%
    #    gtable::gtable_add_cols(colsize,0)
    # }

    ch_grob
  }) %>% stats::setNames(layout$.key)
  # #gtable::gtable_height(ch_grob)
  # grid::heightDetails(ch_grob)
  # grid::heightDetails(ch_grob)
  # ch_grob$widths
  #
  # # grid::heightDetails()
  # grid::grid.newpage()
  # grid::grid.draw(channel_grobs[[4]])
  # grid::grid.draw(ch_grob)
  #
  # Discard facet panels from the original plot:
  rest_grobs <- g_filter_out(plot_grob, "panel|strip-t|axis|xlab|ylab", trim = FALSE)

  # How much larger than the electrode position should the plot be?


  ch_location <- change_coord(ch_location, projection)

  xmin <- min(ch_location$.x, na.rm = TRUE) - 0.3 #* size
  xmax <- max(ch_location$.x, na.rm = TRUE) + 0.3 #* size
  ymin <- min(ch_location$.y, na.rm = TRUE) - 0.3 #* size
  ymax <- max(ch_location$.y, na.rm = TRUE) + 0.3 #* size
  new_plot <- ggplot2::ggplot(
    data.frame(x = c(xmin, xmax), y = c(ymin, ymax)),
    ggplot2::aes_(x = ~x, y = ~y)
  ) +
    ggplot2::geom_blank() +
    ggplot2::scale_x_continuous(limits = c(xmin, xmax), expand = c(0, 0)) +
    ggplot2::scale_y_continuous(limits = c(ymin, ymax), expand = c(0, 0)) +
    ggplot2::theme_void() +
    ggplot2::annotation_custom(rest_grobs,
      xmin = xmin,
      xmax = xmax,
      ymin = ymin,
      ymax = ymax
    )

  for (i in seq_len(length(channel_grobs))) {
    new_coord <- ch_location %>%
      dplyr::filter(.channel == names(channel_grobs)[[i]]) %>%
      dplyr::distinct(.x, .y)
    if (is.na(new_coord$.x) && is.na(new_coord$.y)) {
      new_plot
    } else if (is.na(new_coord$.x) | is.na(new_coord$.y)) {
      warning("X or Y coordinates are missing for electrode ", names(channel_grobs)[[i]])
    } else {
      new_plot <- new_plot + ggplot2::annotation_custom(channel_grobs[[i]],
        xmin = new_coord$.x - .13 * size_x,
        xmax = new_coord$.x + .13 * size_x,
        ymin = new_coord$.y - .13 * size_y,
        ymax = new_coord$.y + .13 * size_y
      )
    }
  }
  new_plot
}


#' Add a head shape to a ggplot
#'
#' Adds the outline of a head and nose to a ggplot.
#'
#' @param size Size of the head
#' @param color Color of the head
#' @param stroke Line thickness
#' @family plotting functions
#' @return A layer for a ggplot
#'
#' @examples
#' library(dplyr)
#' library(ggplot2)
#' 
#' data_faces_ERPs %>%
#'   filter(between(as_time(.sample, unit = "milliseconds"), 100, 200)) %>%
#'   group_by(condition) %>%
#'   summarize_at(channel_names(.), mean, na.rm = TRUE) %>%
#'   plot_topo() +
#'   annotate_head(size = .9, color = "black", stroke = 1)
#' @export
#'
annotate_head <- function(size = 1.1, color = "black", stroke = 1) {
  angle <- NULL # to avoid a note in the checks afterwards:
  head <- dplyr::tibble(
    angle = seq(-pi, pi, length = 50),
    x = sin(angle) * size,
    y = cos(angle) * size
  )
  nose <- dplyr::tibble(
    x = c(size * sin(-pi / 18), 0, size * sin(pi / 18)),
    y = c(size * cos(-pi / 18), 1.15 * size, size * cos(pi / 18))
  )
  list(
    ggplot2::annotate("polygon", x = head$x, y = head$y, color = color, fill = NA, size = 1 * stroke),
    ggplot2::annotate("line", x = nose$x, y = nose$y, color = color, size = 1 * stroke)
  )
}

#' Adds a layer with the events on top of a plot of an eeg_lst.
#'
#' @param data The data to be displayed in this layer. There are three options:
#'               * If NULL, the default, the events table is inherited from the plot data as specified
#'               in the call to ggplot().
#'               * An events table will override the plot events table data.
#'
#' @param alpha new alpha level in 0,1.
#' @return A [`ggplot`][ggplot2::ggplot] layer.
#' @family plotting functions
#' @export
annotate_events <- function(data = NULL, alpha = .2) {
  layer <- ggplot2::geom_rect(
    data = data, alpha = alpha,
    ymin = -Inf, ymax = Inf,
    inherit.aes = FALSE,
    ggplot2::aes(
      xmin = xmin,
      xmax = xmax,
      color = Event,
      fill = Event,
      group = .id
    )
  )
  structure(list(layer = layer), class = "layer_events")
}

ggplot_add.layer_events <- function(object, plot, object_name) {
  if (length(object$layer$data) == 0) {
    events_tbl <- plot$data_events
  } else {
    events_tbl <- object$layer$data
  }
  if(nrow(events_tbl)==0) return(NULL)  #nothing to plot
  info_events <- c(".type", ".description") 
  events_tbl <- data.table::as.data.table(events_tbl)
  events_tbl[, xmin := as_time(.initial) ]
  events_tbl[, xmax := as_time(.final) ]
  events_tbl[, Event := (do.call(paste, c(.SD, sep = "."))), .SDcols = c(info_events)]
  # single events
  segs <- plot$data %>%
    dplyr::select(-.time, -.key, -.value) %>%
    dplyr::distinct()

  events_tbl <- left_join_dt(events_tbl, data.table::as.data.table(segs), by = ".id")
  chs <- list(unique(as.character(plot$data$.key)))
  events_tbl[, .key := lapply(.channel, function(x) as.character(x))]
  events_tbl[is.na(.channel), .key := list(rep(chs, .N))]
  events_tbl <- unnest_dt(events_tbl, .key)

  events_tbl[, .key := factor(.key, levels = levels(plot$data$.key))]

  object$layer$data <- events_tbl
  ggplot2::`%+%`(plot, object$layer)
}


#' Create an ERP plot
#'
#' `ggplot` initializes a ggplot object which takes an `eeg_lst` object as
#' its input data. Layers can then be added in the same way as for a
#' [ggplot2::ggplot] object.
#'
#' If necessary, t will first downsample the `eeg_lst` object so that there is a
#' maximum of 6400 samples. The `eeg_lst` object is then converted to a long-format
#' tibble via [as_tibble]. In this tibble, the `.key` variable is the
#' channel/component name and `.value` its respective amplitude. The sample
#' number (`.sample` in the `eeg_lst` object) is automatically converted to milliseconds
#' to create the variable `.time`. By default, time is plotted on the
#' x-axis and amplitude on the y-axis.
#'
#' To add additional components to the plot such as titles and annotations, simply
#' use the `+` symbol and add layers exactly as you would for [ggplot2::ggplot].
#'
#' @param data An `eeg_lst` object.
#' @inheritParams  ggplot2::ggplot
#' @param max_sample Downsample to approximately 6400 samples by default.
#'
#' @family plotting functions
#' @return A ggplot object
#' @importFrom ggplot2 ggplot
#'
#' @examples
#' library(ggplot2)
#' library(dplyr)
#' # Plot grand averages for selected channels
#' data_faces_ERPs %>%
#'   # select the desired electrodes
#'   select(O1, O2, P7, P8) %>%
#'   ggplot(aes(x = .time, y = .key)) +
#'   # add a grand average wave
#'   stat_summary(
#'     fun.y = "mean", geom = "line", alpha = 1, size = 1.5,
#'     aes(color = condition)
#'   ) +
#'   # facet by channel
#'   facet_wrap(~.key) +
#'   theme(legend.position = "bottom")
ggplot.eeg_lst <- function(data = NULL,
                           mapping = ggplot2::aes(),
                           ...,
                           max_sample = 64000,
                           environment = parent.frame()) {
  df <- try_to_downsample(data, max_sample) %>%
    data.table::as.data.table()

  df[, .key := factor(.key, levels = unique(.key))]
  p <- ggplot2::ggplot(data = df, mapping = mapping, ..., environment = environment)

  p$data_channels <- channels_tbl(data)
  p$data_events <- events_tbl(data)
  p$data_channels <- channels_tbl(data)
  p
}
#'  Eeguana ggplot themes
#'
#' These are complete light themes based on [ggplot2::theme_bw()] which control all non-data display.
#' @return A ggplot theme.
#' @family plotting functions
#' @name theme_eeguana
NULL
# > NULL

#' @rdname theme_eeguana
#' @export
theme_eeguana <- function() {
  ggplot2::`%+replace%`(
    ggplot2::theme_bw(),
    ggplot2::theme(
      #,
      # panel.grid =ggplot2::element_blank(),
      strip.background = ggplot2::element_rect(color = "transparent", fill = "transparent"),
      strip.text.y = ggplot2::element_text(angle = 00),
      panel.spacing = ggplot2::unit(.01, "points"),
      panel.border = ggplot2::element_rect(color = "transparent", fill = "transparent"),
      panel.background = ggplot2::element_rect(fill = "transparent", color ="transparent")
    )
  )
}
#' @rdname theme_eeguana
#' @export
theme_eeguana2 <- function() {
  ggplot2::`%+replace%`(
    theme_eeguana(),
    ggplot2::theme(
      panel.grid = ggplot2::element_line(color = "transparent"),
      axis.ticks = ggplot2::element_line(color = "transparent"),
      axis.text = ggplot2::element_blank(),
      axis.title = ggplot2::element_blank()
    )
  )
}


