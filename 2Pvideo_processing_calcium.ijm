/*
 * CALCIUM IN VIVO VIDEO PROCESSING
 * --------------------------------
 * A macro to process calcium imaging videos from our 2P setup.
 * 
 * Rescaling is done since our software export timelapse videos with
 * "slices" and "frames" inverted (Femtonics' MES 6).
 * 
 * Registration is done manually with TurboReg (use batch). The script
 * will produce an average intensity z-projection to use as reference.
 * 
 * Denoising is performed with the "Stack Moving Average" macro 
 * included by default in ImageJ.
 * 
 * Tested only with our images.
 * 
 * Dependencies:
 * -TurboReg (only if you click on "Register with TurboReg").
 * 
 * Federico N. Soria (c) 2023
 */

//Initialization
print("\\Clear");
run("Options...", "iterations=1 count=1 black");
name=getTitle();
getDimensions(width, height, channels, slices, frames);
getPixelSize(unit, pixelWidth, pixelHeight);

//GUI
Dialog.create("Choose your destiny...");
Dialog.addString("Identifier", "mouse1", 20);
Dialog.addNumber("Acquisition speed in Hz", 1.26);
Dialog.addCheckbox("Register with TurboReg?", true);
Dialog.addCheckbox("Denoise with rolling average", true);
Dialog.show();
id=Dialog.getString();
hz=Dialog.getNumber();
reg=Dialog.getCheckbox();
denoise=Dialog.getCheckbox();
frame_duration=1/hz;
dir=getDirectory("Choose a folder to save Result files.");

//Cropping and scaling
run("Specify...", "width="+height+" height="+height+" x=0 y=0 slice=1");
run("Crop");
rescale();
saveAs("tiff", dir+File.separator+id+"_"+name);
name2=getTitle();

//Registration (use batch)
if (reg==true) {
	run("Z Project...", "projection=[Average Intensity]");
	rename("average");
	run("TurboReg ");
	waitForUser("Press OK when TurboReg is done");
	selectWindow("Registered");
	rescale();
	run("16-bit");
	saveAs("tiff", dir+File.separator+"REG_"+id+"_"+name);
}

if (denoise==true) {
	denoiser();
	selectWindow("Reslice of Reslice");
	rescale();
	run("16-bit");
	saveAs("tiff", dir+File.separator+"REG_DEN_"+id+"_"+name);
}

//End
print("Files saved in "+dir);
close_images = getBoolean("Close all images?");
if (close_images==true) {
	run("Close All");	
}
print("FLAWLESS VICTORY...");

function rescale() {
	Stack.setXUnit("um");
	Stack.setYUnit("um");
	run("Properties...", "channels=1 slices=1 frames="+slices+" pixel_width="+pixelWidth+" pixel_height="+pixelWidth+" voxel_depth=1 frame=["+frame_duration+" sec]");
}

function denoiser() { //from the original Stack Moving Average macro within ImageJ folder
	k3 = "[0 1 0 0 1 0 0 1 0]";
	k5 = "[0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0]";
	k7a = "[0 0 0 1 0 0 0 0 0 0 1 0 0 0 0 0 0 1 0 0 0 0 0 0 1";
    k7b = " 0 0 0 0 0 0 1 0 0 0 0 0 0 1 0 0 0 0 0 0 1 0 0 0]";
	k7 = k7a + k7b;
	Dialog.create("Running Average Denoiser");
	Dialog.addChoice("Slices to Average:", newArray("3", "5", "7"), "5");
	Dialog.addCheckbox("Keep Source Stack", true);
	Dialog.show;
	n = Dialog.getChoice;
	keep = Dialog.getCheckbox;
	kernel = k3;
	if (n=="5")
	    kernel = k5;
	else if (n=="7")
	    kernel = k7;
	if (nSlices==1)
	    exit("Stack required");
	id1 = getImageID;
	// re-slicing may not work if stack is scaled
	setVoxelSize(1, 1, 1, "pixel");
	getMinAndMax(min, max);
	run("Reslice [/]...", "input=1 output=1 start=Top");
	id2 = getImageID;
	if (!keep) {selectImage(id1); close;}
	selectImage(id2);
	run("Convolve...", "text1="+kernel+" normalize stack");
	run("Reslice [/]...", "input=1 output=1 start=Top");
	setMinAndMax(min, max); 
	selectImage(id2);
	close;
}

