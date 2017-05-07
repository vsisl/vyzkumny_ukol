# ------------------------------------------------------------------------
# obsahuje NEFUNKČNÍ VERZE algoritmů (nebo verze s nezaručenou funkčností)
# ------------------------------------------------------------------------
desc "irradiation optimization - based on variations"
task :irradiation_optimization1 do
	folder_data = 					"myData"
	file_simulation_settings = 		"#{folder_data}/simulation_settings"
	folder_outputs = 				"#{folder_data}/Outputs_FeCrAl"
	# file_DPA_1 =					"#{folder_outputs}/FeCrAl_Si28_1700keV_DPA.dat"
	# file_DPA_2 =					"#{folder_outputs}/FeCrAl_Si28_3000keV_DPA.dat"
	file_DPA_1 =					"#{folder_outputs}/test_1.dat"
	file_DPA_2 =					"#{folder_outputs}/test_3.dat"

	simulation_settings = Marshal.load(File.open(file_simulation_settings, 'rb').read)		# simulation_settings is a hash containing all data from the file_simulation_settings		
 	#pp simulation_settings

 	nr_of_steps = 1000
	array_a = []
	array_S1 = 		[]
	array_S2 = 		[]
	array_AVG = 	[]
	array_SDEV =	[]
	coat_width = simulation_settings["FeCrAl"]["coat_width"].to_f
	clad_width = simulation_settings["FeCrAl"]["clad_width"].to_f
	bin_width = (coat_width + clad_width)/100 						# Delta_z [A]
	#puts bin_width
	array_f = []
	array_h = []
	array_g = []
	
	File.foreach(file_DPA_1).with_index do |line, line_nr|					# loading the first irradiation profile
		if line_nr > 0 														# skip firts line (header), index 0
			array_f << line.strip.split[1].to_f			
		end
	end
	# puts array_f
	File.foreach(file_DPA_2).with_index do |line, line_nr|					# loading the second irradiation profile
		if line_nr > 0 														# skip firts line (header), index 0
			array_h << line.strip.split[1].to_f			
		end
	end
	# puts array_h
	
	(0..nr_of_steps - 1).each do |j|				 					# inicializing vectors
		array_a 	<< j/nr_of_steps.to_f								# create the vector a, e.g. a = (0, 0.001, 0.002, .... 0.999, 1)
		array_S1 	<< 0.to_f
		array_S2 	<< 0.to_f
		array_AVG 	<< 0.to_f
		array_SDEV 	<< 0.to_f
	end
	# puts array_a
	
	# ----------------	algorithm based on the COMPARISON OF THE STANDARD DEVIATION of the damage distribution profile for each parameter a \in (0..1); for more info see FUNDAMENTALS OF MONTE CARLO PARTICLE TRANSPORT, FORREST B. BROWN, Lecture notes for Monte Carlo course, slide 6-6, http://kfe.fjfi.cvut.cz/~horny/ostatni/VU_HORNY/REFS1/LA-UR-05-4983_Monte_Carlo_Lectures.pdf	
	(0..nr_of_steps - 1).each do |j|													# iteration over the array_a
		(0..99).each do |i|																# iteration over the depth of the target; the target is divided into 100 bins
			array_g[i] 	= array_a[j] * array_f[i] + (1 - array_a[j]) * array_h[i]		# g(z) is the overall distribution of defects made by a sum of the first distribution f(z) and the second distribution g(z)
			array_S1[j]	= array_S1[j] + array_g[i]											
			array_S2[j]	= array_S2[j] + array_g[i]**2
		end

		array_SDEV[j] = Math.sqrt(1/99.to_f * (array_S2[j]/100 - (array_S1[j]/100)**2))	# standard deviation of the damage distribution for each parameter a; vztah z MCNP
		#array_SDEV[j] = 1/100.to_f * Math.sqrt(100 * array_S2[j] - array_S1[j]**2)		# vztah z wiki 1
		#array_SDEV[j] = Math.sqrt((100 * array_S2[j] - array_S1[j]**2)/(100 * 99))		# vztah z wiki 2
		# pozn. při otestování 3 různých vztahů pro array_SDEV[j] (MCNP, wiki1, wiki2) na vzorku FeCrAl_Fe56_1700keV_DPA.dat a FeCrAl_Fe56_6000keV_DPA.dat pro nr_of_steps = 99 byl výsledek totožný
	end
	# puts array_a
	# puts "---"
	# puts array_S1
	# puts "---"
	# puts array_S2
	# puts "---"
	# # puts array_AVG
	# puts "---"
	# puts array_SDEV
	# puts "---"
	# puts array_SDEV.min
	print "nr_of_steps:"
	puts nr_of_steps
	# print "index for min. value:"
	# puts array_SDEV.index { |x| x == array_SDEV.min }  
	print "a for min. value:"
	puts array_a[array_SDEV.index { |x| x == array_SDEV.min } ]
	# print "index for max. value:"
	# puts array_SDEV.index { |x| x == array_SDEV.max }  
	# print "a for max. value:"
	# puts array_a[array_SDEV.index { |x| x == array_SDEV.max } ]
	puts "---"
