#' init_dtcurve
#' 
#' expand depth and time to a dtcurve data.frame 
#' 
#' @param depth Depth of the dive in meter. Need to be positive values.
#' A single value will result in square dive.
#' @param time Duration of the dive in minute. Need to be positive values.
#' A single value will result in square dive.
#' @param ascent_speed Ascent_speed in meter/minute. 10 m/min by default. 
#' Most dive table advice to limite this speed to 20M/min maximum.
#' @param way If the dive is one way (one way : 'OW') or if the diver return by 
#' the same depth (way back : 'WB'). 
#'
#' @author Jaunatre Maxime <maxime.jaunatre@yahoo.fr>
#'
#' @export
init_dtcurve <- function(depth, time, ascent_speed = 10, way = c("OW", "WB")) {
  #### IDIOT PROOF ####
  if (any(depth < 0) | !is.numeric(depth)) {
    stop("depth must be positive numeric value(s).")
  }
  if (any(time < 0) | !is.numeric(time)) {
    stop("time must be positive numeric value(s).")
  }
  if (any(time != sort(time))) {
    stop("time values need to be sorted, you don't own a subaquatic dolorean")
  }
  if (any(ascent_speed <= 0) | !is.numeric(ascent_speed) |
    length(ascent_speed) > 1) {
    stop("ascent_speed must be a single positive numeric value(s).")
  }

  way <- match.arg(way)

  if (length(depth) != length(time)) {
    stop("depth and time must be of same length")
  }

  if (length(depth) == 1) {
    # square profile
    if (depth > 6) { # ascent speed above 6m is 6m/min
      ascent_time <- ((depth - 6) / ascent_speed) + 1
    } else {
      ascent_time <- depth / 6
    }
    dtcurve <- data.frame(
      depth = c(0, depth, depth, 0),
      time = c(0, 0, time, time + ascent_time)
    )
  } else {
    # check if origin point
    if(time[1] > 0 | depth[1] > 0){
      time <- c(0, time)
      depth <- c(0, depth)
    }
    # way of the dive
    if (way == "WB") {
      depth <- c(depth, rev(depth)[-1])
      time <- c(time, cumsum(c(tail(time, 1), rev(diff(time))))[-1] )
    }
    # make df
    dtcurve <- data.frame(depth = depth, time = time)
    # 
    # if (sum(dtcurve[1, ]) > 0) {
    #   dtcurve <- rbind(c(0, 0), dtcurve)
    # }
    # check for end point
    if (tail(dtcurve$depth, 1) > 0) {
      tmp_d <- tail(dtcurve$depth, 1)
      if (tmp_d > 6) { # ascent speed above 6m is 6m/min
        ascent_time <- ((tmp_d - 6) / ascent_speed) + 1
      } else {
        ascent_time <- tmp_d / 6
      }
      dtcurve <- rbind(dtcurve, c(0, tail(dtcurve$time, 1) + ascent_time))
    }
  }
  return(dtcurve)
}


