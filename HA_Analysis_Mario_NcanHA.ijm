//HA SEGMENTATION AND SKELETON ANALYSIS
//federico.soria@achucarro.org
//Last updated - May 2022

//INITIALIZATION
print("\\Clear");
requires("1.43f");
List.setCommands;
    if (List.get("FractalCount ")=="") {
       showMessage("Required Plugin", "<html><h3>Macro requires ImageJ-PlugIn \"FractalCount\"!</h3>"
     +"<a href=\"http://www.pvv.org/~perchrh/imagej/fractal.html\">Download</a>"); exit(););
    }
run("Options...", "iterations=1 count=1 black");
run("Set Measurements...", "area mean limit display redirect=None decimal=2");
setForegroundColor(255, 255, 255);
setBackgroundColor(0, 0, 0);
name=getTitle();
dir=getDirectory("Choose a Directory to save images");
getDimensions(w, h, channels, slices, frames);
if (channels>1) {
	HA_channel=getNumber("Which one is Hyaluronan channel?", 4);
	run("Split Channels");
	selectWindow("C"+HA_channel+"-"+name);
}
if (slices>1) {
	slice_range=getString("Slice range to be analyzed", "1-3");
	run("Duplicate...", "duplicate range="+slice_range);
	run("Z Project...", "projection=[Max Intensity]");	
}
run("Grays");


//SEGMENTATION
run("Duplicate...", " ");
run("Subtract Background...", "rolling=15"); //can be changed. Test.
run("Median...", "radius=1"); //can be changed. Test.
setAutoThreshold("Triangle dark"); //This must be the same for all images and chosen carefully.
run("Threshold...");
waitForUser("Threshold OK?");
run("Measure");
waitForUser("copy area and MGV to excel");
run("Convert to Mask");
saveAs("Tiff", dir + name + "-BIN.tif");

//SKELETONIZATION
run("Skeletonize");
waitForUser("Are you happy with the skeleton?");
saveAs("Tiff", dir + name + "-SK.tif");
name_sk=getTitle();

//ANALYSIS
run("FractalCount ", "plot automatic threshold=70 start=24 min=2 box=1.2 number=3"); //you can change min box size
waitForUser("Copy Fractal Dimension to Excel");
print("\\Clear");
run("Analyze Skeleton (2D/3D)", "prune=none calculate show");

for(i=0;i<nResults();i++){
	lsps = getResult("Longest Shortest Path", i);
	print (lsps);	
}
selectWindow("Log"); 
waitForUser("Copy LSPs to excel");
if (isOpen("Log")) { 
	selectWindow("Log"); 
    run("Close"); 
}

//INTERSECTIONS
selectWindow(name_sk);
run("Skeleton Intersections", "pseudo results");
selectWindow("Skeleton intersections");
saveAs("Tiff", dir + name + "-INT.tif");
selectWindow("Results");
waitForUser("Copy number of intersections to Excel");

//close windows
  macro "Close All Windows" { 
      while (nImages>0) { 
          selectImage(nImages); 
          close(); 
      } 
  } 

waitForUser("ok?");
run("close");