end
#-------------------------------------------------------------------------------------------------------------------------------------

desc "irradiation optimization - based on entropy"
task :irradiation_optimization2 do
	folder_data = 					"myData"
	file_simulation_settings = 		"#{folder_data}/simulation_settings"
	folder_outputs = 				"#{folder_data}/Outputs_FeCrAl"
	# file_DPA_1 =					"#{folder_outputs}/FeCrAl_Si28_1700keV_DPA.dat"
	# file_DPA_2 =					"#{folder_outputs}/FeCrAl_Si28_3000keV_DPA.dat"
	file_DPA_1 =					"#{folder_outputs}/test_1.dat"
	file_DPA_2 =					"#{folder_outputs}/test_2.dat"

	simulation_settings = Marshal.load(File.open(file_simulation_settings, 'rb').read)		# simulation_settings is a hash containing all data from the file_simulation_settings		
 	#pp simulation_settings

	array_a = 		[]
	array_PS_bez_exp = 		[]		# ln(pravá strana rovnosti)
	array_PS = 		[]		# pravá strana rovnosti
	array_LS = 		[]		# levá strana rovnosti
	array_difference_LS_PS = []
	# array_AVG = 	[]
	# array_SDEV =	[]
	#b = 0.5
	coat_width = simulation_settings["FeCrAl"]["coat_width"].to_f
	clad_width = simulation_settings["FeCrAl"]["clad_width"].to_f
	#bin_width = (coat_width + clad_width)/100 						# Delta_z [A]
	bin_width = 1.to_f 
	#puts bin_width
	array_f = []
	array_h = []
	array_g = []
	array_F = []

	File.foreach(file_DPA_1).with_index do |line, line_nr|
		if line_nr > 0 			# skip firts line (header), index 0
			array_f << line.strip.split[1].to_f#*10**15			
		end
	end

	File.foreach(file_DPA_2).with_index do |line, line_nr|
		if line_nr > 0 			# skip firts line (header), index 0
			array_h << line.strip.split[1].to_f#*10**15			
		end
	end

	(0..99).each do |i|
		array_F << (array_f[i] - array_h[i]) * bin_width
		#puts "#{array_f[i]}       #{array_h[i]}        #{array_F[i]}"
	end
	
	# puts array_f
	# puts array_h
	# puts array_F
	# pp array_f
	# puts array_f.size
	# pp array_h
	# puts array_h.size
	nr_of_steps = 10000

	(0..nr_of_steps - 1).each do |j|				 # create a vector a = (0, 0.001, 0.002, .... 0.999)
		array_a 	<< j/nr_of_steps.to_f
		array_LS 	<< 1.to_f					# vektor levé strany musí na začátku obsahovat jedničky, protože výchozí hodnota je pak násobena v každém kroku další hodnotou (produkt)
		array_PS_bez_exp 	<< 0.to_f					# vektor pravé strany musí na začátku obsahovat nuly, protože k výchozí hodnotě se pak v každém kroku přičítá další hodnota (suma)
		array_PS << 0.to_f
		# array_AVG 	<< 0.to_f
		# array_SDEV 	<< 0.to_f
	end
	#puts array_a
	
	(0..nr_of_steps - 1).each do |j|				# iteration over the array_a
		(0..99).each do |i|						# iteration over the depth of the target
			array_g[i] 	= array_a[j] * array_f[i] + (1 - array_a[j]) * array_h[i]
			#puts array_g[i]
			array_LS[j]	= array_LS[j] * array_g[i]**array_F[i]
			array_PS_bez_exp[j]	= array_PS_bez_exp[j] - array_F[i]
		end
		array_PS[j] = Math.exp(array_PS_bez_exp[j])

		array_difference_LS_PS[j] = (array_LS[j] - array_PS[j]).abs
	end
	# puts array_a
	# puts "---"
	# puts array_LS
	# puts "---"
	# puts array_PS
	# puts "---"
	# puts array_difference_LS_PS
	# puts "---"
	# puts array_SDEV
	# puts "---"
	# puts array_SDEV.min
	print "nr_of_steps:"
	puts nr_of_steps
	# print "index for min. value:"
	# puts array_difference_LS_PS.index { |x| x == array_difference_LS_PS.min }  
	print "a for min. value:"
	puts array_a[array_difference_LS_PS.index { |x| x == array_difference_LS_PS.min } ]
	# print "index for max. value:"
	# puts array_difference_LS_PS.index { |x| x == array_difference_LS_PS.max }  
	# print "a for max. value:"
	# puts array_a[array_difference_LS_PS.index { |x| x == array_difference_LS_PS.max } ]
	puts "---"
