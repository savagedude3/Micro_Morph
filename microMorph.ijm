//Microglia Morphology macro for ImageJ

//works for 2D max projection and 3D Z-stacks
//can use Image>Stacks>3D Project to see image or skeleton 

//open() will give a file explorer window to select an image
//I'll probably put the whole macro into a for loop at some point
//so that it can be run on a whole folder of images
open();
//this gets the filepath of the image so we can open it again 
//if we need to
imageDir = getInfo("image.directory") + getInfo("image.filename");


//this gets the name of the image so that we can select it explicitly
//and name other images we'll create with a name that shows they
//came from this image
title = getTitle();
//we duplicate the original image for preprocessing so that
//the original is unaltered
run("Duplicate...", "title=" + title + "_binary duplicate");
//we explicitly select our duplicate for ImageJ to work on
selectWindow(title + "_binary");

//processing for branches

/* Different microscope settings will record different ranges of
 * intensity values. 8-bit means that each pixel in the image
 * is an 8bit byte which is an intensity value with 2^8 possible
 * values (0-255). This may be losing a little bit of information 
 * but will make a lot of our calculations easier and is a common
 * practice. 
 */
run("8-bit");
//This sets the brightness of the image so that 0.1% of the pixels are //saturated without changing the actual intensity values (only how
//ImageJ displays them)
run("Enhance Contrast...", "saturated=0.1");
//Unsharp mask subtracts a gaussian filter from the image
//to help get rid of background
run("Unsharp Mask...", "radius=1 mask=0.20 stack");
//Despeckle is a median filter, replacing each pixel's intensity
//with the median intensity value of its 3x3 neighborhood
run("Despeckle", "stack");
//This is a gaussian blur filter which will change the value
//of each pixel using a kernel that is normally distributed.
//The overall effect is to blur the image
//sigma controls the variance of the gaussian distribution so 
//a higher sigma value is going to blur the image more.
run("Gaussian Blur...", "sigma=3");
//This uses autothresholding to set where the threshold starts at
setAutoThreshold("Default dark");
//This allows the user to set the threshold and waits for the user
//to click ok while also showing some text
run("Threshold...");
waitForUser("Adjust Threshold for Branches");
//This applies the threshold to make a binary image where every 
//pixel at or above your minimum value is set to 255 and every
//value lower than the threshold is set to 0
run("Convert to Mask", "method=Default background=Dark");
run("Despeckle", "stack");
//This dilates and then erodes the image. A pixel is added to 
//each edge and then a pixel is subtracted from each edge.
//This results in merging some edges and can help to fill in
//small wholes in the image.
run("Close-", "stack");
//This does another median filter and will remove a pixel if it
//deviates from its neighbors, removing some noise.
run("Remove Outliers...", "radius=1 threshold=50 which=Bright stack");

selectWindow(title);
run("Duplicate...", "title=" + title + "_somas1 duplicate");
selectWindow(title + "_somas1");

//processing for somas
run("8-bit");
run("Enhance Contrast...", "saturated=0.1");
run("Unsharp Mask...", "radius=1 mask=0.20 stack");
run("Despeckle", "stack");
run("Gaussian Blur...", "sigma=3");
//run("Auto Threshold", "method=Default white stack");
setAutoThreshold("Default dark");
run("Threshold...");
waitForUser("Adjust Threshold so that somas are filled in \n (likely a lower value than you used for branches\)");
// make convert to mask work for stack
run("Convert to Mask", "method=Default background=Dark");
run("Despeckle", "stack");
run("Close-", "stack");
run("Remove Outliers...", "radius=1 threshold=50 which=Bright stack");

//This gets the number of Zstacks or slices in the image
//so we can treat Zstacks and regular images differently
Stack.getDimensions(width, height, channels, slices, frames);
print(slices);

//if it is a Zstack, we want to make a z projection to more easily
//see the cell somas
if(slices > 1){
	run("Z Project...", "projection=[Max Intensity]");
}

//soma detection and measurement in 2D
//can use the ROIs from this method as ROIs for 3D volume analysis
//of Z stack images
run("Duplicate...", "title=" + title + "_somas2 duplicate");
//watershed will use an erosion-like technique to find the middle of
//each object and then draw lines (called watersheds) to separate 
//the object from eachother. This is slightly different than
//the standard watershed algorithm but has the same basic effect.
run("Watershed");
//will only count object larger than minPixel as somas
//This collects the minArea and minCirc values using a dialog box.
//It is common in programming for these to have separate create,
//add and show steps. 
Dialog.create("Soma Segmentation");
Dialog.addMessage("Check that the watershed is correctly segmenting somas \n and measure the minArea and minCircularity you would like to count as a soma");
Dialog.addNumber("Minimum Area", 20);
Dialog.addNumber("Minimum Circularity", 0.3);
Dialog.show();
minArea = Dialog.getNumber();
minCirc = Dialog.getNumber();
//Analyze particles counts each of the distinct particles in the image
//and will make some measurements about them. It will ignore
//objects with areas less than minArea and circularity values
//less than minCirc. Circ = 4pi(area/perimeter^2) and is 1 for a 
//percet circle
run("Analyze Particles...", "size="+ minArea +"-Infinity circularity="+ minCirc +"-1.00 display exclude clear include summarize record add");
//here we pick the results table that analyze particles made so we can
//save it. Most ImageJ functions will have data in a table named 
//"Results"
selectWindow("Results");
//Here we ask the user for a folder to save the results into
dirSave = getDir("pick save destination");
Table.save(dirSave + "somas.csv");
run("Close");
selectWindow(title + "_somas2");
save(dirSave + "somas.tiff");
//Analyze particles saved the outline of the cells it counted 
//into the ROI manager which we can save to use later
roiManager("save", dirSave + "somaROIs.zip");

