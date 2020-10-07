dir1 = getDir("Select Source Directory");
list1 = getFileList(dir1);
dir2 = getDir("Select Destination Directory");

setBatchMode(true);

//run("Bio-Formats Importer", "open=" +dir1 + list1[0] + " autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");

for (i = 0; i < list1.length; i++) {

	run("Bio-Formats Importer", "open=[" +dir1 + list1[i] + "] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	title = getTitle();
	print(title);
	splitName = split(title, ".");
	//selectWindow("ACC_10x_overview_section01_1.czi");
	selectWindow(title);
	getDimensions(width, height, channels, slices, frames);
	if(channels > 1){
		run("Split Channels");
		selectWindow("C2-" + title);
		close();
		selectWindow("C3-" + title);
		close();
	}
	selectWindow("C1-" + title);
	saveAs("Tiff", dir2 + splitName[0] + "_green.tif");
	close("*");
}
print("Done");
setBatchMode(false);