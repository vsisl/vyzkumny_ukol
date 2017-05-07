require 'pp'

# metoda fitness - vyhodnocuje kvalitu jedince
def fitness (jedinec, array_f, array_h, nr_of_coat_bins)						#jedinec = [a, b]; na výstupu bude float SDEV
	const_S1 = 		0.0
	const_S2 = 		0.0
	const_SDEV = 	0.0
	array_g = 		[]
	
	(0..nr_of_coat_bins - 1).each do |i|											# iteration over the depth of the target; the target is divided into 100 bins
		array_g[i] 	= 	jedinec[0] * array_f[i] + jedinec[1] * array_h[i]	# g(z) is the overall distribution of defects made by a sum of the first distribution f(z) and the second distribution g(z)
		const_S1 += 	array_g[i]											
		const_S2 += 	array_g[i]**2
	end

	const_SDEV = Math.sqrt(1/(nr_of_coat_bins - 1).to_f * (const_S2/nr_of_coat_bins - (const_S1/nr_of_coat_bins)**2))	# standard deviation of the damage distribution for each parameter a; vztah z MCNP
	
	return 1/const_SDEV																	# čím menší const_SDEV, tím lepší jedinec. my ale potřebujeme maximalizovat fitness => vrací 1/const_SDEV
end	

#selekce - vybrání náhodného jedince na základě jeho fitness
# Jedinci s vyšší fitness budou mít vyšší šanci, že budou vybráni. Níže uvedená metoda provádí tzv. „Roulette selection“. //???? nikde nevidím, proč by měl jedinec s větší fitness větší šanci být vybrán
def pick_random_individuum(array_fitness, sum_fitness, population_size)  	# array_fitness je pole fitness všech jedinců v populaci; sum_fitness = array_fitness.sum; vrátí index i pro jedince v populaci, jehož fitness je nejblíž náhodně generované fitnessPoint
	sum = 0.0
	fitnessPoint = Kernel.rand * sum_fitness
	#puts fitnessPoint

	(0..population_size - 1).each do |i|
		sum += array_fitness[i]
		if sum > fitnessPoint
			return i
		end
	end
end









