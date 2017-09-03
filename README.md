# ATF multi-component cladding irradiation using SRIM
Presented scripts enable to 
  execute multiple TRIM input files in a batch,
  process the outputs of TRIM simulations, 
  calculate distribution of radiation damage, 
  create plots of radiation damage distribution,
  optimize the irradiation process consisting of irradiation by multiple ion beams of different energies in order to receive possibly   homogenious damage distribution.
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# How to use presented scripts to run ATF irradiation simulations and to optimize damage distribution

system requirements:
a) windows PC (tested with windows 10)
b) SRIM (tested with SRIM-2013)
c) ruby programming language (tested with version 2.2.3p173)
d) gnuplot (tested with version 5.0)

step-by-step instructions:
1) Download all files in this repository (including the folder "myData").
2) Move all downloaded files to the folder of your SRIM installation, e.g. C:\Program Files\SRIM-2013.
3) Open the file "Rakefile".
- On lines 7 and 8, correct the path of gnuplot.exe and TRIM.exe corresponding to your installation.
- In the task ":_01_simulation_settings" choose what coatings do you want to set for a simulation (by commenting/uncommenting).
4) Using Windows PowerShell, move to the folder of your SRIM installation. e.g. "cd C:\Program Files\SRIM-2013".
5) Using the command "rake -T", print a list of all available tasks. You should see the following list:
-	rake _01_simulation_settings      # creates the file 'simulation_settings' ...
-	rake _02_simulation_inputs        # creates input files based on the file '...
-	rake _03_simulation_run           # executes all input files created by :si...
-	rake _04_simulation_outputs       # processing of simulation outputs; to be...
-	rake _05_simulation_dpa           # creates dpa outputs and plots based on ...
-	rake _06_simulation_results       # creates results for all simulations
-	rake optimization_genetic_2beams  # optimization based on genetic algorithm...
-	rake optimization_genetic_3beams  # optimization based on genetic algorithm...
-	rake optimization_genetic_4beams  # optimization based on genetic algorithm...
-	rake optimization_genetic_5beams  # optimization based on genetic algorithm...
-	rake optimization_simple          # simple irradiation optimization, 2 beam...
6) Using the command "rake _01_simulation_settings", create a file "simulation_settings" in the folder "myData". This file includes all information about simulations to be performed based on what was set in the step 3). This task should be executed prior all other tasks as other tasks load information from the file "simulation_settings".
7) Using the command "rake _02_simulation_inputs", input files for SRIM are created in the folder "myData". The input files are created based on the settings from the step 3) and template input files "template_input_*.IN" located in the folder "myData".
8) Using the command "rake _03_simulation_run", all input files created by previous command are executed, output files "*_VACANCY.txt" are stored in folders "myData/Outputs_*".
9) Using the command "rake _04_simulation_outputs", output files "*_VACANCY.txt" are processed and new files "*_VACANCY.dat" are created.
10) Using the command "rake _05_simulation_dpa", files "*_DPA.dat" are created based on "*_VACANCY.dat". The files "*_DPA.dat" include the radiation damage profiles DPA/FLUENCE[dpa*cm2/Ion].
11) The command "rake _06_simulation_results" prepares results of all performed simulations in the form of graphs in tex/pdf format (gnuplot cairolatex terminal), the graphs are stored in a folder set by the variable "folder_paper_images" in the file "Rakefile".

Following commands 
-	rake optimization_genetic_2beams  
-	rake optimization_genetic_3beams  
-	rake optimization_genetic_4beams  
-	rake optimization_genetic_5beams  
-	rake optimization_simple          
calculate the optimal combination of manually selected ion beams; they use damage profile data from files "myData/Outputs_*/*_DPA.dat", they do not initiate any SRIM simulations.

All optimization calculations require manual setting of damage profiles to be used for optimization. These files are set by variables "file_DPA_*" in files "Rakefile_optimization_*.rb".

The command "rake optimization_simple" performs a simple optimization calculation for two beams.

Commands "rake optimization_genetic_Xbeams" perform genetic optimization calculations for X beams. In all cases, the results are printed directly to the console, plots are created and saved in the folder set by the variable "folder_images".

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------
# To create the genetic optimization algorithm for X ion beams:
- create a new file Rakefile_optimization_genetic_Xbeams.rb
- link this file to the main Rakefile by adding require 'Rakefile_optimization_genetic_Xbeams.rb'
- copy and paste the content of an existing file, e.g. Rakefile_optimization_genetic_5beams.rb to the file Rakefile_optimization_genetic_Xbeams.rb
- adjust methods:
    initialize_population_Xbeams
    fitness_Xbeams
    optimization_plot_Xbeams
    
- change global variables:
    nr_of_beams
    
- create new global variables:
    file_DPA_X, file_DPA_X-1, ...
    array_X, array_X-1, ...
    
- adjust the code to use the new methods rather than the old ones
    don't forget to change the input variables for all methods