//3D volume analysis 

selectWindow(title + "_binary");
somaVolumes = newArray(roiManager("count"));

if(slices > 1){
	
	for (i = 0; i < somaVolumes.length; i++){
		roiManager("Select", i);
		measureVol(i);
		selectWindow("Results");
		Table.save(dirSave + title + "_cell_" + i + "_vol_results.csv");
		somaVolumes[i] = processVol();
		Table.reset("Results");
	}
}

if(slices == 1){
	
	for (i = 0; i < somaVolumes.length; i++){
		roiManager("Select", i);
		run("Measure");
		somaVolumes[i] = getResult("Area",0) * getResult("%Area",0);
		selectWindow("Results");
		Table.save(dirSave + title + "_cell_" + i + "_area_results.csv");
		Table.reset("Results");
	}
}

numArray = newArray(somaVolumes.length);
for (i = 0; i < numArray.length; i++) {
	numArray[i] = i;
}


Table.create("volumes");
Table.setColumn("cellNum", numArray);
Table.setColumn("volume", somaVolumes);
Table.save(dirSave + title + "_volumes.csv");
selectWindow("volumes");
run("Close");

roiManager("reset");

//print(somaVolumes[0]);

//setBatchMode("exit and display");
//save?

selectWindow(title + "_binary");
run("Select All");

run("Duplicate...", "title=" + title + "_skeleton duplicate");

run("Skeletonize", "stack");


//Need to optimize skeleton
/* NOTE: It is likely that the image processing will require optimization with the addition or deletion of the above suggested steps. In this process, skeletonized images are assessed for accuracy by creating an overlay of the skeleton and the original image. Somas should be single origin points with processes emanating from the center; circular somas confound the data and should be avoided through protocol adjustment. An example of a single origin point versus circular somas is illustrated in Figure 1.
 *  
Common problems resulting in non-representative skeletons and suggested solutions:
• Image too dim: convert to greyscale, adjust brightness/contrast sliders, and/or apply Unsharp Mask
• Too much background: adjust brightness/contrast sliders, apply Despeckle, and/or Remove outliers
• Circular somas in skeletonized image (particularly for fluorescence images): apply FFT Bandpass filter, and/or Unsharp Mask
• Cracks in tissue (particularly for bright-field images): apply FFT Bandpass filter, and/or Despeckle
*/


selectWindow(title + "_skeleton");
run("Analyze Skeleton (2D/3D)", "prune=none show");

//save "Branch Information" results table
//save "Results" results table

selectWindow("Branch information");
//dirSave = getDir("pick save destination");
Table.save(dirSave + "BranchInfo.csv");
run("Close");
selectWindow("Results");
Table.save(dirSave + "Results.csv");
run("Close");
selectWindow(title + "_skeleton");
save(dirSave + title + "_skeleton.tif");
selectWindow(title + "_binary");
save(dirSave + title + "_binary.tif");


close("*");
selectWindow("Summary");
run("Close");
selectWindow("Log");
run("Close");
selectWindow("Threshold");
run("Close");
selectWindow("ROI Manager");
run("Close");

//get cellNum from outline somehow (if it is total number)

//probably easiest to do the next part in R
//Could write a java plugin?

/*Duplicate the experiment workbook with the raw data output from skeleton analysis and add TRIM to the filename. All subsequent data trimming should occur in the duplicated workbook to preserve the raw data for future use and reference.
 * Determine which length of fragments will be trimmed from the dataset by opening the skeletonized image in ImageJ and selecting the Line tool. Measure several fragments, taking note of the average length, and decide on a cutoff value.
NOTE: For the purposes of the data presented here, the cutoff length for undesired fragments is 0.5. This value should be consistent throughout a dataset.
Custom sort the Excel spreadsheet by clicking Sort & Filter | Custom sort. Sort by "endpoint voxels" from largest to smallest and, in a new level, by "Mx branch pt" from largest to smallest.
Remove every row that contains 2 endpoints with a maximum branch length of less than the cutoff value (i.e., 0.5). Sum the data in the endpoints column to calculate the total number of endpoints collected from the image.
Repeat for Branch information data: sort by 'branch length' from largest to smallest. Scroll through the data and remove every row that has a branch length of less than the cutoff value(i.e., 0.5). Sum the values in the branch length column to calculate the summed length of all branches collected from the image.
Repeat steps 4.11.3-4.11.5 for every image/sheet until all data have been trimmed and summed.
Divide the data from each image (summed number of endpoints and summed branch length) by the number of microglia somas in the corresponding image. Enter the final data (endpoints/cell & branch length/cell) into statistical software.
NOTE: The summed branch length/cell data may require conversion from length in pixels to microns */


