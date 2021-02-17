/*
 * DoG FILTER 1.1
 * --------------
 * 
 * A Difference-of-gaussians filter for fluorescence images 
 *
 * Changes in 1.1 (Feb 2021)
 *  - Added dialog to choose min and max sigma.
 *
 * Federico N. Soria
 * ACHUCARRO BASQUE CENTER FOR NEUROSCIENCE
 * January 2020
 */

Dialog.create("Difference of Gaussians Filter");
Dialog.addNumber("Minimum sigma", 1);
Dialog.addNumber("Maximum sigma", 50);
Dialog.show();
gmin=Dialog.getNumber();
gmax=Dialog.getNumber();
		
name=getTitle();
selectWindow(name);
run("Grays");
run("Duplicate...", "title=min duplicate");
run("Gaussian Blur...", "sigma="+gmin+" stack");
selectWindow(name);
run("Duplicate...", "title=max duplicate");
run("Gaussian Blur...", "sigma="+gmax+" stack");
imageCalculator("Subtract stack", "min","max");
selectWindow("max");
close();
selectWindow("min");
run("Enhance Contrast", "saturated=0.35");
rename(name+"-Enhanced");
