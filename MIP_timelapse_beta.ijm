/*
 * MIP Time-Lapse v.0.1
 * --------------------
 *
 * BETA version (not tested)!!!
 *
 * This script generates a maximal intensity projections from 
 * tridimensional time-lapse images (xyzt hyperstacks).
 * 
 * The script was designed to process hyperstacks from 
 * two-photon microglia time-lapse images. Hence, it allows for registration 
 * and cropping of individual cells (I will do this optional in the future)
 * 
 * PLANNED FEATURES:
 * -Optional cropping
 * -Optional contrast enhancement
 * 
 * Federico N. Soria (February 2021) 
 * federico.soria@achucarro.org
 * 
 */

//REQUIREMENTS
requires("1.53c");
List.setCommands;
    if (List.get("StackReg ")=="") {
       showMessage("Required Plugin", "<html><h3>Macro requires additional Plugin \"StackReg\"!</h3>"
     +"<a href=\"http://bigwww.epfl.ch/thevenaz/stackreg\">Download</a>"); exit(););
    }

print("\\Clear");
contrast = 1; //It can be changed, it is just for better visualization. I will make it optional soon.

//MIP generator
name=getTitle();
run("Z Project...", "projection=[Max Intensity] all");
selectWindow(name);
close();
selectWindow("MAX_"+name);
getDimensions(width, height, channels, slices, frames);
run("Enhance Contrast...", "saturated="+contrast);
waitForUser("Is the image OK?");

//Registration
roiManager("reset");
if (frames==1) {
	exit("Image is not a time-lapse image.\n \nPlease open a time-lapse image or switch slices to frames");
}
run("Enhance Contrast", "saturated="+contrast);
run("Temporal-Color Code", "lut=Red/Green start=1 end="+frames);
items=newArray("Rigid Body", "Translation", "Scaled Rotation", "Affine");
reg=getBoolean("Does the image needs registration?");
selectWindow("MAX_colored");
close();
while (reg==1) {
	Dialog.create("Registration algorithm");
	Dialog.addChoice("Registering algorithm", items);
	Dialog.show();
	typeReg=Dialog.getChoice();
	print("Registering with algorithm "+typeReg+" ...");
	selectWindow("MAX_"+name);
	run("StackReg ", "transformation=["+typeReg+"]");
	print("Registration DONE");
	selectWindow("MAX_"+name);
	run("Enhance Contrast...", "saturated="+contrast);
	run("Temporal-Color Code", "lut=Red/Green start=1 end="+frames);
	reg=getBoolean("Does the image needs additional registration?");
	selectWindow("MAX_colored");
    close();
}

//Cropping
selectWindow("MAX_"+name);
run("Enhance Contrast...", "saturated="+contrast);
run("Temporal-Color Code", "lut=Red/Green start=1 end="+frames);
selectWindow("MAX_colored");
run("Maximize");
setTool("polygon");
waitForUser("Cleaning outside cell", "Draw a precise ROI around the cell and press OK");
roiManager("add");
selectWindow("MAX_"+name);
roiManager("select", 0);
setBackgroundColor(0, 0, 0);
run("Crop");
run("Clear Outside", "stack");
run("Select None");
selectWindow("MAX_"+name);
run("Enhance Contrast...", "saturated="+contrast);
doCommand("Start Animation");

//Save files
saveimage=getBoolean("Is the image OK? (Image will be saved if YES");
if (saveimage==1) {
	dir=getDirectory("Choose Output Directory");
	saveAs("TIFF", dir+File.separator+"MIP_"+name);
}
run("Close All");
selectWindow("Log");
run("Close");
