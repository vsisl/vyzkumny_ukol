require 'pp'
require 'active_support/core_ext/enumerable.rb'									# array.sum

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

# method for inicializing the population with individuals with random values of genes a,b...
def initialize_population_4beams (population, population_size)
	(0..population_size - 1).each do |i|
		a = Kernel.rand.to_f 
		b = Kernel.rand.to_f
		c = Kernel.rand.to_f
		d = Kernel.rand.to_f
				
		sum = a + b + c + d
		
		population[i][0] = a/sum						
		population[i][1] = b/sum
		population[i][2] = c/sum
		population[i][3] = d/sum
	end

	puts "------- Initial population (random) -----------"
	pp   population
	puts
	puts
	puts
	puts

	return population
end

# fitness method - expresses the quality of an individual; returns the SDEV float
def fitness_4beams (array_individual, array_A, array_B, array_C, array_D, nr_of_coat_bins)		# array_individual = [a, b, c, d]
	const_S1 = 		0.0
	const_S2 = 		0.0
	const_SDEV = 	0.0
	array_f = 		[]															# f(z) is the overall distribution of defects made by a sum of the first distribution A(z) and the second distribution B(z)
	
	a = array_individual[0]
	b = array_individual[1]
	c = array_individual[2]
	d = array_individual[3]

	(0..nr_of_coat_bins - 1).each do |i|										# iteration over the depth of the coating part of the target
		array_f[i] = 	a * array_A[i] + b * array_B[i]	+ c * array_C[i] + d * array_D[i]						# f(z) is the overall distribution of defects made by a sum of the first distribution A(z) and the second distribution B(z)
		const_S1 += 	array_f[i]											
		const_S2 += 	array_f[i]**2
	end

		# debugging
		if 1/(nr_of_coat_bins - 1).to_f * (const_S2/nr_of_coat_bins - (const_S1/nr_of_coat_bins)**2) < 0
			pp array_individual
			puts const_S2/nr_of_coat_bins
			puts (const_S1/nr_of_coat_bins)**2
			puts (const_S2/nr_of_coat_bins - (const_S1/nr_of_coat_bins)**2)
			puts 1/(nr_of_coat_bins - 1).to_f * (const_S2/nr_of_coat_bins - (const_S1/nr_of_coat_bins)**2)
		end		

	const_SDEV = Math.sqrt(1/(nr_of_coat_bins - 1).to_f * (const_S2/nr_of_coat_bins - (const_S1/nr_of_coat_bins)**2))	# standard deviation formula from MCNP
	# const_SDEV = (1/nr_of_coat_bins).to_f * Math.sqrt(nr_of_coat_bins * const_S2 - const_S1**2).to_f												# alternative formula for standard deviation
	# array_SDEV[i] = Math.sqrt((100 * array_S2[i] - array_S1[i]**2)/(100 * 99))												# alternative formula for standard deviation

	return 1/const_SDEV															# the lower standard deviation (const_SDEV) the better is the individual; we want to maximize fitness => returns 1/const_SDEV
end	
#----------------------------------------------------------------------------

# selection - choosing a random individual; "roulette selection"; returns the index of the individual from population, whose fitness is the closest the the randomly chosen finessPoint
def pick_random_individuum(array_fitness, sum_fitness, population_size)  		# array_fitness contains the fitness values of all individials in the population; sum_fitness = array_fitness.sum
	sum = 0.0
	fitnessPoint = Kernel.rand * sum_fitness									# random number from the interval 0, sum_fitness
	
	if sum_fitness == 0.0 														# method fails if all individuals in the population are the same and all have fitness = 0; in that case in returns a sequence of indexes (0..population_size - 1) instead of one integer index
		puts "WARNING: all individuals have fitness = 0, the pick_random_individuum method won't work"
	end

	(0..population_size - 1).each do |i|
		sum += array_fitness[i]
		if sum > fitnessPoint
			return i
		end
	end
end
#----------------------------------------------------------------------------