end
#-------------------------------------------------------------------------------------------------------------------------------------

desc "irradiation optimization - based on variations, only unzero g[i] taken into account -tohle je asi blbost"
task :irradiation_optimization3 do
	folder_data = 					"myData"
	file_simulation_settings = 		"#{folder_data}/simulation_settings"
	folder_outputs = 				"#{folder_data}/Outputs_FeCrAl"
	# file_DPA_1 =					"#{folder_outputs}/FeCrAl_Si28_1700keV_DPA.dat"
	# file_DPA_2 =					"#{folder_outputs}/FeCrAl_Si28_3000keV_DPA.dat"
	file_DPA_1 =					"#{folder_outputs}/test_1.dat"
	file_DPA_2 =					"#{folder_outputs}/test_3.dat"

	simulation_settings = Marshal.load(File.open(file_simulation_settings, 'rb').read)		# simulation_settings is a hash containing all data from the file_simulation_settings		
 	#pp simulation_settings

 	nr_of_steps = 1000
	array_a = []
	array_S1 = 		[]
	array_S2 = 		[]
	array_AVG = 	[]
	array_SDEV =	[]
	coat_width = simulation_settings["FeCrAl"]["coat_width"].to_f
	clad_width = simulation_settings["FeCrAl"]["clad_width"].to_f
	bin_width = (coat_width + clad_width)/100 						# Delta_z [A]
	#puts bin_width
	array_f = []
	array_h = []
	array_g = []
	
	File.foreach(file_DPA_1).with_index do |line, line_nr|					# loading the first irradiation profile
		if line_nr > 0 														# skip firts line (header), index 0
			array_f << line.strip.split[1].to_f			
		end
	end
	# puts array_f
	File.foreach(file_DPA_2).with_index do |line, line_nr|					# loading the second irradiation profile
		if line_nr > 0 														# skip firts line (header), index 0
			array_h << line.strip.split[1].to_f			
		end
	end
	# puts array_h
	
	(0..nr_of_steps - 1).each do |j|				 						# inicializing vectors
		array_a 	<< j/nr_of_steps.to_f								# create the vector a, e.g. a = (0, 0.001, 0.002, .... 0.999, 1)
		array_S1 	<< 0.to_f
		array_S2 	<< 0.to_f
		array_AVG 	<< 0.to_f
		array_SDEV 	<< 0.to_f
	end
	nr_of_unzero_bins = 0
	
	# ----------------	algorithm based on the COMPARISON OF THE STANDARD DEVIATION of the damage distribution profile for each parameter a \in (0..1); for more info see FUNDAMENTALS OF MONTE CARLO PARTICLE TRANSPORT, FORREST B. BROWN, Lecture notes for Monte Carlo course, slide 6-6, http://kfe.fjfi.cvut.cz/~horny/ostatni/VU_HORNY/REFS1/LA-UR-05-4983_Monte_Carlo_Lectures.pdf	
	(0..nr_of_steps - 1).each do |j|													# iteration over the array_a
		(0..99).each do |i|																# iteration over the depth of the target; the target is divided into 100 bins
			if array_f[i] != 0.to_f or array_h[i] != 0.to_f
				array_g[i] 	= array_a[j] * array_f[i] + (1 - array_a[j]) * array_h[i]	# g(z) is the overall distribution of defects made by a sum of the first distribution f(z) and the second distribution g(z)
				array_S1[j]	= array_S1[j] + array_g[i]											
				array_S2[j]	= array_S2[j] + array_g[i]**2
				nr_of_unzero_bins = nr_of_unzero_bins + 1
			end
		end

		array_SDEV[j] = Math.sqrt(1/(nr_of_unzero_bins - 1).to_f * (array_S2[j]/nr_of_unzero_bins - (array_S1[j]/nr_of_unzero_bins)**2))	# standard deviation of the damage distribution for each parameter a; vztah z MCNP
		#array_SDEV[j] = 1/100.to_f * Math.sqrt(100 * array_S2[j] - array_S1[j]**2)		# vztah z wiki 1
		#array_SDEV[j] = Math.sqrt((100 * array_S2[j] - array_S1[j]**2)/(100 * 99))		# vztah z wiki 2
		# pozn. při otestování 3 různých vztahů pro array_SDEV[j] (MCNP, wiki1, wiki2) na vzorku FeCrAl_Fe56_1700keV_DPA.dat a FeCrAl_Fe56_6000keV_DPA.dat pro nr_of_steps = 99 byl výsledek totožný
	end
	# puts array_a
	# puts "---"
	# puts array_S1
	# puts "---"
	# puts array_S2
	# puts "---"
	# # puts array_AVG
	# puts "---"
	# puts array_SDEV
	# puts "---"
	# puts array_SDEV.min
	print "nr_of_steps:"
	puts nr_of_steps
	print "index for min. value:"
	puts array_SDEV.index { |x| x == array_SDEV.min }  
	print "a for min. value:"
	puts array_a[array_SDEV.index { |x| x == array_SDEV.min } ]
	# print "index for max. value:"
	# puts array_SDEV.index { |x| x == array_SDEV.max }  
	# print "a for max. value:"
	# puts array_a[array_SDEV.index { |x| x == array_SDEV.max } ]
	puts "---"
