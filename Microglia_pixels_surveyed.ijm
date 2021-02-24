/* 
 * PIXELS SURVEYED v2.0
 * --------------------
 * This macro allows to calculate the cumulative area surveyed by a single cell body in time-lapse images.
 * It will generate two excel files with the per-time-point data plus the cumulative data.
 * Binary image stacks (time-lapse) will also be generated.
 * 
 * The macro works with time-lapse images where a single cell is the largest fluorescent body.
 * If more than one cell is present, crop the image before starting the macro.
 * 
 * The image should be drift-corrected if possible 
 * You can use (3D drift correction in hyperstack or StackReg in MIP)
 *
 * Copyright (c) 2020, Federico N. Soria 
 * federico.soria@achucarro.org
 */

//REQUIREMENTS
requires("1.53c");

//Initialization
name=getTitle();
if (nImages==0) {
	exit("Please open an image");
}
if (nImages>1) {
	waitForUser("More than 1 image open. Please close all non-relevant images");
}
run("Histogram", "stack");
rename("Histogram");

//GUI DIALOG
Dialog.create("Pixels Surveyed v2.0");
Dialog.addMessage("Pixels Surveyed 2.0");
Dialog.addMessage("(C) 2020 Federico N. Soria (federico.soria@achucarro.org)");
Dialog.addMessage("This macro allows to quantify the cumulative area occupied by a cell in a time-lapse image. \nThis version needs 1 image already open, preferentially with one cell.");
Dialog.addCheckbox("Create MIP?", false);
Dialog.addCheckbox("Crop image and clean outside cell?", false);
Dialog.addCheckbox("Enhance contrast (For images with low dynamic range)", true);
Dialog.addNumber("      Contrast factor", 5);
Dialog.show();
mip=Dialog.getCheckbox();
crop=Dialog.getCheckbox();
contrast=Dialog.getCheckbox();
contrast_coef=Dialog.getNumber();

selectWindow("Histogram");
run("Close");

//Get info and clear previous data
getDimensions(width, height, channels, slices, frames);
if (frames==1) {
	exit("Image is not a time-lapse image.\n \nPlease open a time-lapse image or switch slices to frames");
}
run("Select None");
run("Clear Results");
roiManager("reset");
run("Set Measurements...", "area limit display redirect=None decimal=2");
print("\\Clear");

//Directory
dir=getDirectory("Choose a Directory to save files");

//MIP creation, resize and contrast
if (mip==true) {
	run("Z Project...", "projection=[Max Intensity] all");
}
if (contrast==true) {
	run("Enhance Contrast", "saturated="+contrast_coef);
	run("Apply LUT", "stack");
}
name_max=getTitle();

//Cropping
if (crop==true) {
	selectWindow(name_max);
	run("Temporal-Color Code", "lut=Red/Green start=1 end="+frames+" create");
	selectWindow("MAX_colored");
	run("Maximize");
	selectWindow("color time scale");
	setTool("polygon");
	waitForUser("Cleaning outside cell", "Draw a precise ROI around the cell and press OK");
	roiManager("add");
	selectWindow("MAX_colored");
	saveAs("Tiff", dir+File.separator+"TIMECOL_"+name_max);
	close();
	selectWindow("color time scale");
	close();
	selectImage(name_max);
	roiManager("select", 0);
	setBackgroundColor(0, 0, 0);
	run("Clear Outside", "stack");
	run("Select None");
	selectWindow(name_max);
	saveAs("Tiff", dir+File.separator+name_max);
	name=getTitle();
}

//Manual thresholding and binarization
var thrs=0;
selectImage(name);
run("Maximize");
Stack.getStatistics(voxelCount, mean, min, max, stdDev);
print("Min Value: "+min+"; Max value: "+max);
run("Threshold...");
waitForUser("Set Threshold", "Set Threshold level using the upper sliding bar \nThen click OK. \n \nDo not press Apply!\nCheck all slices to ensure all processes are connected!");
selectImage(name); 
getThreshold(thrs, upper);
print("Threshold: "+thrs);

run("Convert to Mask", "method=Default background=Dark black");
doCommand("Start Animation");
showMessageWithCancel("Is the binary image OK?");
doCommand("Stop Animation");
saveAs("Tiff", dir+File.separator+"BIN_"+name);
name_bin=getTitle();

//Measure area per frame
setAutoThreshold("Default dark");
for (i=1; i<=frames; i++) {
	Stack.setFrame(i);
	run("Measure");
}
resetThreshold();
saveAs("Results", dir+File.separator+"AREA_PER_FRAME_"+name+".xls");

//Generation of cumulated frames
selectWindow(name_bin);
Stack.setFrame(1);
run("Duplicate...", "title=FRAME_1");
for (i=1; i<=frames; i++) {
	count=i+1;
	selectWindow("FRAME_"+i);
	run("Duplicate...", "title=FRAME_"+count);
	selectWindow(name_bin);
	Stack.setFrame(count);
	imageCalculator("Add", "FRAME_"+count,name_bin);
}

//Close original and BIN windows to allow concatenation
if (isOpen(name)){
	selectWindow(name);
	run("Close");	
}
if (isOpen(name_bin)){
	selectWindow(name_bin);
	run("Close");	
}

//Movie of cumulated frames and area calculation
selectWindow("FRAME_1");
run("Concatenate...", "all_open title=[CUMUL_"+name+"] open");
selectWindow("CUMUL_"+name);
doCommand("Start Animation");
showMessageWithCancel("Is the cumulated binary image OK?");
doCommand("Stop Animation");
saveAs("Tiff", dir+File.separator+"CUMUL_"+name);

//Measure cumulated area
run("Clear Results");
setAutoThreshold("Default dark");
for (i=1; i<=frames; i++) {
	Stack.setFrame(i);
	run("Measure");
}
resetThreshold();
saveAs("Results", dir+File.separator+"CUMUL_AREA_"+name+".xls");

//SAVING LOG AND EXIT
selectWindow("Log");
saveAs("Text", dir+File.separator+"LOG_"+name+".txt");
selectWindow("Results");
run("Close");
run("Close All");
print("DONE!!!");