def optimization_plot_4beams(array_individual, file_DPA_1, file_DPA_2, file_DPA_3, file_DPA_4, folder_images, i_generation, coat_width, clad_width, nr_of_coat_bins, coating_type)
	gnuplot = 	"\"C:/Program Files (x86)/gnuplot/bin/gnuplot.exe\""

	FileUtils.mkdir(folder_images) unless File.exists?(folder_images)

	a = array_individual[0]
	b = array_individual[1]
	c = array_individual[2]
	d = array_individual[3]
	
	array_A = []
	array_B = []
	array_C = []
	array_D = []
		
	File.foreach(file_DPA_1).with_index do |line, line_nr|					# loading the first irradiation profile
		if line_nr > 0 														# skip firts line (header), index 0
			array_A << line.strip.split[1].to_f			
		end
	end

	File.foreach(file_DPA_2).with_index do |line, line_nr|					
		if line_nr > 0 														
			array_B << line.strip.split[1].to_f			
		end
	end

	File.foreach(file_DPA_3).with_index do |line, line_nr|					
		if line_nr > 0 														
			array_C << line.strip.split[1].to_f			
		end
	end

	File.foreach(file_DPA_4).with_index do |line, line_nr|					
		if line_nr > 0 														
			array_D << line.strip.split[1].to_f			
		end
	end

	array_x_axis = []

	File.foreach(file_DPA_1).with_index do |line, line_nr|					# loading the values of the depth in the target
		if line_nr > 0 														# skip firts line (header), index 0
			array_x_axis << line.strip.split[0]			
		end
	end

	# puts array_x_axis.size
	# puts array_A.size

	# creating a .dat file which includes the final damage distribution as a sum of 3 distributions
	File.open("#{folder_images}/Generace_#{i_generation}.dat", "w") do |output|
		array_x_axis.each_with_index do |x_axis, i|
			output.puts x_axis.to_s + "       " + (a * array_A[i] + b * array_B[i] + c * array_C[i] + d * array_D[i]).to_s
		end
	end

	File.open("#{folder_images}/Generace_#{i_generation}.gp", "w") do |output|	
		output.puts "set title \"\\\\ce{#{coating_type}} + Zircaloy--4, dpa per fluence\""
		output.puts "set xlabel \"Target depth [$\\\\SI{}{\\\\um}$]\""
		output.puts "set ylabel \"dpa per fluence [$\\\\rm dpa \\\\cdot cm^2 / ion$]\""
		output.puts "unset ytics"	# setting y tics on the right side of the plot to avoid the collison with ylabel text
		output.puts "set y2tics"
		output.puts "set xrange [0:#{coat_width.to_f/10000} + #{clad_width.to_f/10000}]"	# width divided by 10 000 to get from angstroms to microns
		# following two lines draw a line at the border of coat and clad
		# first plot is necessary to abtain the value GPVAL_Y_MAX, which is upper yrange
		# see http://stackoverflow.com/questions/7330161/how-to-access-gnuplots-autorange-values-and-modify-them-to-add-some-margin 
		output.puts "plot \"#{folder_images}/Generace_#{i_generation}.dat\" using ($1/10000):2 with boxes notitle"
		output.puts "set arrow from #{coat_width.to_f/10000},0 to #{coat_width.to_f/10000},GPVAL_Y_MAX nohead lw 3 lc rgb 'red'"
		# following two lines add labels denoting coating and cladding part of plot
		output.puts "set label 1 at #{coat_width.to_f/10000}, (GPVAL_Y_MAX - GPVAL_Y_MIN)*0.1 \'   clad\' textcolor rgb 'black' left front"
		output.puts "set label 2 at #{coat_width.to_f/10000}, (GPVAL_Y_MAX - GPVAL_Y_MIN)*0.1 \'coat   \' textcolor rgb 'black' right front"
		output.puts "set style fill transparent solid 0.5 noborder"

		output.puts "set terminal png"
		output.puts "set output \"#{folder_images}/Generace_#{i_generation}.png\""
		output.puts "plot \"#{folder_images}/Generace_#{i_generation}.dat\" using ($1/10000):2 with boxes title \"Gen. #{i_generation}, a = #{a.round(3)}, b = #{b.round(3)}, c = #{c.round(3)}, d = #{d.round(3)}\""
		
		# output.puts "set terminal cairolatex pdf colortext"
		# output.puts "set output \"#{folder_images}/#{file_DPA_basename}.tex\""
		# output.puts "plot \"#{folder_images}/#{file_DPA_basename}.dat\" using ($1/10000):2 with boxes title \"\\\\ce{#{ion_name}}, #{ion_eng.to_f/1000} MeV\""
	end
	system("#{gnuplot} #{folder_images}/Generace_#{i_generation}.gp")	
	# image_path_correction(folder_images, "#{file_DPA_basename}.tex")
	FileUtils.rm("#{folder_images}/Generace_#{i_generation}.gp")
end
#----------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------      TASKS      ------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------

