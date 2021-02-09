/*
 * SEGMENTATION AND COLOCALIZATION v.1.1
 * ------------------------------------- 
 *
 *
 * This script segments image channels automatically based on a predefine threshold
 * and calculates a colocalization percentage.
 *
 * -Needs 1 (only 1) multichannel image open to work.
 * -The user can set a number of slices from the center of the z-stack to create a MIP.
 * -The user can choose to use a ROI or quantify the full image.
 * -A colocalization percentage will be calculated at the end.
 * -The script will create a custom table that can be copied to excel.
 * -Results will be saved in a folder of your choosing if box ticked.
 * 
 * Changes in v1.1
 * ---------------
 * -Added option to use only 1 slice instead of MIP.
 * (I plan to add the option for manual thresholding in next version)
 *
 * Federico N. Soria (federico.soria@achucarro.org)
 * July 2020
 */

//CLEAR PREVIOUS RESULTS, ROI AND LOG INFO
run("Collect Garbage");
roiManager("reset");
roiManager("Show None");
print("\\Clear");
run("Clear Results");
run("Options...", "iterations=1 count=1 black");

//INITIALIZATION
if (nImages==0) {
	exit("No images open. Please open an image");
}
name=getTitle();
getDimensions(width, height, channels, slices, frames);
if (channels==1) {
	exit("Image is not multichannel. Please open a multichannel image");
}
getPixelSize(unit, pixelWidth, pixelHeight);
run("Set Measurements...", "area mean limit display redirect=None decimal=3");
setBackgroundColor(0, 0, 0);
setForegroundColor(255, 255, 255);

//GUI DIALOG
ch_list=newArray(channels);
for (i=0; i<channels; i++){
		ch_list[i]=""+i+1+"";
}
thres_list = getList("threshold.methods");
items = newArray("Draw ROI", "Full Image");
Dialog.create("Autosegmentation Script for FIJI");
Dialog.addChoice("Channel for reference ROI", ch_list, "1");
Dialog.addString("Name for ref channel", "Ch1");
Dialog.addChoice("Threshold for ref channel", thres_list, "Default");
Dialog.addMessage("\n");
Dialog.addChoice("Channel for colocalization", ch_list, "2");
Dialog.addString("Name for coloc channel", "Ch2");
Dialog.addChoice("Threshold for coloc channel", thres_list, "Default");
Dialog.addMessage("\n");
Dialog.addSlider("z-stack slices for MIP", 1, slices, (round(slices/2)));
Dialog.addMessage("If you choose 1, the macro will consider only the central slice (no MIP)");
Dialog.addMessage("\n");
Dialog.addRadioButtonGroup("Region of interest", items, 1, 2, "Draw ROI");
Dialog.addCheckbox("Save binary images, values an ROIs to disk?", false);
Dialog.addMessage("\n(c) Federico N. Soria (federico.soria@achucarro.org)\nJuly 2020");
Dialog.show();
ref_ch=Dialog.getChoice();
ref_name=Dialog.getString();
thres_ref=Dialog.getChoice();
coloc_ch=Dialog.getChoice();
coloc_name=Dialog.getString();
thres_coloc=Dialog.getChoice();
s=Dialog.getNumber();
roi=Dialog.getRadioButton();
save_files=Dialog.getCheckbox();


//DIRECTORY CREATION
if (save_files==true) {
	dir=getDirectory("Choose a folder to save Result files.");

	//DIRECTORY FOR IMAGES
	dir_im = dir + "Images" + File.separator;
	if (File.exists(dir_im)==false) {
		File.makeDirectory(dir_im);
	}

	//DIRECTORY FOR VALUES
	dir_val = dir + "Values" + File.separator;
	if (File.exists(dir_val)==false) {
		File.makeDirectory(dir_val);
	}
	
	//DIRECTORY FOR ROIS
	dir_roi = dir + "ROIs" + File.separator;
	if (File.exists(dir_roi)==false) {
		File.makeDirectory(dir_roi);
	}
}

//SUBSTACK AND MIP CREATION
print("Analyzing "+ name + " ...");
run("Select None");
first_slice=round((slices-s)/2);
last_slice=(slices-first_slice);
if ((last_slice-first_slice)>=s)
	last_slice=last_slice-1; 
