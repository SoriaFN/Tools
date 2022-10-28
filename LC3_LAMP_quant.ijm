/*
 * LC3-LAMP Quant for SIERRA LAB
 * -----------------------------
 * 
 * This macro was modified from Puncta_quant.ijm 
 * (https://github.com/SoriaFN/Tools)
 * 
 * This is the version used in Beccari, Sierra et al., 2022
 * 
 * This macro is intended for multichannel (3 or more channels) fluorescence images.
 * It will segment a particular cell type based on a cytoplasmic marker (Iba1, GFAP, etc)
 * and it will quantify number, size and fluorescence intensity of LC3 and LAMP1 puncta 
 * within the cellular ROI (i.e. within the cell type of interest, e.g. Microglia).
 * 
 * The lysosome puncta quantification will be done in specific slices of a z-stack.
 * You have to specify: 
 * 1. Threshold to segment LC3 (Line 86)
 * 2. Threshold to segment LAMP1 (Line 98)
 * 3. Slices to use for puncta quantificacion (Lines 101-103)
 * 
 * Please cite the paper if you use it in your analysis.
 * 
 * CONTACT
 * federico.soria@achucarro.org
 */

//INITIALIZATION
run("Clear Results");
print("\\Clear"); //Clears the log
run("Options...", "iterations=1 count=1 black"); //Signal is white, background is black
run("Set Measurements...", "area mean limit display redirect=None decimal=2");
roiManager("reset"); //wipes the ROI manager
dir=getDirectory("Choose a folder to save files");
name=getTitle();
getDimensions(width, height, channels, slices, frames);
print("Number of channels= "+channels);
print("Number of slices= "+slices);
if (channels < 3){
	exit("Image has less than 3 channels (macro is intended for 3 channels minimum");
}
if (slices < 3){
	exit("Image has less than 3 slices (macro is intended for z-stacks");
}
print("Results will be saved in "+dir);
print("Analyzing "+name);

//UNITS
getPixelSize(unit, pixelWidth, pixelHeight);
if (unit != "pixels"){
     print ("pixel size = "+ pixelWidth +" "+unit);
    } else print("Image is not spatially calibrated");

//CELL SEGMENTATION
run("Split Channels");
seg_chan=getNumber("Which channel will you use for segment your CELLS of interest", 2);
selectWindow("C"+seg_chan+"-"+name);
run("Z Project...", "projection=[Max Intensity]"); //this will create a maximal projection, to ensure getting lysosomes in all z-layers.
run("Threshold...");
setAutoThreshold("Default dark"); 
waitForUser("Set Threshold", "Set Threshold level using the upper sliding bar \nThen click OK. \n \nDo not press Apply!\nCheck all slices to ensure all processes are connected!");
getThreshold(thrs, upper);
print("Threshold for cell segmentation: "+thrs);
run("Convert to Mask");
run("Median...", "radius=2"); //you can reduce the radius to 1 if you deem the filtering is being too harsh.
saveAs("tiff", dir+File.separator+name+"_MAX_CELL-bin");

//CELL ROI
setAutoThreshold("Default dark");
run("Create Selection");
roiManager("Add");
roiManager("save", dir+File.separator+name+"CELL_ROI.zip");
run("Measure"); //measures the area of CELL in the maximal projection
area_mg=getResult("Area", 0);
myTable(name,"Cell Total Area",area_mg,unit,"N/A");

//LC3 segmentation
lc3_chan=getNumber("Which channel has LC3 data", 4);
selectWindow("C"+lc3_chan+"-"+name);
run("Duplicate...", "title=LC3-bin duplicate");
roiManager("Select", 0);
run("Clear Outside", "stack");
run("Select None");
run("Subtract Background...", "rolling=2 stack"); //Background filter (rolling number can be changed)
selectWindow("LC3-bin");
setAutoThreshold("Moments dark"); //You can change the threshold used
run("Convert to Mask", "method=Moments background=Dark calculate black"); //You can change the threshold used (in this case is "Moments")

//LAMP1 SEGMENTATION
lamp_chan=getNumber("Which channel has LAMP data", 3);
selectWindow("C"+lamp_chan+"-"+name);
run("Duplicate...", "title=LAMP1 duplicate");
roiManager("Select", 0);
run("Clear Outside", "stack");
run("Select None");
difgaus (1, 50, "LAMP1-bin"); //Difference of Gaussians filter
selectWindow("LAMP1-bin");
setAutoThreshold("Default dark");
run("Convert to Mask", "method=Default background=Dark calculate black"); //You can change the threshold used (in this case is "Default")

