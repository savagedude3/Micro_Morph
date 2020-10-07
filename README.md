# Micro_Morph
 
I am writing this ImageJ macro to more easily carry out the microglia morphology analysis described in [Quantifying Microglia Morphology from Photomicrographs of Immunohistochemistry Prepared Tissue Using ImageJ](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6103256/) by Kimberly Young and Helena Morrison.

The basic idea of the process is as follows:

1. Preprocess to remove noise 
1. Threshold the image to separate signal from background
1. Create a skeletonized image that follows all of the branches in the image
1. Analyze the skeletonized image for total branching difference (per image, but not per cell)
1. Isolate single cells on the binarized image (thresholded but not skeletonized)
1. ~~Use the FracLac plugin to analyze the morphology of single cells~~ (took this out for now)

The ImageJ plugin will produce 2 data files from the skeleton analysis and 2 data files from FracLac that can then be analyzed using the [R file](https://github.com/savagedude3/Micro_Morph/blob/master/MicroMorphProcessorV2.R) in this repository.


To actually use the macro you will have to do the following:
1. Download/update [FIJI](https://fiji.sc/)
1. ~~Download the [FracLac plugin](http://rsb.info.nih.gov/ij/plugins/fraclac/Frac_Lac.jar) and put the jar file in your FIJI plugins folder~~ (took this out for now)
1. Open the macro in FIJI using Plugins>Macros>Run and then selecting the [microMorphBatch.ijm](https://github.com/savagedude3/Micro_Morph/blob/master/microMorphBatch.ijm) file from this repo
1. When another file explorer window pops up, select a folder containing all of your image files (they should be Z-stacks or max projections with Iba1 only, you can use something like [cziToTiff.ijm](https://github.com/savagedude3/Micro_Morph/blob/master/cziToTiff.ijm) to convert them)
1. Preprocessing should happen on its own
1. You will be asked the manually threshold the image. This step will take some experimentation and could be replaced by an automated thresholding algorithm in the future.
1. You will be asked to input the minimum cell soma area and circularity that you wish to have counted. You can use the tools in FIJI to measure these things on your image while the dialog box is up.
1. It will then do the analysis of the skeleton images and ask you where you want to save your data files
~~1. The prompt will ask you to draw an ROI around a single cell for FracLac.
1. FracLac will then open and there will be a prompt to give you instructions. Don't click Ok on that prompt until FracLac shows the Box Count Summary chart.~~ (took these out for now)
1. The macro saved all of the important data so you can just close FIJI to get rid of all of the other windows that are open.

To analyze the data:
1.ImageJ made a folder for each of your images which contains a dataOut.csv file that contains the main findings of the analysis. The [R file](https://github.com/savagedude3/Micro_Morph/blob/master/MicroMorphProcessorV2.R) in this repository is a great way to analyze these data.
1. Use cmnd/ctrl + A to select the whole R script within RStudio and click run
1. Any necessary packages should be automatically installed
1. An explorer window will appear and you should select the same folder you selected that has all of your images and the output folders that ImageJ made
1. The script will automatically collate the data into a larger object and try to make comparisons by the side of the image (right or left) and sex of the animal (M or F). These could be easily changed to allow for many interesting comparisons based on any information you include in the original filenames of the images.

This is still very much a work in progress so let me know if you have any problems or suggestions. One easy way to do this is with the [issues tab](https://github.com/savagedude3/Micro_Morph/issues) on this Github page.
