# vyzkumny_ukol
ATF cladding irradiation using SRIM
Enables to 
  execute multiple TRIM input files in a batch,
  process the outputs of TRIM simulations, 
  calculate distribution of radiation damage, 
  create plots of radiation damage distribution,
  optimize the irradiation process consisting of irradiation by multiple ion beams of different energies in order to receive possibly   homogenious damage distribution.

To create the genetic optimization algorithm for X ion beams:
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

