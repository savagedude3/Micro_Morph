#author Justin Savage
#js664@duke.edu
#Version 1.0
#10/4/20

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

allData <- tibble(
  ImageName = "", 
  BranchLengthPerCell = 0, 
  EndPointsPerCell = 0,
  Sex = "M",
  Side = "L")

currentData <- allData



folders <- list.files()

i <- 1

for (i in c(1:length(folders))) {
  print(i)
  dataFiles <- list.files(folders[i])
  currentFolder <- folders[i]
  print(currentFolder)
  currentName <- dataFiles[grep("dataOut", dataFiles)]
  currentPath <- str_c(dataFile, "/" ,currentFolder ,"/",currentName)
  currentData <- read.csv(currentPath)
  if(length(grep("left", currentFolder)) > 0) {
    currentData$Side <- "L"
  }
  if(length(grep("right", currentFolder)) > 0) {
    currentData$Side <- "R"
  }
  if(length(grep("M", currentFolder)) > 0) {
    currentData$Sex <- "M"
  }
  if(length(grep("F", currentFolder)) > 0) {
    currentData$Sex <- "F"
  }
  
  if (i == 1) {
    allData <- currentData
  }
  if (i > 1) {
    allData <- full_join(allData, currentData)
  }
}

leftData <- filter(allData, Side == "L")
rightData <- filter(allData, Side == "R")

t.test(formula = BranchLengthPerCell ~ Side, data =allData)