desc "optimization based on genetic algorithms"
task :optimization_genetic_2beams do
	folder_data = 					"myData"
	folder_outputs = 				"#{folder_data}/Outputs_FeCrAl"
	# file_DPA_1 =					"#{folder_outputs}/FeCrAl_Si28_1700keV_DPA.dat"
	# file_DPA_2 =					"#{folder_outputs}/FeCrAl_Si28_3000keV_DPA.dat"
	file_DPA_1 =					"#{folder_outputs}/test_1.dat"
	file_DPA_2 =					"#{folder_outputs}/test_2.dat"

	file_simulation_settings = "#{folder_data}/simulation_settings"
	simulation_settings =		Marshal.load(File.open(file_simulation_settings, 'rb').read)		# simulation_settings is a hash containing all data from the file_simulation_settings
	coat_width = 					simulation_settings["FeCrAl"]["coat_width"].to_f
	clad_width = 					simulation_settings["FeCrAl"]["clad_width"].to_f
	bin_width = 					(coat_width + clad_width)/100 						# Delta_z [A]
	nr_of_coat_bins = 			((coat_width/(coat_width + clad_width)) * 100).to_i			

	array_f = []
	array_h = []
	array_g = []
	
	File.foreach(file_DPA_1).with_index do |line, line_nr|
		if line_nr > 0 and line_nr < nr_of_coat_bins + 1			# skip firts line (header), index 0; load only tho coat bins
			array_f << line.strip.split[1].to_f*2			
		end
	end

	File.foreach(file_DPA_2).with_index do |line, line_nr|
		if line_nr > 0 and line_nr < nr_of_coat_bins + 1			# skip firts line (header), index 0; load only tho coat bins
			array_h << line.strip.split[1].to_f*2		
		end
	end

	cross_rate = 			1.0														# pravdepodobnost krizeni (typicky 0.7 - 1)
	mutation_rate = 		0.05														# pravdepodobnost mutace kazdeho genu; gen = parametr jedince (v tomto případě a, b, c...)
	population_size = 	80															# pocet jedincu v populaci
	nr_of_generations = 	20															# pocet populaci
	population = 			Array.new(population_size){Array.new(2)} 		# pole population_size x genotyp (80x2), float/double; obsahuje vsechny jedince v populaci
	#zaznam = []																		# pole genarations_nrm x population_size (500x80) integer; graf, ktery ukazuje, jak se populace vyviji v case

	# inicializace populace
	(0..population_size - 1).each do |i|
		population[i][0] = Kernel.rand									# toto je a
		population[i][1] = 1.0 - population[i][0]						# toto je b = 1 - a
	end
	
	array_fitness = [] 														# bude obsahovat fitness všech jedinců v populaci
	
	puts "-------Start-----------"
	puts
	puts
	puts
	puts
	puts
	puts
	puts
	puts
	puts
	(0..nr_of_generations).each do |i_generation|					# iterace přes všechny generace; každá generace obasuje populaci, která obsahuje jednotlivé jedince
		best_fitness = 		0.0
		best_fitness_index = 0
		new_population = 		Array.new(population_size){Array.new(2)}  # pole new_population, které ke konci cyklu nahradí stávající populaco - population
		min_fitness = 			Float::MAX											# nejvetší možný float v ruby
		# min_fitness = 		Float::INFINITY 									# takhle by to možná šlo taky
		
		# vypocet fitness pro kazdeho jedince v populaci, přitom si pamatujeme jedince s minimálním fitness a jedince s maximálním fitness.
		(0..population_size - 1).each do |i|
			array_fitness[i] = fitness(population[i], array_f, array_h, nr_of_coat_bins)		#def fitness (jedinec, array_f, array_h, nr_of_coat_bins)			#jedinec = [a, b]; na výstupu bude float 1/const_SDEV
			
			if array_fitness[i] > best_fitness
				best_fitness = array_fitness[i]
				best_fitness_index = i
			end
			
			if array_fitness[i] < min_fitness
				min_fitness = array_fitness[i]
			end
			
			#zaznam[i_generation][i] = (array_fitness[i] * 0.66).round 		# proč takhle???
		end
		
		# všechny zjištěné hodnoty fitness upravíme tak, že odečteme minimální fitness. Tím kvalitu jedinců dostaneme do rozsahu od 0 do bestFitness-minFitness. Tím se zlepší selekce – je zaručeno, že nejhorší jedinec nebude nikdy vybrán ke křížení.
		sum_fitness = 0.0
		
		(0..population_size - 1).each do |i|	
			array_fitness[i] -= 	min_fitness
			sum_fitness += 		array_fitness[i]		
		end
		
		# vytvoreni nove populace, ktera nahradi stavajici
		(0..population_size - 1).step(2) do |i_individuum|		# Cyklus opakujeme POPULATION_SIZE/2 krát. V každé iteraci vybereme náhodné 2 jedince ke křížení a vytvoříme místo nich 2 potomky, které uložíme do nové populace  newPopulation.
			# prirozeny vyber = náhodný výběr
			individuum_index_1 = pick_random_individuum(array_fitness, sum_fitness, population_size)	# náhodně vybranný jedinec 1
			individuum_index_2 = pick_random_individuum(array_fitness, sum_fitness, population_size) 	# náhodně vybranný jedinec 2
			
			if Kernel.rand < cross_rate		# S pravděpodobností CROSS_RATE provedeme křížení, jinak pouze zkopírujeme do nové populace již existující vybrané jedince.
				(0..1).each do |i|				# tady se iteruje přes parametry jedince [a, b]
					if Kernel.rand < 0.5 		# Křížení provedeme tak, že každou hodnotu genotypu potomka vybereme náhodně buď z prvního rodiče nebo druhého rodiče. Vzniknou tak dva potomci new_population[i_individuum] a  newPopulation[i_individuum+1].
						new_population[i_individuum][i] = 		population[individuum_index_1][i]
						new_population[i_individuum + 1][i] = 	population[individuum_index_2][i]
					else
						new_population[i_individuum][i] = 		population[individuum_index_2][i]
						new_population[i_individuum + 1][i] = 	population[individuum_index_1][i]
					end
				end
				
				# mutace
				# Po křížení se provede mutace obou potomků. V každém ze dvou potomků procházíme jejich genotyp (hodnoty a, b, ...) a s pravděpodobností MUTATION_RATE hodnotu v genotypu změníme tak, že přičteme náhodnou hodnotu dánou normálním rozdělením. S vyšší pravděpodobností dojde k malé změně hodnoty a s nižší pravděpodobností dojde k vyšší změně hodnoty. Nakonec zkontrolujeme, že hodnoty v genotypu splňují a + b + ... = 1
				(0..1).each do |child|			# tady se iteruje od 0 do 1 (ne přes parametry jedince)
					# *** tady si vytvořím xxx_sum = 0.0; sumu parametrů a + b + ...
					# ***
					# xxx_sum = 0.0
					(0..0).each do |i|			# tady se iteruje přes parametry jedince (počet parametrů - 1; poslední parametr se vypočítá jako 1 - ostatní parametry)
						if Kernel.rand < mutation_rate
							parameter = 0.01		# v příkladu s kružnicemi byl parametr = 8.0, to je hrozně moc, já potřebuju random_value malou
							random_value = parameter * Math.sqrt(-2 * Math.log(Kernel.rand)) * Math.sin(2 * Math::PI * Kernel.rand)	# tohle nechápu - normální rozdělení v tom nevidím		# náhodně generované číslo s normálním rozdělením - vysoká pravděpodobnost malé hodnoty, nízká pravděpodobnost vyšších hodnot
							puts "Mutace - random_value: #{random_value}"

							new_population[i_individuum + child][i] += random_value													
							
							if new_population[i_individuum + child][i] < 0
								new_population[i_individuum + child][i] = 0
							end

							if new_population[i_individuum + child][i] > 1
								puts "PROBLÉM"
								new_population[i_individuum + child][i] = 1
							end
						end
						# ***tady na tom místě ještě bude potřeba zkontrolovat, jestli součet dasavadních parametrů není větší než 1
						# xxx_sum += new_population[i_individuum + child][i]
						# ***
						# if xxx_sum > 1
						# 	new_population[i_individuum + child][i] = 0.0
						# end
					end
					puts "new_population[i_individuum + child][0]: #{new_population[i_individuum + child][0]}, class: #{new_population[i_individuum + child][0].class}"
					new_population[i_individuum + child][1] = 1.0 - new_population[i_individuum + child][0]		# b = 1 - a
				end
			else # else má roli if Kernel.rand >= cross_rate
				# s pravděpodobností (1 - cross rate) nedojde ke křížení - pouze zkopírujeme do nové populace dva stávající jedince
				(0..1).each do |i|			 # tady se iteruje přes parametry jedince
					new_population[i_individuum][i] = 		population[individuum_index_1][i]
					new_population[i_individuum + 1][i] = 	population[individuum_index_2][i]
				end
			end
		end # tímto byla vytvořena nová populace

		# elitismus - umělé zachování nejlepších jedinců. Zaručuje, že nejlepší jedinec se v populaci zachová. To umožňuje rychleji nalézt optimální řešení. Do nové populace na první řádek zkopírujeme nejlepšího jedince v minulé generaci.
		(0..1).each do |i| 			 # tady se iteruje přes parametry jedince
			new_population[0][i] = population[best_fitness_index][i]			
		end
		population = new_population
		puts "----------------------------------"
		puts "Generation" + i_generation.to_s + ", Best fitness:" + best_fitness.to_s + ", Best fitness index:" + best_fitness_index.to_s + ", Best a:" + population[best_fitness_index][0].to_s 
		puts "----------------------------------"
   
   end
end