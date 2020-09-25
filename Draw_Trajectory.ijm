/* 
 * DRAW_TRAJECTORY v1.1
 * --------------------
 * This script will draw a trajectory of a single molecule on top of its video file
 * based on coordinates previously calculated in TrackMate.
 * 
 * It has not been tested extensively so there are probably bugs.
 *
 * 1. Open the video (only tested in TIF stacks where frames>1).
 * 2. Import the .csv file (spots coordinates) generated in TrackMate
 * 3. Rename the table as "Results"
 * 4. Run the macro
 * 5. The trajectory will be colored based in instantaneous displacement (calculated by the macro).
 * 
 * Federico N. Soria
 * ACHUCARRO BASQUE CENTER FOR NEUROSCIENCE
 * August 2020
 * 
 * Please acknowledge this script if you use it in your publication
 */

if (nImages==0) {
	exit("Please open an image");
}

getDimensions(width, height, channels, slices, frames);
if (frames==1) {
	exit("Image is not a time-lapse image.\n \nPlease open a time-lapse image or switch slices to frames");
}

r=getValue("results.count");
last_frame=getResult("FRAME", r-1);
run("Duplicate...", "duplicate range=1-"+last_frame); //if last frames are not tracked, they will be eliminated
run("RGB Color");
getDimensions(width1, height1, channels1, slices1, frames1);
getPixelSize(unit, pW, pH);
setLineWidth(2);
max_d=10; //This is the highest displacement to be considered
n=1;
for (i=1;i<(frames1-1);i++) {
	Stack.setFrame(i+1);
	for (p=1;p<n;p++) {	
		x0=(getResult("POSITION_X", p-1)/pW);
		y0=(getResult("POSITION_Y", p-1)/pW);
		x1=(getResult("POSITION_X", p)/pW);
		y1=(getResult("POSITION_Y", p)/pW);
		d=sqrt((pow(x0-x1,2))+(pow(y0-y1,2))); //Calculates displacement
		red=(255*(d-(max_d*0.5)))/((max_d*0.66)-(max_d*0.5)); //Calculates ammount of red
		blue=(255*((max_d*0.5)-d))/((max_d*0.5)-(max_d*0.33)); //Calculates ammount of blue
		if (d<(max_d/2)) { //Calculates ammount of green
			green=(255*d)/(max_d*0.33);
		} else {
			green=(255*(max_d-d))/(max_d-(max_d*0.66));
		}
		setColor(red,green,blue);
		drawLine(x0, y0, x1, y1);
	}
	f=getResult("FRAME", n);
	if (i==f) {
		n=n+1;
	}
}
