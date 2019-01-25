# Copyright 2018 Observational Health Data Sciences and Informatics
#
# This file is part of RadiologyFeatureExtraction
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Data processing setting
#' 
#' @details 
#' This function is for preprocessing fo the data, including normalization, resizing, and dimension concat
#' 
#' @param normalization       method for normalization. 'MinMaxNorm' is min-max normalization
#' @param maxLimit            maximum value for all values of the data
#' @param width
#' @param height
#' @param roiWidth          Region of interest, width. default seq(width)
#' @param roiHeight         Region of interest, height. default seq(height)
#' @param channelDim        An additional dimension for the channel of the image. It there is no channel, it should be NULL
#' @param indexDim           indexDim indicates the index dimension. indexDim should be NULL or an integer. if indexDim is not null, the array will be melted along this specified dimension
#' 
#' @export
SetImageProcessing<-function(normalization=NULL,
                                 maxLimit = NULL,
                                 minLimit = NULL,
                                 width = 28,
                                 height = 28,
                                 roiWidth = NULL,
                                 roiHeight = NULL,
                                 channelDim = NULL,
                                 indexDim = NULL){
    
    if (!class(maxLimit) %in% c("numeric", "NULL", "integer"))
        stop("maxLimit should be NULL or a single numeric value")
    if (  (!class(width) %in% c("numeric", "integer")) &(!class(height) %in% c("numeric", "integer")) )
        stop("width and height should be a single numeric value")
    
    imageProcessingSettings<-list(normalization=normalization,
                                  maxLimit = maxLimit,
                                  minLimit = minLimit,
                                  width = as.integer(width),
                                  height = as.integer(height),
                                  roiWidth = roiWidth,
                                  roiHeight = roiHeight,
                                  channelDim = channelDim,
                                  indexDim = indexDim)
    #attr(imageProcessingSettings,'fun') <- 'imagePreProcessing'
    class(imageProcessingSettings) <- 'imageProcessingSettings'
    return(imageProcessingSettings)
}

#' Pre-processing function for the data
#' 
#' @details 
#' This function is for preprocessing fo the data, including normalization, resizing, and dimension concat
#' 
#' @param x                   An object of data
#' @param imageProcessingSettings       class of imageProcessingSettings
#' 
#' @export
preProcessing<-function(x=NULL,
                        imageProcessingSettings=imageProcessingSettings){
    if(class(imageProcessingSettings) != 'imageProcessingSettings')
        stop("the class of imageProcessingSettings should be imageProcessingSettings generated by imageProcessingSetting function")
    
    if (length(dim(x))+is.null(imageProcessingSettings$channelDim)!=3)
        stop("currently only 2D array")
    
    #loading the setting
    normalization=imageProcessingSettings$normalization
    maxLimit = imageProcessingSettings$maxLimit
    minLimit = imageProcessingSettings$minLimit
    width = imageProcessingSettings$width
    height = imageProcessingSettings$height
    roiWidth = imageProcessingSettings$roiWidth
    roiHeight = imageProcessingSettings$roiHeigh
    channelDim = imageProcessingSettings$channelDim
    
    #resizing
    if ( is.null(roiWidth)) roiWidth<-seq(width)
    if ( is.null(roiHeight)) roiHeight<-seq(height)
    x <- EBImage::resize(x, w = width, h =height)[roiWidth, roiHeight]
    
    #remove NA values in the image
    x[is.na(x)] <- 0
    
    #cap the image to the limit
    if(!is.null(maxLimit)){
        x <- replace(x, x > maxLimit, maxLimit)
        x <- replace(x, x > maxLimit, maxLimit)
    }
    
    if(!is.null(minLimit)){
        x <- replace(x, x < minLimit, minLimit)
        x <- replace(x, x < minLimit, minLimit)
    }
    
    #normalization
    if(normalization =="MinMaxNorm") {
        x<-(x- minLimit)/(maxLimit - minLimit)
    }
    
    return(x)
}


#' melt the dimension of the datda
#' 
#' @details 
#' This function is for preprocessing fo the data, including normalization, resizing, and dimension concat
#' 
#' @param x                             An array object
#' @param imageProcessingSettings       class of imageProcessingSettings
#' 
#' @export
meltDim<-function(x,
                  imageProcessingSettings = imageProcessingSettings,
                  convolution=F){
    
    if(class(imageProcessingSettings) != 'imageProcessingSettings')
        stop("the class of imageProcessingSettings should be imageProcessingSettings generated by imageProcessingSetting function")
    
    indexDim = imageProcessingSettings$indexDim
    channelDim = imageProcessingSettings$channelDim
    
    if(convolution){
        x<-array(unlist(x), dim = c(length(imageProcessingSettings$roiWidth), length(imageProcessingSettings$roiHeight), length(x)))
        if(indexDim==1) x<-aperm(x,c(3,1,2))
        #add additional one dimension for channel
        dim(x)<-c(dim(x),1)
    } else {
        x<-array(unlist(x), dim = c(length(imageProcessingSettings$roiWidth)*length(imageProcessingSettings$roiHeight), length(x)))
        if(indexDim==1) x<-aperm(x,c(2,1))
        # x <- x %>% apply(indexDim, as.numeric) %>% t()
    }
    return(x)
}

#' Reconstruction of the dimenion of the data
#' 
#' @details 
#' This function is for preprocessing fo the data, including normalization, resizing, and dimension concat
#' 
#' @param x                             An object of data
#' @param imageProcessingSettings       imageProcessingSettings
#' 
#' @export
reconDim <- function(x,
                     imageProcessingSettings = imageProcessingSettings,
                     convolution = F){
    if(class(imageProcessingSettings) != 'imageProcessingSettings')
        stop("the class of imageProcessingSettings should be imageProcessingSettings generated by imageProcessingSetting function")
    
    indexDim = imageProcessingSettings$indexDim
    channelDim = imageProcessingSettings$channelDim
    
    if(convolution) {
        dim(x)<-dim(x)[1:3]}else{
            x<-array(unlist(x), dim = c(dim(x)[1], length(imageProcessingSettings$roiWidth), length(imageProcessingSettings$roiHeight)))
        }
    return(x)
}

#' Reverse-processing function for the data
#' 
#' @details 
#' This function is for preprocessing fo the data, including normalization, resizing, and dimension concat
#' 
#' @param x                   An object of data
#' @param normalization       method for normalization. 'MinMaxNorm' is min-max normalization
#' @param dimConcat           dimConcat indicates the index dimension. dimConcat should be NULL or an integer. if dimConcat is not null, the array will be concatenated along this specified dimension
#' 
#' @export
reverseProcessing<-function(x){
    normalization=imageProcessingSettings$normalization
    maxLimit = imageProcessingSettings$maxLimit
    minLimit = imageProcessingSettings$minLimit
    width = imageProcessingSettings$width
    height = imageProcessingSettings$height
    roiWidth = imageProcessingSettings$roiWidth
    roiHeight = imageProcessingSettings$roiHeigh
    indexDim=imageProcessingSettings$indexDim
    
    #reverse normalization
    if(normalization =="MinMaxNorm") {
        x<- x*(maxLimit - minLimit)+minLimit
    }
    return(x)
}