#' add_desat
#' 
#' Add the desaturation stops to the dive curve. It also check if there is no
#' depth point higher and before the stops, to prevent accidents.
#' 
#' @param dtcurve a depth time curve in a data.frame with 2 columns depth and 
#' time. Depths values are meters (positive values) and time is in minute.
#' @param desat a desat object that contain the desaturation stops of given dive
#' @param ascent_speed Ascent_speed in meter/minute. 10 m/min by default. 
#' Most dive table advice to limite this speed to 20M/min maximum.
#' @param secu security decompression stop of 3 min at 3 m. FALSE by default.
#'
#' @return a dtcurve data.frame with the same format, but desaturation stop have
#' been rbinded at the end.
#'
#' @author Jaunatre Maxime <maxime.jaunatre@yahoo.fr>
#'
#' @export
add_desat <- function(dtcurve, desat, ascent_speed = 10, secu = FALSE) {
  #### IDIOT PROOF ####
  if (!inherits(dtcurve, 'data.frame') | any(is.na(dtcurve)) | 
      any(colnames(dtcurve) != c('depth', 'time'))){
    stop(paste('dtcurve must be a data.frame with 2 columns named',
               'depth and time without any NA value'))
  }
  if (any(dtcurve$depth < 0) | !is.numeric(dtcurve$depth)) {
    stop("depth must be positive numeric value(s).")
  }
  if (any(dtcurve$time < 0) | !is.numeric(dtcurve$time)) {
    stop("time must be positive numeric value(s).")
  }
  if (any(dtcurve$time != sort(dtcurve$time))) {
    stop("time values need to be sorted, you don't own a subaquatic dolorean")
  }
  
  if(!is.desat(desat)){
    stop("desat must be of class desat made with desat_model function")
  }
  
  if (any(ascent_speed <= 0) | !is.numeric(ascent_speed) |
      length(ascent_speed) > 1) {
    stop("ascent_speed must be a single positive numeric value(s).")
  }
  if( !is.logical(secu) | is.na(secu) )
    stop('secu must be TRUE or FALSE')
  
  # adding security desat
  if(secu){
    depths <- desat$desat_stop$depth
    if(3 %in% depths){
      desat$desat_stop$time[depths==3] <- desat$desat_stop$time[depths==3] + 3
    } else {
      desat$desat_stop <- rbind(desat$desat_stop, m3 = data.frame(depth = 3, time = 3, 
                                                  hour = NA))
    }
  }
  
  
  
  # if(all(is.na(desat$desat_table))){ # in case time specified
  dtcurve <- dtcurve[-nrow(dtcurve),]
  for(i in 1:nrow(desat$desat_stop)){
    if(desat$desat_stop$time[i] > 0){ 
      last_p <- unlist(dtcurve[nrow(dtcurve),])
      beg_depth <- end_depth <- desat$desat_stop$depth[i]
      begtime <- last_p["time"] + abs(last_p["depth"] - beg_depth) / ascent_speed
      endtime <- begtime + desat$desat_stop$time[i]
      # now ascent_speed restricted to 6m.
      if(ascent_speed > 6){
        ascent_speed <- 6
      }
      # add desat stop
      dtcurve <- rbind(dtcurve, data.frame(depth = c(beg_depth, end_depth),
                                           time = c(begtime, endtime)))
    }
  }
  # add last point to surface
  last_p <- unlist(dtcurve[nrow(dtcurve),])
  surf <- last_p["time"] + (last_p["depth"]) / ascent_speed
  dtcurve <- rbind(dtcurve, data.frame(depth = 0,
                                       time = surf))
  # } else { # in case time specified
  # }
  row.names(dtcurve) <- 1:nrow(dtcurve)
  
  return(dtcurve)
}


#' minute_to_time
#'
#' Transform minute variable into a character string in hour format.
#'
#' @param time positive numeric value in minute
#' @param sec add the sec part of the string. 
#' @param sep ':' by default, choice between ':' and 'h'. Only affect only the
#' first separator character
#' @param day TRUE by default, allow to set time in a day period (betwwen 00h00 
#' and 23:59)
#' 
#' @return character string
#' 
#' @examples 
#' minute_to_time(130.5, sec = TRUE)
#' minute_to_time(130.5, sec = FALSE)
#' minute_to_time(130.5, sec = TRUE, sep = 'h')
#' minute_to_time(130.5, sec = FALSE, sep = 'h')
#' minute_to_time(1440, sec = FALSE, sep = 'h')
#' minute_to_time(1664, sec = FALSE, sep = 'h')
#'
#' @author Jaunatre Maxime <maxime.jaunatre@yahoo.fr>
#'
#' @export
minute_to_time <- function(time, sec = TRUE, sep = c(':', 'h'), day = TRUE){
  #### IDIOT PROOF ####
  if (any(time < 0) | !is.numeric(time)) {
    stop("time must be positive numeric value.")
  }
  if( !is.logical(sec) | is.na(sec) ){
    stop('sec must be TRUE or FALSE',call. = interactive())
  }
  sep <- match.arg(sep)
  if( !is.logical(day) | is.na(day) ){
    stop('day must be TRUE or FALSE',call. = interactive())
  }
  
  while(any(time >= 1440) & day){
    time[time >= 1440 ] <- time[time >= 1440] - 1440
  }
  
  if(sec){
    res = sprintf("%02.0f%s%02.0f:%02.0f", time %/% 60, sep, time %% 60, 
                  (time %% 60 %% 1) * 60 )
  } else {
    res = sprintf("%02.0f%s%02.0f", time %/% 60, sep, time %% 60)
  }
  return(res)
}