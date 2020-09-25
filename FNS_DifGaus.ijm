name=getTitle();
selectWindow(name);
run("Grays");
run("Duplicate...", "title=min duplicate");
run("Gaussian Blur...", "sigma=1 stack");
selectWindow(name);
run("Duplicate...", "title=max duplicate");
run("Gaussian Blur...", "sigma=50 stack");

imageCalculator("Subtract stack", "min","max");
selectWindow("max");
close();
selectWindow("min");
run("Enhance Contrast", "saturated=0.35");
rename(name+"-Enhanced");

