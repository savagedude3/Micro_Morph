#author Justin Savage
#js664@duke.edu
#Version 1.0
#9/12/20

#loaded RStudioAPI to use for selecting working directory
if("rstudioapi" %in% rownames(installed.packages()) == FALSE) 
{install.packages("rstudioapi")}
library(rstudioapi)
if("xlsx" %in% rownames(installed.packages()) == FALSE) 
{install.packages("xlsx")}
library(xlsx)
if("reshape" %in% rownames(installed.packages()) == FALSE) 
{install.packages("reshape")}
library(reshape)
if("data.table" %in% rownames(installed.packages()) == FALSE) 
{install.packages("data.table")}
library(data.table)
if("stringi" %in% rownames(installed.packages()) == FALSE) 
{install.packages("stringi")}
library(stringi)
if("tidyverse" %in% rownames(installed.packages()) == FALSE) 
{install.packages("tidyverse")}
library(tidyverse)

dataFile <- selectDirectory(
  caption = "Select Directory",
  label = "Select",
  path = getActiveProject()
)
setwd(dataFile)

boxFile <- list.files(pattern = 'BoxCount')

boxCount <- read.csv(boxFile[1])