desc "optimization based on genetic algorithms, for 4 ion beams"
task :optimization_genetic_4beams do
	folder_data = 					"myData"
	file_simulation_settings = 		"#{folder_data}/simulation_settings"
	coating_type =					"CrN"
	folder_outputs = 				"#{folder_data}/Outputs_#{coating_type}"
	nr_of_beams =					4
	folder_images = 				"#{folder_outputs}/Img_optimalizace_#{nr_of_beams}beams"
	file_DPA_1 =					"#{folder_outputs}/#{coating_type}_Ni58_3400keV_DPA.dat"
	file_DPA_2 =					"#{folder_outputs}/#{coating_type}_Ni58_6000keV_DPA.dat"
	file_DPA_3 =					"#{folder_outputs}/#{coating_type}_O16_3400keV_DPA.dat"
	file_DPA_4 = 					"#{folder_outputs}/#{coating_type}_Ni58_1700keV_DPA.dat"


	
	simulation_settings =			Marshal.load(File.open(file_simulation_settings, 'rb').read)		# simulation_settings is a hash containing all data from the file_simulation_settings
	coat_width = 					simulation_settings[coating_type]["coat_width"].to_f
	clad_width = 					simulation_settings[coating_type]["clad_width"].to_f
	bin_width = 					(coat_width + clad_width)/100 										# Delta_z [A]
	nr_of_coat_bins = 				((coat_width/(coat_width + clad_width)) * 100).to_i			

	array_A = []
	array_B = []
	array_C = []
	array_D = []
	
	array_A = load_irradiation_profile(file_DPA_1, nr_of_coat_bins)						# irradiation profile of the first beam
	array_B = load_irradiation_profile(file_DPA_2, nr_of_coat_bins)
	array_C = load_irradiation_profile(file_DPA_3, nr_of_coat_bins)
	array_D = load_irradiation_profile(file_DPA_4, nr_of_coat_bins)

	nr_of_genes =					nr_of_beams													# individual is described by its genes; [a, b]; the number of geses is equal to the number of ion beams used in irradiation
	cross_rate = 					1.0															# probability of crossing (křížení), typically 0.7 - 1
	mutation_rate = 				0.05														# probability of mutation of each gene; gene = parameter of an individual (a, b)
	population_size = 				800															# nr. of individuals in one population; must be even number!
	nr_of_generations = 			100															# nr. of populations in the simulation
	
	population = 					Array.new(population_size){Array.new(nr_of_genes)} 			# array population_size x nr. of genes (80x2); contains all individuals in the population
	population = 					initialize_population_4beams(population, population_size)	# creating an initiali population with random individuals	
	
	array_fitness =					[]															# will contain the fitness values of all individuals in the population
	
	puts "------- Start -----------"
	puts
	puts
	puts
	puts
	puts
	puts
	puts
	puts
	
	# the aim of the algorithm is to find an individual with the highest fitness (quality)
	# iteration over all generations; 1 generation = 1 population; each population contains individuals
	(0..nr_of_generations).each do |i_generation|										
		best_fitness = 			0.0
		best_fitness_index =	0
		new_population = 		Array.new(population_size){Array.new(nr_of_genes)}	# new_population will replace the current population at the end of the cycle
		min_fitness = 			Float::MAX											# highest possible float in ruby
		# min_fitness = 		Float::INFINITY 									# should work as well
		
		# calculate the fitness value for each individual in the population; keep the lowest and the highest fitness
		(0..population_size - 1).each do |i|
			array_fitness[i] = fitness_4beams(population[i], array_A, array_B, array_C, array_D, nr_of_coat_bins)		# calculating fitness funcition for each individual in the population
			
			if array_fitness[i] > best_fitness 										
				best_fitness = 			array_fitness[i]							# saving the value of the best fitness
				best_fitness_index = 	i 											# saving the index of an individual with the best fitness
			end
			
			if array_fitness[i] < min_fitness
				min_fitness = 			array_fitness[i]
			end
		end
		
		# linear transformation 			# Jsou-li hodnoty fitness vysoké, může se stát, že poměr fitness mezi nejhorším a nejlepším jedincem bude blízký jedné (např. 900:1000 = 0.9). Používáme-li selekci Roulette wheel selection, všichni jedinci budou mít na ruletě téměř stejné díly a dobří jedinci se tak nebudou moci prosadit mezi ostatními. Tento problém se dá řešit lineární transformací fitness, nová hodnota fitness je pak dána vztahem: f'=a*f+b, kde a a b jsou vhodné parametry. V minulém díle jsme např. fitness transformovali tak, že jsme od hodnoty fitness odečetli fitness nejhoršího jedince. Tento problém se ale dá vyřešit i použitím jiného typu selekce – Rank selection.
		# subtracts the value min_fitness from the fitness of each individual; => the fitness of each individual is from the range (0 - best_fitness-min_fitness); this makes the selection process better - the individual with the lowest fitness will be never chosen for crossing
		sum_fitness = 0.0
		
		(0..population_size - 1).each do |i|	
			array_fitness[i] -= 	0.999 * min_fitness 							# it is not possible to sumbtract the whole value of min_fitness - in that case, if all individuals in the population are the same, min_fitness = best_fitness => after the transformation, all individuals will have fitness equal to 0 and the method pick_random_individuum won't work
			sum_fitness += 			array_fitness[i]		
		end
		
		# creating a new population, which will replace the current population at the end of the cycle
		(0..population_size - 1).step(2) do |i_individuum|												# the cycle is repeated POPULATION_SIZE/2 - times; in each iteration, two random individuals are chosen for crossing; 2 descendant are created and saved into a new population
			
			# natural selection = random selection of two individuals which will enter crossing (and mutation)																			
			individuum_index_1 = pick_random_individuum(array_fitness, sum_fitness, population_size)	# randomly chosen individual 1
			individuum_index_2 = pick_random_individuum(array_fitness, sum_fitness, population_size) 	# randomly chosen individual 2
					
			# crossing of two randomly selected individuals
			if Kernel.rand < cross_rate																	# with the probability CROSS_RATE, the crossing is done; otherwise the chosen individuals from the old population are just copied to the new population 
				(0..nr_of_genes - 1).each do |gene_index|												# iteration over individual's genes: [a, b]
					if Kernel.rand < 0.5 																# the process of crossing: the value of each gene (values a and b) of the descendant is picked randomly either from the first or the second parent; in this way, two descendants new_population[i_individuum] and new_)opulation[i_individuum+1] are created																	
						new_population[i_individuum][gene_index] = 		population[individuum_index_1][gene_index]		 
						new_population[i_individuum + 1][gene_index] = 	population[individuum_index_2][gene_index]
					else
						new_population[i_individuum][gene_index] = 		population[individuum_index_2][gene_index]
						new_population[i_individuum + 1][gene_index] = 	population[individuum_index_1][gene_index]
					end

				end

				(0..1).each do |child|														# iteration over 2 descendants
					# mutation
					# after the crossing, mutation of both descendants follows; each gene of each descendant is modified with the probability of MUTATION_RATE; the gene is modified by adding a random value from a certain distribution (e.g. normal distribution); a small modification should be more common, than a large one
					(0..nr_of_genes - 1).each do |gene_index|
						if Kernel.rand < mutation_rate
							parameter = 0.01	
							random_value = parameter * Math.sqrt(-2 * Math.log(Kernel.rand)) * Math.sin(2 * Math::PI * Kernel.rand)		# distribution of mutation value
							new_population[i_individuum + child][gene_index] += random_value													
							
								# puts "------ Mutation -------"
								# puts "random_value: #{random_value}"
								# puts "gene: #{gene_index}"
								# pp 	 new_population[i_individuum + child]
								# puts "sum of genes: #{new_population[i_individuum + child].sum}"
								# puts "----- //Mutation ------"

							if new_population[i_individuum + child][gene_index] < 0 		# the value of genes a, b, c... must be positive
								puts "WARNING: new_population[#{i_individuum + child}][#{gene_index}] = #{new_population[i_individuum + child][gene_index]}; set to 0"
								new_population[i_individuum + child][gene_index] = 0
							end							
						end
					end					

					# after crossing it may happen that the sum of the genes a + b + c + ... is not equal to 0 (this happens regardless of mutation); therefore it is needed to normalize the values of genes
						# puts "------ Normalization after crossing ------"	
					sum_of_genes = new_population[i_individuum + child].sum 					# sum of all genes
						# pp new_population[i_individuum + child]
						# puts new_population[i_individuum + child].sum
					new_population[i_individuum + child].map! {|gene| gene/sum_of_genes} 		# normalization
						# pp 	 new_population[i_individuum + child]
						# puts "sum of genes: #{new_population[i_individuum + child].sum}"
						# puts "----- //Normalization after crossing -----"	
				end
			else # else = if Kernel.rand >= cross_rate
				# with the probability (1 - CROSS_RATE), there is no crossing; currently chosen 2 individuals are just pasted into the new population
				new_population[i_individuum] = 		population[individuum_index_1]
				new_population[i_individuum + 1] = 	population[individuum_index_2]
			end
		end # new population has been completed

		# elitism - artifitial preservation of the best individual; ensures, that the best individual will survive to the following population; enables a faster convergation to the optimal solution (optimal individual)
		new_population[0] = population[best_fitness_index]							# the best individual is pasted to the first position in the new population

		population = new_population													# current population is replaced by the new population

		puts "--------------------------------------------------------------------------------"
		puts "Generation" + i_generation.to_s + ", Best fitness:" + best_fitness.to_s + ", Best fitness index:" + best_fitness_index.to_s
		puts "Best individual: " + population[best_fitness_index].to_s
		puts "--------------------------------------------------------------------------------"
		puts
		puts
		
		# optimization_plot_4beams(population[best_fitness_index], file_DPA_1, file_DPA_2, file_DPA_3, file_DPA_4, folder_images, i_generation, coat_width, clad_width, nr_of_coat_bins, coating_type)
   end
end