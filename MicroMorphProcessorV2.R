#author Justin Savage
#js664@duke.edu
#Version 2.0
#10/6/20

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

sourceDir <- selectDirectory(
  caption = "Select Directory",
  label = "Select",
  path = getActiveProject()
)
setwd(sourceDir)

allData <- tibble(
  ImageName = "", 
  BranchLengthPerCell = 0, 
  EndPointsPerCell = 0,
  Sex = "M",
  Side = "L")

currentData <- allData



folders <- list.files()
folders <- folders[grep("outputs", folders)]

i <- 1

for (i in c(1:length(folders))) {
  print(i)
  currentFolder <- folders[i]
  dataFiles <- list.files(currentFolder)
  print(currentFolder)
  
  #############################
  #Step 1
  #############################
  
  currentPath <- str_c(sourceDir, currentFolder, sep = "/")
  branchString <- str_c(currentPath,  dataFiles[grep("Branch", dataFiles)], sep = "/")

  branchInfo <- read.csv(branchString)
  
  resultsString <- str_c(currentPath,  dataFiles[grep("Results", dataFiles)], sep = "/")
  
  results <- read.csv(resultsString)
  
  vols <- list.files(currentFolder, pattern = 'vol_results')
  numCells <- length(vols)
  
  dataOut <- tibble(
    ImageName = "", 
    BranchLengthPerCell = 0, 
    EndPointsPerCell = 0)
  
  #Can't load in data when there were multiple FracLac cells
  #boxCount <- read.csv(dataFiles[grep("Box", dataFiles)])
  #hullCircle <- read.csv(dataFiles[grep("Hull", dataFiles)])
  
  #Set a cutoff value for which all real branches are larger and smaller branches
  #will be excluded
  
  #Duplicate the experiment workbook with the raw data output from skeleton analysis and add TRIM to the filename. 
  #All subsequent data trimming should occur in the duplicated workbook to preserve the raw data for future use and reference.
  #Determine which length of fragments will be trimmed from the dataset by opening the skeletonized image in ImageJ and selecting the Line tool. 
  #Measure several fragments, taking note of the average length, and decide on a cutoff value.
  #NOTE: For the purposes of the data presented here, the cutoff length for undesired fragments is 0.5. 
  #This value should be consistent throughout a dataset.
  #Custom sort the Excel spreadsheet by clicking Sort & Filter | Custom sort. 
  #Sort by "endpoint voxels" from largest to smallest and, in a new level, by "Mx branch pt" from largest to smallest.
  #Remove every row that contains 2 endpoints with a maximum branch length of less than the cutoff value (i.e., 0.5). 
  #Sum the data in the endpoints column to calculate the total number of endpoints collected from the image.
  
  #Repeat for Branch information data: sort by 'branch length' from largest to smallest. 
  #Scroll through the data and remove every row that has a branch length of less than the cutoff value(i.e., 0.5). 
  #Sum the values in the branch length column to calculate the summed length of all branches collected from the image.
  
  #Repeat steps 4.11.3-4.11.5 for every image/sheet until all data have been trimmed and summed.
  #Divide the data from each image (summed number of endpoints and summed branch length) 
  #by the number of microglia somas in the corresponding image. Enter the final data (endpoints/cell & branch length/cell) 
  #into statistical software.
  #NOTE: The summed branch length/cell data may require conversion from length in pixels to microns */
  
  #cutoff <- as.numeric(showPrompt("Cutoff Value", "What is the shortest branch length to count?", default = 2.0))
  cutoff <- 2
  
  results <- filter(results, X..End.point.voxels >= 2)
  results <- filter(results, Maximum.Branch.Length >= cutoff)
  totEndPoints <- sum(results$X..End.point.voxels)
  
  branchInfo <- filter(branchInfo, Branch.length > cutoff)
  totBranchLength <- sum(branchInfo$Branch.length)
  
  #Divide image totals by the number of cells
  #numCells <- as.numeric(showPrompt("Number of Cells", "How many cells were in the image?", default = 2.0))
  
  endPointsPerCell <- totEndPoints/numCells
  branchLengthPerCell <- totBranchLength/numCells
  
  #change so imageName is correct
  tempImageName <- str_split(dataFile, "/")
  tempImageName <- tempImageName[[length(tempImageName)]]
  tempImageName <- tempImageName[length(tempImageName)]
  
  dataOut$ImageName[1] <- tempImageName
  dataOut$BranchLengthPerCell <- branchLengthPerCell
  dataOut$EndPointsPerCell <- endPointsPerCell
  
  outputPath <- str_c(currentPath, "dataOut.csv", sep = "/")
  write.csv(dataOut, outputPath)
  
  
  #############################
  #Step 2
  #############################
  
  #refresh dataFiles to include new dataOut
  #dataFiles <- list.files(currentFolder)
  
  #currentName <- dataFiles[grep("dataOut", dataFiles)]
  #currentPath <- str_c(dataFile, "/" ,currentFolder ,"/",currentName)
  currentData <- dataOut
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

####################
#Analyze Final Data
####################

leftData <- filter(allData, Side == "L")
rightData <- filter(allData, Side == "R")

sideMeans <- tibble(
  Side = c("L", "R"),
  branchMean = c(mean(leftData$BranchLengthPerCell),mean(rightData$BranchLengthPerCell)),
  endpointsMean = c(mean(leftData$EndPointsPerCell),mean(rightData$EndPointsPerCell))
)

sideMeans$branchSD <- 0
pairStDev <- group_by(allData, Side) %>%
  summarize(StDev = sd(BranchLengthPerCell)/length(filter(allData, Side == "L"))) 

sideMeans$branchSD <- pairStDev$StDev

sideMeans$endpointsSD <- 0
pairStDev <- group_by(allData, Side) %>%
  summarize(StDev = sd(EndPointsPerCell)/length(filter(allData, Side == "L"))) 

sideMeans$endpointsSD <- pairStDev$StDev

t.test(formula = BranchLengthPerCell ~ Side, data =allData)

ggplot(allData) + 
  geom_point(mapping = aes(x = Side, y = BranchLengthPerCell)) +
  geom_col(data = sideMeans, mapping = aes(x = Side, y = branchMean, fill = Side), alpha = 0.5) +
  geom_errorbar(data = sideMeans ,mapping = aes(x = Side, ymax = (branchMean+branchSD), ymin = (branchMean-branchSD))) +
  scale_x_discrete(limits = c("L","R"))

ggsave("branchPlot.png", width = 3, height = 5)

t.test(formula = EndPointsPerCell ~ Side, data =allData)

ggplot(allData) + 
  geom_point(mapping = aes(x = Side, y = EndPointsPerCell)) +
  geom_col(data = sideMeans, mapping = aes(x = Side, y = endpointsMean, fill = Side), alpha = 0.5) +
  geom_errorbar(data = sideMeans ,mapping = aes(x = Side, ymax = (endpointsMean+endpointsSD), ymin = (endpointsMean-endpointsSD))) +
  scale_x_discrete(limits = c("L","R"))

ggsave("endpointsPlot.png", width = 3, height = 5)
