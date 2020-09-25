/*
 * DoG FILTER
 * ----------
 * 
 * A Difference-of-gaussians filter for fluorescence images 
 *
 * Planned: A dialog to choose min and max sigma.
 *
 * Federico N. Soria
 * ACHUCARRO BASQUE CENTER FOR NEUROSCIENCE
 * January 2020
 */

name=getTitle();
selectWindow(name);
run("Grays");
run("Duplicate...", "title=min duplicate");
run("Gaussian Blur...", "sigma=1 stack"); //sigma value can be tuned
selectWindow(name);
run("Duplicate...", "title=max duplicate");
run("Gaussian Blur...", "sigma=50 stack"); //sigma value can be tuned

imageCalculator("Subtract stack", "min","max");
selectWindow("max");
close();
selectWindow("min");
run("Enhance Contrast", "saturated=0.35"); //for visualization only, does not change pixel values
rename(name+"-Enhanced");