end
#-------------------------------------------------------------------------------------------------------------------------------------

desc "irradiation optimization - based on entropy, only takes coat part into account"
task :irradiation_optimization5 do
	folder_data = 					"myData"
	file_simulation_settings = 		"#{folder_data}/simulation_settings"
	folder_outputs = 				"#{folder_data}/Outputs_FeCrAl"
	# file_DPA_1 =					"#{folder_outputs}/FeCrAl_Si28_1700keV_DPA.dat"
	# file_DPA_2 =					"#{folder_outputs}/FeCrAl_Si28_3000keV_DPA.dat"
	file_DPA_1 =					"#{folder_outputs}/test_1.dat"
	file_DPA_2 =					"#{folder_outputs}/test_2.dat"

	simulation_settings = Marshal.load(File.open(file_simulation_settings, 'rb').read)		# simulation_settings is a hash containing all data from the file_simulation_settings		
 	#pp simulation_settings

 	nr_of_steps = 5
	array_a = 		[]
	array_PS_bez_exp = 		[]		# ln(pravá strana rovnosti)
	array_PS = 		[]				# pravá strana rovnosti
	array_LS = 		[]				# levá strana rovnosti
	array_difference_LS_PS = []
	# array_AVG = 	[]
	# array_SDEV =	[]
	#b = 0.5
	coat_width = simulation_settings["FeCrAl"]["coat_width"].to_f
	clad_width = simulation_settings["FeCrAl"]["clad_width"].to_f
	nr_of_coat_bins = ((coat_width/(coat_width + clad_width)) * 100).to_i	
	#puts nr_of_coat_bins
	#bin_width = (coat_width + clad_width)/100 						# Delta_z [A]
	bin_width = 1.to_f 
	#puts bin_width
	array_f = []
	array_h = []
	array_g = []
	array_F = []

	File.foreach(file_DPA_1).with_index do |line, line_nr|
		if line_nr > 0 and line_nr < nr_of_coat_bins + 1					# skip firts line (header), index 0; load only tho coat bins
			array_f << line.strip.split[1].to_f#*10**15			
		end
	end

	File.foreach(file_DPA_2).with_index do |line, line_nr|
		if line_nr > 0 and line_nr < nr_of_coat_bins + 1					# skip firts line (header), index 0; load only tho coat bins
			array_h << line.strip.split[1].to_f#*10**15			
		end
	end

	(0..nr_of_coat_bins - 1).each do |i|
		array_F << (array_f[i] - array_h[i]) * bin_width
		#puts "#{array_f[i]}       #{array_h[i]}        #{array_F[i]}"
	end
	
	# puts array_f
	# puts "---"
	# puts array_h
	# puts "---"
	# puts array_F
	# pp array_f
	# puts array_f.size
	# pp array_h
	# puts array_h.size
	

	(0..nr_of_steps - 1).each do |j|				 # create a vector a = (0, 0.001, 0.002, .... 0.999)
		array_a 	<< j/nr_of_steps.to_f
		array_LS 	<< 1.to_f					# vektor levé strany musí na začátku obsahovat jedničky, protože výchozí hodnota je pak násobena v každém kroku další hodnotou (produkt)
		array_PS_bez_exp 	<< 0.to_f					# vektor pravé strany musí na začátku obsahovat nuly, protože k výchozí hodnotě se pak v každém kroku přičítá další hodnota (suma)
		array_PS << 0.to_f
		# array_AVG 	<< 0.to_f
		# array_SDEV 	<< 0.to_f
	end
	#puts array_a
	#puts array_PS_bez_exp
	#puts array_h
	
	(0..nr_of_steps - 1).each do |j|				# iteration over the array_a
		(0..nr_of_coat_bins - 1).each do |i|						# iteration over the depth of the target
			array_g[i] 	= array_a[j] * array_f[i] + (1 - array_a[j]) * array_h[i]
			puts "g[i]: #{array_g[i]}     F[i]: #{array_F[i]}     g[i]**F[i]: #{array_g[i]**array_F[i]}"
			array_LS[j]	= array_LS[j] * array_g[i]**array_F[i]
			array_PS_bez_exp[j]	= array_PS_bez_exp[j] - array_F[i]
		end
		array_PS[j] = Math.exp(array_PS_bez_exp[j])
		puts "a: #{array_a[j]}      PS: #{array_PS[j]}        LS: #{array_LS[j]}"

		array_difference_LS_PS[j] = (array_LS[j] - array_PS[j]).abs
	end
	# puts array_a
	# puts "---"
	# puts array_LS
	# puts "---"
	# puts array_PS
	# puts "---"
	# puts array_difference_LS_PS
	# puts "---"
	# puts array_SDEV
	# puts "---"
	# puts array_SDEV.min
	print "nr_of_steps:"
	puts nr_of_steps
	# print "index for min. value:"
	# puts array_difference_LS_PS.index { |x| x == array_difference_LS_PS.min }  
	print "a for min. value:"
	puts array_a[array_difference_LS_PS.index { |x| x == array_difference_LS_PS.min } ]
	# print "index for max. value:"
	# puts array_difference_LS_PS.index { |x| x == array_difference_LS_PS.max }  
	# print "a for max. value:"
	# puts array_a[array_difference_LS_PS.index { |x| x == array_difference_LS_PS.max } ]
	puts "---"
