/*
 * Puncta Quant ("Multiple Slices" version)
 * ----------------------------------------
 * 
 * This macro was modified from Puncta_quant.ijm 
 * (https://github.com/SoriaFN/Tools)
 * 
 * This macro is intended for multichannel (3+ channels) fluorescence image stacks (3+ slices).
 * It will segment a particular cell type based on a cytoplasmic marker (Iba1, GFAP, etc)
 * and it will quantify number, size and fluorescence intensity of puncta (LCR, LAMP, CatD, etc)
 * within the cellular ROI (i.e. within the cell type of interest, e.g. Microglia).
 * 
 * The lysosome puncta quantification will be done in specific slices of a z-stack.
 * You have to specify the thresholds to be used and the slices to be used (3 slices).
 * 
 * If Difference of Gaussians filter is used (recommended), the filtered image will be used to create
 * the mask, but the Mean Gray Value (MGV) quantification of each punctum will be calculated in  
 * the original unfiltered image.
 * 
 * The QUANTIFICATION table will render the cell area ON THE TOP, and then the size and MGV of each punctum.
 * The SUMMARY table will render summarized data on each puncta and their absolute colocalization. 
 * 
 * If the "Save to disk" option is used, the macro will save all images created, ROIs, and tables.
 * You can use the ROI files (ZIP) to manually check the lysosomes found.
 * 
 * Please cite the macro (including the Github repository) if you use it in your paper.
 * 
 * Federico N. Soria 2024
 * ACHUCARRO BASQUE CENTER FOR NEUROSCIENCE
 */

//INITIALIZATION
requires("1.54i");
run("Clear Results");
print("\\Clear"); //Clears the log
run("Options...", "iterations=1 count=1 black"); //Signal is white, background is black
run("Set Measurements...", "area mean limit display redirect=None decimal=2");
roiManager("reset"); //wipes the ROI manager
name=getTitle();
getDimensions(width, height, channels, slices, frames);
print("Number of channels= "+channels);
print("Number of slices= "+slices);
print("Analyzing... "+name);
if (channels < 3){
	exit("Image has less than 3 channels (macro is intended for 3 channels minimum");
}
if (slices < 3){
	exit("Image has less than 3 slices (macro is intended for z-stacks");
}

//UNITS
getPixelSize(unit, pixelWidth, pixelHeight);
if (unit != "pixels"){
     print ("pixel size = "+ pixelWidth +" "+unit);
    } else print("Image is not spatially calibrated");
    
//GUI
ch_list=newArray(channels);
for (i=0; i<channels; i++){
		ch_list[i]=""+i+1+"";
}
slice_list=newArray(slices);
for (i=0; i<slices; i++){
		slice_list[i]=""+i+1+"";
}
thres_list = getList("threshold.methods");
Dialog.create("Puncta Quantification");
Dialog.addChoice("Channel for reference (cell) ROI", ch_list, "1");
Dialog.addString("Name for ref channel", "Microglia");
Dialog.addMessage("\n");
Dialog.addChoice("Channel for Colocalization-1", ch_list, "2");
Dialog.addString("Name for coloc channel", "LC3");
Dialog.addChoice("Threshold for this channel", thres_list, "Moments");
Dialog.addMessage("\n");
Dialog.addChoice("Channel for Colocalization-2", ch_list, "3");
Dialog.addString("Name for coloc channel", "LAMP");
Dialog.addChoice("Threshold for this channel", thres_list, "Moments");
Dialog.addMessage("\n");
Dialog.addChoice("Slice 1 for quantification", slice_list, "5");
Dialog.addChoice("Slice 2 for quantification", slice_list, "15");
Dialog.addChoice("Slice 3 for quantification", slice_list, "25");
Dialog.addNumber("Size of punctum in pixels", 10);
Dialog.addCheckbox("Use Difference_of_Gaussians filter to clean image (recommended)?", true);
Dialog.addCheckbox("Save binary images, values an ROIs to disk?", true);
Dialog.show();
ref_ch=Dialog.getChoice();
ref_name=Dialog.getString();
coloc1_ch=Dialog.getChoice();
coloc1_name=Dialog.getString();
coloc1_thres=Dialog.getChoice();
coloc2_ch=Dialog.getChoice();
coloc2_name=Dialog.getString();
coloc2_thres=Dialog.getChoice();
slice1=Dialog.getChoice();
slice2=Dialog.getChoice();
slice3=Dialog.getChoice();
punctum_size=Dialog.getNumber();
dog=Dialog.getCheckbox();
save_files=Dialog.getCheckbox();

