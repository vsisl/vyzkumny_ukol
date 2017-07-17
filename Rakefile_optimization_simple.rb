require 'pp'
require 'active_support/core_ext/enumerable.rb'		# umožňuje array.sum

#----------------------------------------------------------------------------
#--------------------------------- METHODS ----------------------------------
#----------------------------------------------------------------------------

# method for loading an irradiation profile (e.g. A(z)) from a file into an array
def load_irradiation_profile (file_irradiation_profile, nr_of_coat_bins)		
	array_irradiation_profile = []

	File.foreach(file_irradiation_profile).with_index do |line, line_nr|				
		if line_nr > 0 and line_nr < nr_of_coat_bins + 1						# skip firts line (header), index 0; load only the coat bins
			array_irradiation_profile << line.strip.split[1].to_f			
		end
	end

	return array_irradiation_profile
end	
#----------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------      TASKS      ------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------
desc "simple irradiation optimization, 2 beams only"
task :optimization_simple do
	folder_data = 					"myData"
	file_simulation_settings = 		"#{folder_data}/simulation_settings"
	folder_outputs = 				"#{folder_data}/Outputs_FeCrAl"
	# file_DPA_1 =					"#{folder_outputs}/FeCrAl_Si28_1700keV_DPA.dat"
	# file_DPA_2 =					"#{folder_outputs}/FeCrAl_Si28_3000keV_DPA.dat"
	file_DPA_1 =					"#{folder_outputs}/test_1.dat"
	file_DPA_2 =					"#{folder_outputs}/test_3.dat"

	simulation_settings = Marshal.load(File.open(file_simulation_settings, 'rb').read)	# simulation_settings is a hash containing all data from the file_simulation_settings		
 	#pp simulation_settings

 	nr_of_steps = 	1000

 	array_A = 		[]																	# fisrt irradiation distribution A(z)
	array_B = 		[]																	# second irradiation distribution B(z)
	array_f = 		[]																	# final irradiation distribution f(z) made as a combination f(z) = a * A(z) + b * B(z)

	coat_width = 	simulation_settings["FeCrAl"]["coat_width"].to_f
	clad_width = 	simulation_settings["FeCrAl"]["clad_width"].to_f
	bin_width = 	(coat_width + clad_width)/100 										# Delta_z [A]
	nr_of_coat_bins = ((coat_width/(coat_width + clad_width)) * 100).to_i	

	array_A = load_irradiation_profile(file_DPA_1, nr_of_coat_bins)						# loading the first irradiation profile A(z)
	array_B = load_irradiation_profile(file_DPA_2, nr_of_coat_bins)						# loading the second irradiation profile B(z)
	
	array_a = 		[]
	array_b = 		[]
	array_S1 = 		[]
	array_S2 = 		[]
	array_SDEV =	[]
		
	(0..nr_of_steps - 1).each do |i|				 									# inicializing vectors
		array_a 	<< i/nr_of_steps.to_f												# create the vector a, e.g. a = (0, 0.001, 0.002, .... 0.999)
		array_b 	<< 1 - array_a[i]													# b_i = 1 - a_i
		array_S1 	<< 0.to_f
		array_S2 	<< 0.to_f
		array_SDEV 	<< 0.to_f
	end
	
	# ------------------------------
	# --- START OF THE ALGORITHM ---
	# ------------------------------
	# algorithm based on the COMPARISON OF THE STANDARD DEVIATION of the damage distribution profile for each parameter a \in (0..1); for more info see FUNDAMENTALS OF MONTE CARLO PARTICLE TRANSPORT, FORREST B. BROWN, Lecture notes for Monte Carlo course, slide 6-6, http://kfe.fjfi.cvut.cz/~horny/ostatni/VU_HORNY/REFS1/LA-UR-05-4983_Monte_Carlo_Lectures.pdf	

	(0..nr_of_steps - 1).each do |i|													# iteration over the array_a
		(0..nr_of_coat_bins - 1).each do |j|											# iteration over the depth of the target; the target is divided into 100 bins, but only the coating bins are taken into account
			array_f[j] 	= array_a[i] * array_A[j] + array_b[i] * array_B[j]				# f(z) is the overall distribution of defects made by a sum of the first distribution A(z) and the second distribution B(z)
			array_S1[i]	= array_S1[i] + array_f[j]											
			array_S2[i]	= array_S2[i] + array_f[j]**2
		end

		array_SDEV[i] = Math.sqrt(1/(nr_of_coat_bins - 1).to_f * (array_S2[i]/nr_of_coat_bins - (array_S1[i]/nr_of_coat_bins)**2))	# standard deviation of the damage distribution for each parameter a; formula from MCNP
		# array_SDEV[i] = 1/100.to_f * Math.sqrt(100 * array_S2[i] - array_S1[i]**2)												# alternative formula for standard deviation
		# array_SDEV[i] = Math.sqrt((100 * array_S2[i] - array_S1[i]**2)/(100 * 99))												# alternative formula for standard deviation

		puts "a: #{array_a[i]}      SDEV: #{array_SDEV[i]}"
	end

	# ---------------------
	# --- PRINT RESULTS ---
	# ---------------------
	print "nr_of_steps:"
	puts nr_of_steps
	# print "index for min. value:"
	# puts array_SDEV.index { |x| x == array_SDEV.min }  
	print "a for min. standard deviation value:"
	puts array_a[array_SDEV.index { |x| x == array_SDEV.min } ]
	# print "index for max. value:"
	# puts array_SDEV.index { |x| x == array_SDEV.max }  
	# print "a for max. value:"
	# puts array_a[array_SDEV.index { |x| x == array_SDEV.max } ]
	puts "---"
end
#-------------------------------------------------------------------------------------------------------------------------------------