end
#-------------------------------------------------------------------------------------------------------------------------------------

desc "irradiation optimization - based on entropy, only takes coat part into account, computes the entropy directly and then looks for maximum"
task :irradiation_optimization6 do
	folder_data = 					"myData"
	file_simulation_settings = 		"#{folder_data}/simulation_settings"
	folder_outputs = 				"#{folder_data}/Outputs_FeCrAl"
	# file_DPA_1 =					"#{folder_outputs}/FeCrAl_Si28_1700keV_DPA.dat"
	# file_DPA_2 =					"#{folder_outputs}/FeCrAl_Si28_3000keV_DPA.dat"
	file_DPA_1 =					"#{folder_outputs}/test_1.dat"
	file_DPA_2 =					"#{folder_outputs}/test_2.dat"

	simulation_settings = Marshal.load(File.open(file_simulation_settings, 'rb').read)		# simulation_settings is a hash containing all data from the file_simulation_settings		
 	#pp simulation_settings

 	nr_of_steps = 100
	array_a = 		[]
	array_S = 		[]		# entropy
	coat_width = simulation_settings["FeCrAl"]["coat_width"].to_f
	clad_width = simulation_settings["FeCrAl"]["clad_width"].to_f
	nr_of_coat_bins = ((coat_width/(coat_width + clad_width)) * 100).to_i	
	#puts nr_of_coat_bins
	bin_width = (coat_width + clad_width)/100 						# Delta_z [A]
	#bin_width = 1.to_f 
	#puts bin_width
	array_f = []
	array_h = []
	array_g = []
	
	File.foreach(file_DPA_1).with_index do |line, line_nr|
		if line_nr > 0 and line_nr < nr_of_coat_bins + 1					# skip firts line (header), index 0; load only tho coat bins
			array_f << line.strip.split[1].to_f*2			
		end
	end

	File.foreach(file_DPA_2).with_index do |line, line_nr|
		if line_nr > 0 and line_nr < nr_of_coat_bins + 1					# skip firts line (header), index 0; load only tho coat bins
			array_h << line.strip.split[1].to_f*2		
		end
	end

	# puts array_f
	# puts "---"
	# puts array_h
	# puts "---"
	# puts array_F
	# pp array_f
	# puts array_f.size
	# pp array_h
	# puts array_h.size
	
	(0..nr_of_steps - 1).each do |j|				 # create a vector a = (0, 0.001, 0.002, .... 0.999)
		array_a 	<< j/nr_of_steps.to_f
		array_S 	<< 0.to_f				
	end
	#puts array_a
	#puts array_S
	
	(0..nr_of_steps - 1).each do |j|													# iteration over the array_a
		(0..nr_of_coat_bins - 1).each do |i|											# iteration over the depth of the target
			array_g[i] 	= array_a[j] * array_f[i] + (1 - array_a[j]) * array_h[i]
			if array_g[i] == 0.0 														# takhle se formálně definuje 0 * ln(0) = 0
				array_S[j] = 0
			else
				array_S[j]	= array_S[j] - (array_g[i] * Math.log(array_g[i]) * bin_width)
			end
		end

		puts "a: #{array_a[j]}      S: #{array_S[j]}"
	end
	# puts array_a
	# puts "---"
	# puts array_LS
	# puts "---"
	# puts array_PS
	# puts "---"
	# puts array_difference_LS_PS
	# puts "---"
	# puts array_SDEV
	# puts "---"
	# puts array_SDEV.min
	print "nr_of_steps:"
	puts nr_of_steps
	# print "index for min. value:"
	# puts array_difference_LS_PS.index { |x| x == array_difference_LS_PS.min }  
	print "a for max. value:"
	puts array_a[array_S.index { |x| x == array_S.max } ]
	# print "index for max. value:"
	# puts array_difference_LS_PS.index { |x| x == array_difference_LS_PS.max }  
	# print "a for max. value:"
	# puts array_a[array_difference_LS_PS.index { |x| x == array_difference_LS_PS.max } ]
	puts "---"
end
#-------------------------------------------------------------------------------------------------------------------------------------