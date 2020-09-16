
open();

//works for 2D max projection and 3D Z-stacks
//can use Image>Stacks>3D Project to see image or skeleton 

//setBatchMode(true);

title = getTitle();
run("Duplicate...", "title=" + title + "_binary duplicate");
selectWindow(title + "_binary");

run("8-bit");
run("Enhance Contrast...", "saturated=0.1");
run("Unsharp Mask...", "radius=1 mask=0.20 stack");
run("Despeckle", "stack");
run("Gaussian Blur...", "sigma=3");
//run("Auto Threshold", "method=Default white stack");
setAutoThreshold("Default dark");
run("Threshold...");
waitForUser("Adjust Threshold");
// make convert to mask work for stack
run("Convert to Mask");
run("Despeckle", "stack");
run("Close-", "stack");
run("Remove Outliers...", "radius=1 threshold=50 which=Bright stack");

Stack.getDimensions(width, height, channels, slices, frames);
print(slices);

if(slices > 1){
	run("Z Project...", "projection=[Max Intensity]");
}

//soma detection and measurement in 2D
//can use the ROIs from this method as ROIs for 3D volume analysis
//of Z stack images
run("Duplicate...", "title=" + title + "_somas duplicate");
run("Watershed");
//will only count object larger than minPixel as somas
minPixel = 6000;
run("Analyze Particles...", "size="+ minPixel +"-Infinity pixel display exclude clear include summarize record add");
selectWindow("Results");
dirSave = getDir("pick save destination");
Table.save(dirSave + "Somas.csv");
run("Close");


//3D volume analysis 

if(slices > 1){
	
	somaVolumes = newArray(roiManager("count"));
	
	for (i = 0; i < somaVolumes.length; i++){
		roiManager("Select", i);
		somaVolumes[i] = measureVol(i);
	}
}

//print(somaVolumes[0]);

//setBatchMode("exit and display");
//save?

selectWindow(title + "_binary");

run("Duplicate...", "title=" + title + "_skeleton duplicate");

run("Skeletonize", "stack");




//make cell ROIs for fractal analysis

//select cell
cellNum = 1;

selectWindow(title);

run("Z Project...", "projection=[Max Intensity]");

waitForUser("Cell ROI", "Draw a freehand ROI around a cell in the image. Be sure to capture the entire cell in the ROI without any parts of other cells or background");

roiManager("add");

selectWindow(title+"_binary");
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
dirSave = getDir("pick save destination");
Table.save(dirSave + "HullCircle.csv");
run("Close");
selectWindow("Box Count Summary FileFracLac 2015Sep090313a9330");
Table.save(dirSave + "BoxCountSummary.csv");
run("Close");


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
dirSave = getDir("pick save destination");
Table.save(dirSave + "BranchInfo.csv");
run("Close");
selectWindow("Results");
Table.save(dirSave + "Results.csv");
run("Close");
close("*");

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

function measureVol(roiNum) { 
// code from https://visikol.com/2018/11/blog-post-loading-and-measurement-of-volumes-in-3d-confocal-image-stacks-with-imagej/
// Measure Volume of Thresholded Pixels in an Image Stack
//
//
    run("Clear Results");   // First, clear the results table
  	
   	run("Set Measurements...", "area centroid center perimeter fit shape integrated area_fraction stack limit redirect=None decimal=3"); // loop through each slice in the stack. Start at n=1 (the first slice), 
    // keep going while n <= nSlices (nSlices is the total number of slices in the stack)
    // and increment n by one after each loop (n++)
    for (n=1; n<=nSlices; n++) {  
       setSlice(n);  // set the stack's current slice to n
       run("Measure");   // Run the "Measure" function in ImageJ
    }

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