//CREATE DIRECTORY
if (save_files==true) {
	dir=getDirectory("Choose a folder to save files");
	path=dir+File.separator+name;
	if (File.exists(path)==false) {
		File.makeDirectory(path);
	}
	print("Results will be saved in "+path);
}
  
//DIFFERENCE OF GAUSSIANS FILTER
if (dog==true) {
	selectWindow(name);
	difgaus();
		if (save_files==true) {
		saveAs("tiff", path+File.separator+name+"_FILTERED");
		name2=getTitle();
	}
} else {
	run("Duplicate...", "duplicate");
	name2=getTitle();
}

//CELL SEGMENTATION
selectWindow(name2);
run("Split Channels");
selectWindow("C"+ref_ch+"-"+name2);
run("Duplicate...", "title=CELL-BIN duplicate");
run("Z Project...", "projection=[Max Intensity]"); //this will create a maximal projection, to ensure getting lysosomes in all z-layers.
selectWindow("MAX_CELL-BIN");
run("Threshold...");
setAutoThreshold("Default dark"); 
waitForUser("Set Threshold", "Set Threshold level using the upper sliding bar \nThen click OK. \n \nDo not press Apply!\nCheck all slices to ensure all processes are connected!");
getThreshold(thrs, upper);
print("Threshold for cell segmentation: "+thrs);
run("Convert to Mask");
run("Median...", "radius=2");

//CELL ROI
selectWindow("MAX_CELL-BIN");
setAutoThreshold("Default dark");
run("Create Selection");
roiManager("Add");
if (save_files==true) {
	roiManager("save", path+File.separator+name2+"-CELL_ROI.zip");
}
run("Measure"); //measures the area of CELL in the maximal projection
area_mg=getResult("Area", 0);
myTable(name,ref_name,area_mg,unit,"N/A");
run("Select None");

//CH2 (LC3) SEGMENTATION
selectWindow("C"+coloc1_ch+"-"+name2);
run("Duplicate...", "title="+coloc1_name+" duplicate");
roiManager("Select", 0);
run("Clear Outside", "stack");
run("Select None");
selectWindow(coloc1_name);
setAutoThreshold(coloc1_thres+" dark");
run("Convert to Mask", "method="+coloc1_thres+" background=Dark calculate black");
run("Watershed", "stack");

//CH3 (LAMP1) SEGMENTATION
selectWindow("C"+coloc2_ch+"-"+name2);
run("Duplicate...", "title="+coloc2_name+" duplicate");
roiManager("Select", 0);
run("Clear Outside", "stack");
run("Select None");
selectWindow(coloc2_name);
setAutoThreshold(coloc2_thres+" dark");
run("Convert to Mask", "method="+coloc2_thres+" background=Dark calculate black");
run("Watershed", "stack");

//SLICES SELECTOR
print("Slices used for puncta quantification= "+slice1+", "+slice2+", "+slice3);

//CH2 PUNCTA QUANTIFICATION
print("Quantifying PUNCTA...");
selectWindow(coloc1_name);
puncta (coloc1_ch, coloc1_name, slice1, punctum_size);
selectWindow(coloc1_name);
puncta (coloc1_ch, coloc1_name, slice2, punctum_size);
selectWindow(coloc1_name);
puncta (coloc1_ch, coloc1_name, slice3, punctum_size);

//CH3 PUNCTA QUANTIFICATION
selectWindow(coloc2_name);
puncta (coloc2_ch, coloc2_name, slice1, punctum_size);
selectWindow(coloc2_name);
puncta (coloc2_ch, coloc2_name, slice2, punctum_size);
selectWindow(coloc2_name);
puncta (coloc2_ch, coloc2_name, slice3, punctum_size);
print("\\Update:Puncta Quantification DONE.");

//COLOCALIZACION
coloc(slice1, slice2, slice3, punctum_size);