//make cell ROIs for fractal analysis

//select cell
cellNum = 1;

open(imageDir);

run("Z Project...", "projection=[Max Intensity]");

//moreCells = getBoolean("Are there more cells you want to analyze with FracLac?");

moreCells = false;

while(moreCells){
	waitForUser("Cell ROI", "Draw a freehand ROI around a cell in the image. Be sure to capture the entire cell in the ROI without any parts of other cells or background");
	
	roiManager("add");

	open(dirSave + title + "_binary.tif");
	
	selectWindow(title+"_binary.tif");
	run("Duplicate...", "title="+ title + "_binary_cell_" + cellNum +" duplicate");
	
	roiManager("Select", 0);
	
	run("Clear Outside", "stack");
	
	//save individual cell
	
	run("Outline", "stack");
	
	//probably need to save cell outlines and then run FracLac's internal
	//batch mode since it can't be run as a script
	
	run("FracLac");
	
	waitForUser("FracLac", "1) Click BC \n 2) In grid design, change Num G to 4 \n 3) In graphics options, check the Metrics box \n 4) Click Ok \n 5) Click Scan \n \n Click Ok when FracLac is finished");
	
	
	/*  1) Click BC
	 *  2) In grid design, change Num G to 4
	 *  3) In graphics options, check the Metrics box
	 *  4) Click Ok
	 *  5) Click Scan
	 */
	
	
	selectWindow("Hull and Circle Results");
	//dirSave = getDir("pick save destination");
	Table.save(dirSave + "HullCircle_"+ cellNum +".csv");
	run("Close");
	selectWindow("Box Count Summary FileFracLac 2015Sep090313a9330");
	Table.save(dirSave + "BoxCountSummary_"+ cellNum +".csv");
	run("Close");
	roiManager("save", dirSave + "cell_" + cellNum + "_ROI.zip");
	roiManager("reset");

	moreCells = getBoolean("Are there more cells you want to analyze with FracLac?");

	if(moreCells == true){
		//reset for next cell
		cellNum = cellNum + 1;
	
		close("*");
	
		run("Close All");
	
		open(imageDir);
	
		run("Z Project...", "projection=[Max Intensity]");
	}
}

close("*");
run("Close All");


function measureVol(roiNum) { 
	// code from https://visikol.com/2018/11/blog-post-loading-and-measurement-of-volumes-in-3d-confocal-image-stacks-with-imagej/
	// Measure Volume of Thresholded Pixels in an Image Stack

	
    run("Clear Results");   // First, clear the results table
  	
   	run("Set Measurements...", "area centroid center perimeter fit shape integrated area_fraction stack limit redirect=None decimal=3"); 				  
   	// loop through each slice in the stack. Start at n=1 (the first slice), 
    // keep going while n <= nSlices (nSlices is the total number of slices in the stack)
    // and increment n by one after each loop (n++)
    for (n=1; n<=nSlices; n++) {  
       setSlice(n);  // set the stack's current slice to n
       run("Measure");   // Run the "Measure" function in ImageJ
       //waitForUser("results?");
    }
}

function processVol() { 
// process the data tables from measureVol to give volume as return

// Create a variable that we will use to store the area measured in each slice
    totalArea = 0;
    depthStart = -1;
    depthEnd = 0;
    // Loop through each result from 0 (the first result on the table) to nResult (the total number of results on the table)
    for (n=0; n < nResults; n++){
    	
       sliceArea = getResult("Area",n) * getResult("%Area",n);
       totalArea += sliceArea;  
       if(sliceArea > 0.5 && depthStart == -1){
       		depthStart = n;
       		depthEnd = n;
       }
       if(sliceArea > 0.5){
       		depthEnd = n;
       }
       
       // Add the area of the current result to the total
    }
   
	print(depthStart + " to " + depthEnd);    
    // Get the calibration information from ImageJ and store into width, height, depth, and unit variables. 
    // We will only be using depth and unit
    getVoxelSize(width, height, depth, unit);
   	//print(depth);
   	 // Calculate the volume by multiplying the sum of area of each slice by the depth

   	 
    trueDepth = (depthEnd - depthStart + 1)/nSlices * depth;
    volume = totalArea*trueDepth;

    print("totalArea: " + totalArea);
    print("trueDepth: " + trueDepth);
    // return the result of the volume calculation
    return(volume);
}

