# Micro_Morph
 
I am writing this ImageJ macro to more easily carry out the microglia morphology analysis described in [Quantifying Microglia Morphology from Photomicrographs of Immunohistochemistry Prepared Tissue Using ImageJ](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6103256/) by Kimberly Young and Helena Morrison.

The basic idea of the process is as follows:

1. Preprocess to remove noise 
2. Threshold the image to separate signal from background
3. Create a skeletonized image that follows all of the branches in the image
4. Analyze the skeletonized image for total branching difference (per image, but not per cell)
5. Isolate single cells on the binarized image (thresholded but not skeletonized)
6. Use the FracLac plugin to analyze the morphology of single cells

The ImageJ plugin will produce 2 data files from the skeleton analysis and 2 data files from FracLac that can then be analyzed using the R file in this repository (once I finish writing it).

To actually use the macro you will have to do the following:
1. Download/update FIJI
2. Download the [FracLac plugin](http://rsb.info.nih.gov/ij/plugins/fraclac/Frac_Lac.jar) and put the jar file in your FIJI plugins folder
3. Open the macro in FIJI using Plugins>Macros>Run and then selecting the micro_morph.ijm file from this repo
4. When another file explorer window pops up, select your image file (it should be a Z-stack or max projection with Iba1 only)
5. Preprocessing should happen on its own
6. The prompt will ask you to draw an ROI around a single cell for FracLac. I've only got this to let you pick 1 cell per image now, but I will fix it so you pick more later on.
7. FracLac will then open and there will be a prompt to give you instructions. Don't click Ok on that prompt until FracLac shows the Box Count Summary chart.
8. After you click Ok, the file explorer will ask where you want to save your data files.
9. It will then do the analysis of the skeleton images and ask you where you want to save those data files as well.
10. The macro saved all of the important data in steps 8 and 9 so you can just close FIJI to get rid of all of the other windows that are open. I also haven't written anything for it to save the intermediate images for future reference, but will add that soon.

This is still very much a work in progress so let me know if you have any problems or suggestions. One easy way to do this is with the issues tab on this Github page.