run("Duplicate...", "duplicate slices="+first_slice+"-"+last_slice+"");
name2=getTitle();
print("Substack created: slices "+first_slice+" to "+last_slice);
selectWindow(name);
run("Close");
selectWindow(name2);
getDimensions(width2, height2, channels2, slices2, frames2);
if (slices2>1) {
	run("Z Project...", "projection=[Max Intensity]");
	print("MIP created.");
}
name_max=getTitle();


//ROI
run("Split Channels");
selectWindow("C"+ref_ch+"-"+name_max);
if (roi=="Draw ROI") {
	setTool("polygon");
	waitForUser("Draw a ROI");	
}
else {
run("Select All");
}
roiManager("Add");
run("Measure");
total_area=getResult("Area", 0);
print("");
print("ROI Area: "+total_area+" "+unit);

//SEGMENTATION REF CHANNEL
selectWindow("C"+ref_ch+"-"+name_max);
roiManager("select", 0);
run("Duplicate...", " ");
rename("BIN_REF");
if (roi=="Draw ROI") {
	run("Clear Outside");
}
run("Select None");
setAutoThreshold(thres_ref+" dark");
showMessageWithCancel("Is the threshold OK?");
run("Measure");
area1=getResult("Area", 1);
print("");
print("Threshold used for "+ref_name+": "+thres_ref);
print("Thresholded area in "+ref_name+": "+area1+" "+unit);
run("Convert to Mask");

//SEGMENTATION COLOC CHANNEL
selectWindow("C"+coloc_ch+"-"+name_max);
roiManager("select", 0);
run("Duplicate...", " ");
rename("BIN_COLOC");
if (roi=="Draw ROI") {
	run("Clear Outside");
}
run("Select None");
setAutoThreshold(thres_coloc+" dark");
showMessageWithCancel("Is the threshold OK?");
run("Measure");
area2=getResult("Area", 2);
print("");
print("Threshold used for "+coloc_name+": "+thres_coloc);
print("Thresholded area in "+coloc_name+": "+area2+" "+unit);
run("Convert to Mask");

//COLOCALIZATION
imageCalculator("AND create", "BIN_REF","BIN_COLOC");
setAutoThreshold("Default dark");
run("Measure");
resetThreshold();
area_coloc=getResult("Area", 3);
per_ref_ch=((area_coloc*100)/area1);
per_coloc_ch=((area_coloc*100)/area2);
print("");
print("Colocalization area: "+area_coloc+" "+unit);
print("Percentage of "+ref_name+" colocalizing with "+coloc_name+": "+per_ref_ch);
print("Percentage of "+coloc_name+" colocalizing with "+ref_name+": "+per_coloc_ch);
run("Tile");

//CUSTOM TABLE
myTable(name,unit,total_area,area1,area2,area_coloc);

function myTable(a,b,c,d,e,f){
	title1="Quantification";
	title2="["+title1+"]";
	if (isOpen(title1)){
   		print(title2, a+"\t"+b+"\t"+c+"\t"+d+"\t"+e+"\t"+f);
	}
	else{
   		run("Table...", "name="+title2+" width=1000 height=300");
   		print(title2, "\\Headings:File\tUnit\tROI Area\t"+ref_name+" Area\t"+coloc_name+" Area\tColocalization Area");
   		print(title2, a+"\t"+b+"\t"+c+"\t"+d+"\t"+e+"\t"+f);
	}
}
waitForUser("Copy Results to Excel");


//SAVE FILES
if (save_files==true) {
	selectWindow("BIN_REF");
	saveAs("tiff", dir_im+File.separator+ref_name+"-"+name);
	
	selectWindow("BIN_COLOC");
	saveAs("tiff", dir_im+File.separator+coloc_name+"-"+name);
	
	selectWindow("Result of BIN_REF");
	saveAs("tiff", dir_im+File.separator+ref_name+"_AND_"+coloc_name+"-"+name);
	
	roiManager("save", dir_roi+"ROI_"+name+".zip");
	
	selectWindow("Log");
	saveAs("Text", dir+File.separator+"LOG_"+name+".txt");
	
	selectWindow("Results");
	saveAs("Results", dir_val+File.separator+"DEFAULT_"+name+".xls");

	selectWindow("Quantification");
	saveAs("Text", dir_val+File.separator+"CUSTOM_"+name+".csv");
	
	print("");
	print("Result files saved in "+dir);
}

//EXIT
close_images = getBoolean("Close all images?");
if (close_images==true) {
	run("Close All");	
}

selectWindow("Quantification");
run("Close");

print("DONE!");
