/*
LESION PROFILER v1.1 (October 2019)
Federico N. Soria (federico.soria@achucarro.org)
*/

//GUI DIALOG
Dialog.create("Lesion Profiler v1.1");
Dialog.addMessage("Welcome to LESION PROFILER v1.1 \nThis macro allows to create radial fluorescence profiles on delimited regions \nThis version needs 1 image already open to work with.");
Dialog.addNumber("Number of profiles", 2);
Dialog.addNumber("Profile width in pixels", 250);
Dialog.addNumber("Default profile length in radii", 2);
Dialog.addCheckbox("Enhance image contrast", true); //Only for visualization, does not change values
Dialog.addCheckbox("Copy values to clipboard", true); //To copy to spreadsheet
Dialog.addCheckbox("Save ROIs and values to file", true);
Dialog.addMessage("After clicking OK, you will be prompted to choose a working directory.");
Dialog.show();
p=Dialog.getNumber();
roiwidth=Dialog.getNumber();
roilength=Dialog.getNumber();
contrast= Dialog.getCheckbox();
clipboard= Dialog.getCheckbox();
savetofile= Dialog.getCheckbox();
print("Number of Profiles: "+p);
print("Profile width: "+roiwidth+" pixels");
print("Default Length: "+roilength+" radii"); //Can be changed, but it will be stated in the log

//INITIALIZATION AND IMAGE INFO
if (nImages>0) {
	Overlay.remove;
} else {
	waitForUser("Please open an image");
}

run("Select None");
run("Clear Results");
roiManager("reset");
print("\\Clear");
run("Set Measurements...", "area centroid fit redirect=None decimal=2");
name=getTitle();
getPixelSize(unit, pw, ph);
getDimensions(width, height, channels, slices, frames);
font_size=round(height/40); //This is for the overlay at the center of lesion
center_size=round(height/100); //This is for the overlay at the center of lesion
center_pos=round(height/200); //This is for the overlay at the center of lesion

//CREATE DIRECTORIES
if (savetofile==true) {
	dir=getDirectory("Choose a Directory to save ROIs");
	dir_roi = dir + "ROIs" + File.separator;
	if (File.exists(dir_roi)==false) {
					File.makeDirectory(dir_roi);
	}
	dir_val = dir + "Values" + File.separator;
	if (File.exists(dir_val)==false) {
					File.makeDirectory(dir_val);
	}
}

//LESION SIZE
if (channels>1) {
	run("Split Channels");
}
waitForUser("Select image to delineate the lesion");
if (contrast==true) {
	run("Enhance Contrast", "saturated=0.35");
}
setTool("freehand");
waitForUser("draw a ROI over the lesioned area"); //This has to be approximate. 
run("Fit Ellipse");
run("Add Selection...");
run("Measure");
area = getResult("Area");
r_major = getResult("Major")/2; //Major radius of the fitted ellipse
r_minor = getResult("Minor")/2; //Minor radius of the fitted ellipse
radius = (r_major+r_minor)/2; //Average radius, used to draw the default profile
diametre = (radius*2);
print("Area of lesion: "+area+" "+unit);
print("Diameter of lesion: "+diametre+" "+unit);


//CENTER OF LESION
centroid_x = (getResult("X"))*(1/pw);
centroid_y = (getResult("Y"))*(1/pw);
setLineWidth(5);
setColor("yellow");
setFont("Sans Serif", font_size, "antialiased");
Overlay.drawEllipse((centroid_x-center_pos),(centroid_y-center_pos),center_size,center_size);
Overlay.drawString("Center of Lesion",(centroid_x+center_size),centroid_y);
Overlay.show; //This overlay is just for visualization, does not change values


//DEFAULT PROFILE LENGTH
lenght = (1/pw)*(radius*roilength); //converts lenght from scaled units to pixels
l_round = round(lenght);  //round length to nearest integer
makeLine(centroid_x,centroid_y,(centroid_x+l_round),centroid_y,roiwidth);


//USER PROFILE (User can keep the default length or change it)
count = 1;
for (i=0; i<p; i++) {
	waitForUser("Profile "+count+"\n \nMove the ROI to the appropiate position. \nUse ALT while dragging if you want to keep length fixed.");
	run("Measure");
	print("Profile "+count+" length: "+(getResult("Length"))+" "+unit);
	roiManager("add");
	roiManager("select", i);
	roiManager("rename", "Profile"+count);
	count = count+1;
}
if (savetofile==true) {
	roiManager("save", dir_roi+"ROIs_"+name+".zip");
	print("Profile ROIs saved in"+dir_roi);
}


//MEASURE PROFILES IN DIFFERENT CHANNELS
Dialog.create("Profile analysis");
Dialog.addMessage("Do you want to analyse profiles now?");
Dialog.addChoice("Type:", newArray("Yes", "No"));
Dialog.show();
ans = Dialog.getChoice();
while (ans=="Yes" && nImages>0) {
	waitForUser("Select a channel to be analyzed");
	count = 1;
	for (i=0; i<p; i++) {
		name_c=getTitle();
		roiManager("select", i);
		run("Plot Profile");
		Plot.getValues(x, y);
		Plot.showValues();
		if (savetofile==true) {
			saveAs("Results", dir_val+File.separator+"VALUES_"+name_c+"_P"+count+".xls");
		}
		if (clipboard==true) {
			String.copyResults; //Copies the "Results" table to clipboard.
			waitForUser("Paste results to spreadsheet");
		}
		count=count+1;
		selectWindow(name_c);
	}
	c = substring (name_c,1,2); 
	if (savetofile==true) {
		print("Ch"+c+" values saved in "+dir_val);
	}
	if (nImages>0) {
		Dialog.create("Profile analysis");
		Dialog.addMessage("Analyse more channels?");
		Dialog.addChoice("Type:", newArray("Yes", "No"));
		Dialog.show();
		ans = Dialog.getChoice();
	}
}
if (savetofile==true) {
	selectWindow("Log");
	saveAs("Text", dir+File.separator+"LOG_"+name+".txt");
	print("Log saved in "+dir);
}
Dialog.create("Close all images?");
Dialog.addChoice("Type:", newArray("Yes", "No"));
Dialog.show();
ans = Dialog.getChoice();
if (ans=="Yes") {
    run("Close All");
} 