//SAVE REMAINING FILES
if (save_files==true) {
	selectWindow("MAX_CELL-BIN");
	saveAs("tiff", path+File.separator+name2+"_"+ref_name);
	selectWindow(coloc1_name);
	saveAs("tiff", path+File.separator+name+"_"+coloc1_name);
	selectWindow(coloc2_name);
	saveAs("tiff", path+File.separator+name+"_"+coloc2_name);
	selectWindow("Quantification");
	saveAs("text", path+File.separator+"Table_"+name+".xls");
	selectWindow("Summary");
	saveAs("text", path+File.separator+"Summary_"+name+".xls");
	selectWindow("Log");
	saveAs("text", path+File.separator+"Log_"+name+".txt");
}

//END
run("Tile");
waitForUser("Close all windows");
run("Close All");
selectWindow("Results");
run("Close");
waitForUser("SUMMARY contains summarized puncta and colocalization data.\n \nQUANTIFICATION (Table) contains individual puncta data.\n \nLOG contains parameters used for quantification");
print("MACRO FINISHED!");

//FUNCTIONS
//FUNCTION FOR PUNCTA QUANTIFICATION
function puncta (ch, ch_name, slice, min_size){
	run("Clear Results");
	selectWindow(ch_name);
	Stack.setSlice(slice);
	run("Duplicate...", "use");
	rename(ch_name+"-S"+slice);
	name_with_slice_n=name+"_"+ch_name+"-S"+slice;
	roiManager("reset");
	run("Analyze Particles...", "size="+min_size+"-Infinity display add pixel summarize");
	n = roiManager("Count");
	if (save_files==true) {
		roiManager("save", path+File.separator+name2+"-PUNCTA_ROI-"+ch_name+"-S"+slice+".zip");
	}
	for (i=0; i<n; i++) { //quantifies area and fluo and sends to custom table
		area_puncta=getResult("Area", i);
		selectWindow(name);
		Stack.setChannel(ch);
		Stack.setSlice(slice);
		roiManager("deselect");
		roiManager("Select", i);
		run("Measure");
		mgv=getResult("Mean", (i+n));
		run("Select None");
		myTable(name_with_slice_n,ch_name,area_puncta,unit,mgv);
	}
}

//FUNCTION FOR COLOCALIZATION
function coloc (s1, s2, s3, min_size){
	imageCalculator("AND create", coloc1_name+"-S"+s1, coloc2_name+"-S"+s1);
	rename("COLOC-S"+s1);
	run("Analyze Particles...", "size="+min_size+"-Infinity pixel summarize");

	imageCalculator("AND create", coloc1_name+"-S"+s2, coloc2_name+"-S"+s2);
	rename("COLOC-S"+s2);
	run("Analyze Particles...", "size="+min_size+"-Infinity pixel summarize");

	imageCalculator("AND create", coloc1_name+"-S"+s3, coloc2_name+"-S"+s3);
	rename("COLOC-S"+s3);
	run("Analyze Particles...", "size="+min_size+"-Infinity pixel summarize");
}

//FUNCTION FOR TABLE
function myTable(a,b,c,d,e){
	title1="Quantification";
	title2="["+title1+"]";
	if (isOpen(title1)){
   		print(title2, a+"\t"+b+"\t"+c+"\t"+d+"\t"+e);
	}
	else{
   		run("Table...", "name="+title2+" width=800 height=800");
   		print(title2, "\\Headings:File\tLabel\tArea\tUnit\tIntensity (MGV)");
   		print(title2, a+"\t"+b+"\t"+c+"\t"+d+"\t"+e);
	}
}

//FUNCTION FOR FILTERING
function difgaus() {
	name_dog=getTitle();
	print("Filtering in progress...");
	selectWindow(name_dog);
	run("Grays");
	run("Duplicate...", "title=min duplicate");
	run("Gaussian Blur...", "sigma=1 stack"); //you can play with the sigma number to get different results
	selectWindow(name_dog);
	run("Duplicate...", "title=max duplicate");
	run("Gaussian Blur...", "sigma=50 stack"); //you can play with the sigma number to get different results
	imageCalculator("Subtract stack", "min","max");
	selectWindow("max");
	close();
	selectWindow("min");
	run("Enhance Contrast", "saturated=0.35");
	rename(name_dog+"_DOG");
	print("\\Update:Filtering DONE");
}