//SLICE SELECTOR (you can change the number of the slices to be used in puncta quantification)
slice1 = 4;  
slice2 = 8;
slice3 = 12;
print("Slices used for puncta quantification= "+slice1+", "+slice2+", "+slice3);

//LAMP1 QUANTIFICATION
selectWindow("LAMP1-bin");
puncta (3, slice1, 4); //Function modifiers: channel, slice, size of punctum in pixels
selectWindow("LAMP1-bin");
puncta (3, slice2, 4);
selectWindow("LAMP1-bin");
puncta (3, slice3, 4);

//LC3 QUANTIFICATION
selectWindow("LC3-bin");
puncta (4, slice1, 4); //Function modifiers: channel, slice, size of punctum in pixels
selectWindow("LC3-bin");
puncta (4, slice2, 4);
selectWindow("LC3-bin");
puncta (4, slice3, 4);

//COLOCALIZACION
coloc(slice1, slice2, slice3, 4); //4th modifier is the minimum punctum size in pixels

//END
selectWindow("LAMP1-bin");
saveAs("tiff", dir+File.separator+name+"_LAMP1-bin");
selectWindow("LC3-bin");
saveAs("tiff", dir+File.separator+name+"_LC3-bin");
run("Tile");
waitForUser("Close all windows");
run("Close All");
selectWindow("Quantification");
saveAs("text", dir+File.separator+"Table_"+name+".xls");
selectWindow("Summary");
saveAs("text", dir+File.separator+"Summary_"+name+".xls");
selectWindow("Log");
saveAs("text", dir+File.separator+"Log_"+name+".txt");
selectWindow("Results");
run("Close");
waitForUser("SUMMARY contains summarized puncta and colocalization data.\n \nQUANTIFICATION (Table) contains individual puncta data.\n \nLOG contains parameters used for quantification");
print("");

//FUNCTION FOR IMAGE ENHANCEMENT (from Jorge Valero @Achucarro)
function difgaus (min, max, finalname){
	run("Duplicate...", "title=min duplicate");
	run("Gaussian Blur...", "sigma="+min+" stack");
	run("Duplicate...", "title=max duplicate");
	run("Gaussian Blur...", "sigma="+max+" stack");

	imageCalculator("Subtract stack", "min","max");
	selectWindow("max");
	close();
	selectWindow("min");
	rename(finalname);
}

//FUNCTION FOR PUNCTA QUANTIFICATION
function puncta (ch, slice, min_size){
	run("Clear Results");
	name2=getTitle();
	selectWindow(name2);
	Stack.setSlice(slice);
	run("Duplicate...", "use");
	rename(name2+"-S"+slice);
	name_with_slice_n=getTitle();
	roiManager("reset");
	run("Analyze Particles...", "size="+min_size+"-Infinity display add pixel summarize");
	n = roiManager("Count");
	for (i=0; i<n; i++) { //quantifies area and fluo and sends to custom table
		area_puncta=getResult("Area", i);
		selectWindow("C"+ch+"-"+name);
		roiManager("deselect");
		roiManager("Select", i);
		run("Measure");
		mgv=getResult("Mean", (i+n));
		run("Select None");
		myTable(name,name_with_slice_n,area_puncta,unit,mgv);
	}
	waitForUser("Fluorescence from "+n+" puncta from channel "+ch+", slice "+slice+" has been quantified");
}

//FUNCTION FOR COLOCALIZATION
function coloc (s1, s2, s3, min_size){
	imageCalculator("AND create", "LAMP1-bin-S"+s1, "LC3-bin-S"+s1);
	rename("Coloc-S"+s1);
	run("Analyze Particles...", "size="+min_size+"-Infinity pixel summarize");

	imageCalculator("AND create", "LAMP1-bin-S"+s2, "LC3-bin-S"+s2);
	rename("Coloc-S"+s2);
	run("Analyze Particles...", "size="+min_size+"-Infinity pixel summarize");

	imageCalculator("AND create", "LAMP1-bin-S"+s3, "LC3-bin-S"+s3);
	rename("Coloc-S"+s3);
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
