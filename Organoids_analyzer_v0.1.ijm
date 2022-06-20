/*
 * ORGANOIDS ANALYZER 0.1
 * ----------------------
 * 
 * This macro will help you segment a brightfield image 
 * of a brain organoid (or any roundish object) and analyze its shape.
 * Object must have sufficient contrast against background.
 * 
 * It will create a binary image of the segmented object
 * in the same folder as the input image.
 * 
 * Shape descriptors:
 * -Area (in calibrated units, squared) 
 * -Major (maximum diameter in calibrated units)
 * -Circularity (former "Form Factor", where perfect circle = 1)
 * -AR (Aspect ratio: higher means more elongated)
 * -Roundness (inverse to aspect ratio: closer to 1 means round)
 * -Solidity (area vs convex area, it is a measure of shape complexity) 
 * 
 * For detailed info on shape descriptors...
 * https://imagej.nih.gov/ij/docs/guide/146-30.html#toc-Subsection-30.7
 *
 * 
 * federico.soria@achucarro.org
 * June 2022
 */

//Initialization
run("Options...", "iterations=1 count=1 black do=Nothing");
setForegroundColor(255, 255, 255);
setBackgroundColor(0, 0, 0);
run("Set Measurements...", "area fit shape display redirect=None decimal=3");
name=getTitle();
dir=getDirectory("image");

//Segmentation and processing
run("Duplicate...", " ");
run("Invert");
run("8-bit");
setAutoThreshold("Minimum dark");
run("Threshold...");
waitForUser("Adjust threshold and press OK (do not press APPLY)");
setOption("BlackBackground", true);
run("Convert to Mask");
setTool("freehand");
waitForUser("Draw a selection around the object(s)"); //if more than one object, encircle both
run("Clear Outside");
run("Crop");
run("Select None");
run("Fill Holes"); //this is to fill holes mostly in epithelial buds
run("Median...", "radius=2"); //this is to smooth the border
waitForUser("Binary OK? (you can use brush to fix)");
save_and_cont=getBoolean("Save binary image and analyze it?");
if (save_and_cont==true) {
	saveAs("Tiff", dir+"BIN_"+name);
}
if (save_and_cont==false) {
	run("Close All");
	exit("Macro was stopped by the user. No image saved.");
}

//Analysis
setAutoThreshold("Default dark");
run("Analyze Particles...", "size=1000-Infinity pixel show=[Overlay Masks] display exclude"); //size can be adjusted
resetThreshold();

//Exit
selectWindow("Results");
waitForUser("Copy results to spreadsheet and then press OK.");
run("Close All");