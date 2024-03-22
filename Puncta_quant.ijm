/* PUNCTA QUANT 1.0
 * ----------------
 * 
 * Optimized for working with 1 channel for segmentation and 1 channel for puncta.
 * 
 * HOW TO USE
 *  1- Open multichannel image.
 *  2- Run macro and follow instructions.
 *  3- Set manual threshold for segmentation channel.
 *  4- Threshold for puncta segmentation is automatic (chosen at GUI).
 *  5- If "save to file" is ON, you will be prompted to choose a directory.
 * 
 * COMMENTS
 * -Area measurements are in calibrated units ONLY if image is calibrated
 * -Puncta size is in pixels
 * 
 * Federico N. Soria (Septiembre 2021) 
 * federico.soria@achucarro.org
 */

requires("1.43f");
run("Collect Garbage");


//INITIALIZATION
if (nImages==0) {
	exit("No images open. Please open an image");
}
if (isOpen("Summary")==true) {
	selectWindow("Summary");
	run("Close");	
}
run("Select None");
run("Clear Results");
roiManager("reset");
run("Set Measurements...", "area limit display redirect=None decimal=2");
setOption("BlackBackground", true);
print("\\Clear");
name=getTitle( );
getDimensions(width, height, channels, slices, frames);


//GUI DIALOG
ch_list=newArray(channels);
for (i=0; i<channels; i++){
		ch_list[i]=""+i+1+"";
}
thres_list = getList("threshold.methods");
Dialog.create("Choose your destiny...");
Dialog.addChoice("Channel for cell segmentation", ch_list, "2");
Dialog.addString("Name for segmentation channel", "NeuN");
Dialog.addMessage("\n");
Dialog.addChoice("Channel for puncta", ch_list, "3");
Dialog.addString("Name for puncta channel", "ApoD");
Dialog.addChoice("Threshold for puncta channel", thres_list, "RenyiEntropy");
Dialog.addNumber("Min puncta size in pixels", 10);
Dialog.addMessage("\n");
Dialog.addCheckbox("Save values to file", true);
Dialog.show();

seg_chan=Dialog.getChoice();
seg_name=Dialog.getString();

puncta_chan=Dialog.getChoice();
puncta_name=Dialog.getString();
puncta_thres=Dialog.getChoice();
puncta_size=Dialog.getNumber();

savetofile=Dialog.getCheckbox();


//DIRECTORY CREATION
if (savetofile==true) {
	dir=getDirectory("Choose Directory to save files");
}


//SPLIT CHANNELS ONLY IF STACK
if (channels>1) {
	run("Split Channels");
}


//SEGMENTATION
run("Measure"); //calculates Total Area
selectWindow("C"+seg_chan+"-"+name);
run("16-bit");
run("Threshold...");
waitForUser("Set Threshold", "Set Threshold level using the upper sliding bar \nThen click OK. \n \nDo not press Apply!");
getThreshold(thrs, upper);
print("Analyzing: "+name+"...");
print("Threshold for cell segmentation: "+thrs);
run("Convert to Mask");
run("Median...", "radius=2"); //cleans speckles 
if (savetofile==true) {
	saveAs("tiff", dir+File.separator+name+"_"+seg_name+"-BIN.tif");
}
run("Create Selection");
roiManager("Add");
if (savetofile==true) {
	roiManager("save", dir+File.separator+name+"_ROI.zip");
}
run("Measure"); //calculates Segmented Area


//PUNCTA
selectWindow("C"+puncta_chan+"-"+name);
run("16-bit");
setAutoThreshold(puncta_thres+" dark");
run("Convert to Mask", "method="+puncta_thres+" background=Dark calculate black"); //binarizes
run("Analyze Particles...", "size="+puncta_size+"-Infinity pixel summarize"); //counts puncta in the WHOLE image
if (savetofile==true) {
	saveAs("tiff", dir+File.separator+name+"_"+puncta_name+"-BIN.tif"); //saves binarized puncta
}
roiManager("Select", 0);
run("Clear Outside"); //deletes puncta outside ROI, i.e. outside segmentation mask
run("Select None");
run("Analyze Particles...", "size="+puncta_size+"-Infinity pixel summarize"); //counts puncta in the ROI
if (savetofile==true) {
	saveAs("tiff", dir+File.separator+name+"_"+puncta_name+"_in_"+seg_name+"-BIN.tif"); //saves binaryzed puncta, ROI only
}


//DATA GATHERING FOR CUSTOM TABLE
total_area=getResult("Area", 0);
area_seg=getResult("Area", 1);
selectWindow("Results");
run("Close");
IJ.renameResults("Summary","Results");
puncta_all=getResult("Count", 0);
puncta_in=getResult("Count", 1);

//CUSTOM TABLE
myTable(name,thrs,total_area,area_seg,puncta_all,puncta_in);

function myTable(a,b,c,d,e,f){
	title1="Quantification";
	title2="["+title1+"]";
	if (isOpen(title1)){
   		print(title2, a+"\t"+b+"\t"+c+"\t"+d+"\t"+e+"\t"+f);
	}
	else{
   		run("Table...", "name="+title2+" width=800 height=500");
   		print(title2, "\\Headings:File\tThreshold used\tTotal Area\t"+seg_name+" Area\tNumber of total "+puncta_name+" puncta\tNumber of "+puncta_name+" in "+seg_name);
   		print(title2, a+"\t"+b+"\t"+c+"\t"+d+"\t"+e+"\t"+f);
	}
}

selectWindow("Quantification");
if (savetofile==true) {
	saveAs("text", dir+File.separator+"Custom_Table.xls"); //saves the custom table, or updates it if it already exists.
}

//END
run("Tile");
waitForUser("Close all windows");
run("Close All");
waitForUser("Copy Results to Excel if needed \n \nCUSTOM TABLE has been updated.");

if (savetofile==true) {
	selectWindow("Log");
	saveAs("Text", dir+File.separator+name+".txt");
	print("Files saved in "+dir);
}
print("FLAWLESS VICTORY!");
print("");


