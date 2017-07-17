require 'fileutils'									# nástroje pro práci se soubory
require 'pp'										# výpis hashů v hezčím tvaru
require 'json'										# knihovna pro práci s datovým formátem JSON
require 'active_support/core_ext/enumerable.rb'		# umožňuje array.sum
require 'benchmark'									# měření výpočetního času

gnuplot = 	"\"C:/Program Files (x86)/gnuplot/bin/gnuplot.exe\""
trim = 		"\"C:/Users/vacla/Downloads/SRIM-2013/TRIM.exe\""
#----------------------------------------------------------------------------
#--------------------------------- METHODS ----------------------------------
#----------------------------------------------------------------------------

def image_path_correction (folder_images, name_image)
	outdata = File.read("#{folder_images}/#{name_image}").gsub("#{folder_images}/#{name_image.split(".")[0]}", "Img/#{name_image.split(".")[0]}")
	File.open("#{folder_images}/#{name_image}", "w") {|out|	out << outdata} 
end	


def change_TRIM_mode(auto_or_normal)
	file_TRIMAUTO = 	"TRIMAUTO"

	if auto_or_normal == "auto"
		string = IO.read(file_TRIMAUTO)						# change TRIMAUTO from normal to auto mode
		string[0] = "1"
		File.open(file_TRIMAUTO, "w") { |output| output.puts string}
	end

	if auto_or_normal == "normal"
		string = IO.read(file_TRIMAUTO)						# change TRIMAUTO from auto to normal mode
		string[0] = "0"
		File.open(file_TRIMAUTO, "w") { |output| output.puts string}
	end

	if auto_or_normal != "auto" and auto_or_normal != "normal"
		puts "ERROR in the change_TRIM_mode method - wrong input in argument - use \"auto\" or \"normal\" in argument"
	end
end	

#-------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------      TASKS      ------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------

desc "creates the file 'simulation_settings' which coantains coating types and all irradiation parameters to be performed"
task :_01_simulation_settings do
	folder_data = 					"myData"
	file_simulation_settings = 		"#{folder_data}/simulation_settings"

	simulation_settings = {
		"Ti2AlC" => {
			"array_Ion_Energies" =>	[1700, 3400, 3000, 6000],		# ion energies [keV] to be performed
			"number_of_ions" => 	200.to_s,						# number of ions in the simulation
			"coat_width" => 		30000.to_s,						# coating layer width [A]; 1 micron = 10 000 A
			"clad_width" => 		60000.to_s,						# cladding layer width [A]; 1 micron = 10 000 A
			"hash_Ions" => {										# hash of all desired incident ions	 	
					"He" => {
						"name" =>			"He4",				
						"proton_nr_Z" =>	"2",				
						"mass_nr_A" =>		"4",				
						},
					"O" => {
						"name" =>			"O16",				
						"proton_nr_Z" =>	"8",				
						"mass_nr_A" =>		"16",				
						},
					"Si" => {
						"name" =>			"Si28",				
						"proton_nr_Z" =>	"14",				
						"mass_nr_A" =>		"28",				
						},
					"Fe" => {
						"name" => 			"Fe56",				
						"proton_nr_Z" =>	"26",				
						"mass_nr_A" =>		"56",				
						},
					"Ni" => {
						"name" => 			"Ni58",				
						"proton_nr_Z" =>	"28",				
						"mass_nr_A" =>		"58",				
						}
					}
			},

		"FeCrAl" => {
			"array_Ion_Energies" =>	[1700, 3400, 3000, 6000],		# ion energies [keV] to be performed
			"number_of_ions" => 	300.to_s,						# number of ions in the simulation
			"coat_width" => 		30000.to_s,						# coating layer width [A]; 1 micron = 10 000 A
			"clad_width" => 		60000.to_s,						# cladding layer width [A]; 1 micron = 10 000 A
			"hash_Ions" => {										# hash of all desired incident ions	 	
					"He" => {
						"name" =>			"He4",				
						"proton_nr_Z" =>	"2",				
						"mass_nr_A" =>		"4",				
						},
					"O" => {
						"name" =>			"O16",				
						"proton_nr_Z" =>	"8",				
						"mass_nr_A" =>		"16",				
						},
					"Si" => {
						"name" =>			"Si28",				
						"proton_nr_Z" =>	"14",				
						"mass_nr_A" =>		"28",				
						},
					"Fe" => {
						"name" => 			"Fe56",				
						"proton_nr_Z" =>	"26",				
						"mass_nr_A" =>		"56",				
						},
					"Ni" => {
						"name" => 			"Ni58",				
						"proton_nr_Z" =>	"28",				
						"mass_nr_A" =>		"58",				
						}
					}
			},
		}

	data = Marshal.dump(simulation_settings)									# The marshaling library converts collections of Ruby objects into a byte stream, allowing them to be stored outside the currently active script (e.g. in an external file to be loaded again later)
	
	File.open(file_simulation_settings, 'wb') do |output| 						# data in the "marshal format" are saved into the file simulation_settings
		output.puts data 
	end
	
	# data2 = Marshal.load(File.open(file_simulation_settings, 'rb').read)		# this is how the data are loaded from an external file in a "marshal format"
	# pp data2
	# puts data2["Ti2AlC"]["array_Ion_Energies"]
end
#-------------------------------------------------------------------------------------------------------------------------------------

desc "creates input files based on the file 'simulation_settings'"
task :_02_simulation_inputs do
	folder_data = 					"myData"
	file_simulation_settings = 		"#{folder_data}/simulation_settings"

	simulation_settings = Marshal.load(File.open(file_simulation_settings, 'rb').read)		# simulation_settings is a hash containing all data from the file_simulation_settings		

	simulation_settings.each do |coat, data|												# coat is name of a coating, e.g. "FeCrAl", "Ti2SiC"...; data is a hash containing simulation settings for each coating type
		puts coat
		#pp data

		folder_inputs = 		"#{folder_data}/Inputs_#{coat}"
		template_TRIM_IN = 		"#{folder_data}/template_input_#{coat}.IN"					# SRIM-2013/TRIM.IN is the input file from which TRIM reads instructions when a calcutilation is executed in the auto mode

		array_Ion_Energies = 	data["array_Ion_Energies"]			 						# ion energies [keV] to be performed
		number_of_ions = 		data["number_of_ions"]					 					# number of ions in the simulation
		coat_width = 			data["coat_width"]											# coating layer width [A]; 1 micron = 10 000 A
		clad_width = 			data["clad_width"]											# cladding layer width [A]; 1 micron = 10 000 A
		hash_Ions =				data["hash_Ions"]											# hash of all desired incident ions
	
		#puts array_Ion_Energies

		FileUtils.remove_dir(folder_inputs, true) if File.exists?(folder_inputs) 			# removes previous inputs; we want to get rid of old inputs -> we remove folder of inputs and then create it again; second argument (true) has to be used for removing non-empty folder
		FileUtils.mkdir(folder_inputs) 
		template = IO.read(template_TRIM_IN)

		array_Ion_Energies.each do |tag_energy|												# creating inputs based on the template
			eng = tag_energy.to_s
			hash_Ions.each do |id, record|
				name = 			hash_Ions[id] ["name"]
				proton_nr_Z = 	hash_Ions[id] ["proton_nr_Z"]
				mass_nr_A =		hash_Ions[id] ["mass_nr_A"]

				File.open("#{folder_inputs}/#{coat}_#{name}_#{eng}keV.IN", "w") do |output|
					output.puts template.sub("{ion_Z}", proton_nr_Z).sub("{ion_A}", mass_nr_A).sub("{ion_eng}", eng).sub("{number_of_ions}", number_of_ions).sub("{ion_name}", "#{name} (#{proton_nr_Z},#{mass_nr_A.to_i - proton_nr_Z.to_i})").sub("{coat_width}", coat_width).sub("{clad_width}", clad_width)
				end
			end
		end
	end
end
#-------------------------------------------------------------------------------------------------------------------------------------

desc "executes all input files created by :simulation_inputs based on the file 'simulation_settings'"
task :_03_simulation_run do 																	# executes all input files from #{folder_data}/Inputs_#{coat} and stores the output files *_VACANCY.txt and *_IONIZ.txt to the output folder
	folder_data = 					"myData"
	file_simulation_settings = 		"#{folder_data}/simulation_settings"

	simulation_settings = Marshal.load(File.open(file_simulation_settings, 'rb').read)		# simulation_settings is a hash containing all data from the file_simulation_settings		

	simulation_settings.each do |coat, data|												# coat is name of a coating, e.g. "FeCrAl", "Ti2SiC"...; data is a hash containing simulation settings for each coating type
		folder_inputs = 	"#{folder_data}/Inputs_#{coat}"
		folder_outputs = 	"#{folder_data}/Outputs_#{coat}"
		folder_current = 	Dir.getwd	
		file_TRIM_IN = 		"TRIM.IN"
		file_VACANCY = 		"#{folder_current}/VACANCY.txt"									# output file listing vacancies created during irradiation
		file_IONIZ = 		"#{folder_current}/IONIZ.txt"									# output file describing energy lost to ionization

		FileUtils.mkdir("#{folder_outputs}") unless File.exists?("#{folder_outputs}")
		change_TRIM_mode("auto")															# change TRIM mode to auto
		File.rename(file_TRIM_IN, "TRIM_backup.IN")											# create backup of the original TRIM.IN

		Dir["#{folder_inputs}/*.IN"].each do |input|
			puts input

			FileUtils.cp(input, folder_current)												# copy input from Inputs folder to folder_current (which is the one where trim is installed and TRIM.IN file placed)
			input_basename = input.strip.split("/").last	
			File.rename(input_basename, "TRIM.IN")											# rename the input file to TRIM.IN (TRIM.IN is the file used as input to TRIM.EXE)
			
			system("#{trim}")																# run TRIM

			FileUtils.cp(file_VACANCY, folder_outputs)										# move VACANCY.txt to folder_outputs and rename it
			File.rename("#{folder_outputs}/VACANCY.txt", "#{folder_outputs}/#{input_basename.split(".").first}_VACANCY.txt")	
			FileUtils.cp(file_IONIZ, folder_outputs)										# move IONIZ.txt to folder_outputs and rename it
			File.rename("#{folder_outputs}/IONIZ.txt", "#{folder_outputs}/#{input_basename.split(".").first}_IONIZ.txt")	

			FileUtils.rm("TRIM.IN")															# remove the file TRIM.IN which was just executed
		end	

		File.rename("TRIM_backup.IN", "TRIM.IN")											# rename the backup TRIM.IN file
		change_TRIM_mode("normal")															# chane TRIM mode to normal (manual)
	end
end
#-------------------------------------------------------------------------------------------------------------------------------------

desc "processing of simulation outputs; to be executed before :simulation_dpa and :simulation_results"
task :_04_simulation_outputs do
	folder_data = 					"myData"
	file_simulation_settings = 		"#{folder_data}/simulation_settings"

	simulation_settings = Marshal.load(File.open(file_simulation_settings, 'rb').read)		# simulation_settings is a hash containing all data from the file_simulation_settings		

	simulation_settings.each do |coat, data|												# coat is name of a coating, e.g. "FeCrAl", "Ti2SiC"...; data is a hash containing simulation settings for each coating type
		folder_outputs = 	"#{folder_data}/Outputs_#{coat}"
		folder_images = 	"#{folder_outputs}/Img"

		# -------------------------------------------------------------------------------------------------------------------
		# --------------------------------------   *_VACANCY.TXT   ----------------------------------------------------------
		# -------------------------------------------------------------------------------------------------------------------
		# processiong of *_VACANCY.txt output file in the folder_outputs
		# creating *_VACANCY.dat in the folder_outputs
		Dir["#{folder_outputs}/*_VACANCY.txt"].each do |file_VACANCY|						
			file_VACANCY_basename = file_VACANCY.strip.split("/").last.split(".").first
			puts file_VACANCY_basename

			ion_name = ""						# e.g. O, Fe, ..
			ion_eng = 0
			coat_width = 0 						# tohle je prostě napsaný tak aby to fungovalo; if it looks stupid but it works it ain't stupid
			clad_width = 0
			array_Vacancies_by_Ions = []
			array_Vacancies_by_Recoils = []

			File.open("#{folder_outputs}/#{file_VACANCY_basename}.dat", "w") do |output|
				output.puts "#TARGET_DEPTH[A]  VACANCIES_BY_IONS[Vacancies/(Angstrom*Ion)]  VACANCIES_BY_RECOILS[Vacancies/(Angstrom*Ion)]"	
				tag_index = 999999				# sem jsem nahulváta fouknul nějaký velký číslo, aby to fungovalo; nemělo by dojít k problému, soubor samotný máš vždy jen 100 řádků s hodnotami, protože terč je vždy rozdělen na 100 úseků
				File.foreach(file_VACANCY).with_index do |line, line_nr|
					if line.include?("keV")
						ion_name = line.strip.split("=")[1].strip.split[0]				# ion name, e.g. Fe
						ion_eng =  line.strip.split("=")[2].strip.split[0]				# ion energy [keV]
					end		
					if line.include?("Layer Width =") and coat_width == 0 				# problém je, že ten soubor osahuje řádek s textem 'Layer Width =' pro každou vrstvu (tedy coat i clad), takže je potřeba nějak rozlišit, ke které vrstvě daný řádek patří (proto jsem na začátku nastavil coat_width = clad_width = 0 a teď mám v ifu 2 podmínky)
						coat_width = line.strip.split("=").last.strip.split("A").first.strip.gsub! ',', '.'		
						if coat_width.include?(".E")									# tohle tady musí být, protože pokud je číslo zapsáno ve tvaru 500.E-1, tak 500.E-1 = 500, kdežto 500.0E-1 = 50			
							coat_width = coat_width.gsub! '.E','.0E' 					# width of coat layer [A]
						end
					end
					if line.include?("Layer Width =") and coat_width != 0
						clad_width = line.strip.split("=").last.strip.split("A").first.strip.gsub! ',', '.'		
						if clad_width.include?(".E")									
							clad_width = clad_width.gsub! '.E','.0E' 					# width of clad layer [A]
						end
					end
					if line.include?("   TARGET     VACANCIES     VACANCIES") 
						tag_index = line_nr + 3
					end
					if line_nr > tag_index and array_Vacancies_by_Ions.size < 100 		# ta druhá podmínka v if je taky pěkná prasárna. bylo potřeba zajistit, aby se do pole nenašetl poslední řádek tabulky, který neobsahoval data, ale string ' To convert to Energy Lost - multiply by Average Binding Energy =  0  eV/Vacancy'
						output.puts line.strip.gsub! ',', '.'							# copy results table to *_VACANCY.dat
						array_Vacancies_by_Ions << line.strip.split[1]
						array_Vacancies_by_Recoils << line.strip.split[2]
					end			
				end
			end	
			# -----------------------------------------------------------------------------------------------------------------
			# integrating the overall number of vacancies per 1 incident ion based on the file *_VACANCY.txt
			#pp array_Vacancies_by_Ions								
			array_Vacancies_by_Ions.each do |string|
				string = string.gsub! ',', '.'						# change comma to decimal point
			end
			array_Vacancies_by_Ions.collect! {|i| i.to_f}			# convert to floats
			#pp array_Vacancies_by_Ions								# [vacancies/(Angstrom*Ion)]

			array_Vacancies_by_Recoils.each do |string|
				string = string.gsub! ',', '.'						# change comma to decimal point
			end
			array_Vacancies_by_Recoils.collect! {|i| i.to_f}		# convert to floats
			#pp array_Vacancies_by_Recoils							# [vacancies/(Angstrom*Ion)]

			array_Vacancies_by_both = [array_Vacancies_by_Ions,array_Vacancies_by_Recoils].transpose.map{|a| a.sum}   # adding elements of these two arrays [vacancies/(Angstrom*Ion)]
			array_Vacancies_by_both = array_Vacancies_by_both.map { |value|  value * (coat_width.to_f + clad_width.to_f)/100} # nr. of vacancies per incident ion [vacancies/(Ion)] = nr. of vacancies per incident ion in each bin[vacancies/(Angstrom*Ion)] * bin_width   ;the target is divided into 100 equally wide bins; the width of each bin is (coat_width.to_f + clad_width.to_f)/100
			number_Vacancies = array_Vacancies_by_both.sum			# [vacancies/(Ion)] (sum over all bins)
			puts "nr. of vacancies per 1 incident ion based on _VACANCY.txt: #{number_Vacancies}"

			# -----------------------------------------------------------------------------------------------------------------
			# plot for each _VACANCY.dat
			File.open("#{folder_outputs}/#{file_VACANCY_basename}.gp", "w") do |output|				
				output.puts "set title \"\\\\ce{#{coat}} + Zircaloy--4, Vacancies produced per incident ion\""
				output.puts "set xlabel \"Target depth [$\\\\SI{}{\\\\um}$]\""
				output.puts "set ylabel \"Vacancies/($\\\\rm \\\\AA \\\\cdot \\\\: ion$) [$\\\\rm 1/\\\\AA$]\""
				output.puts "set xrange [0:#{coat_width.to_f/10000} + #{clad_width.to_f/10000}]"	# divided by 10 000 to get from angstroms to microns
				# following two lines draw a line at the border of coat and clad
				# first plot is necessary to abtain the value GPVAL_Y_MAX, which is upper yrange
				# see http://stackoverflow.com/questions/7330161/how-to-access-gnuplots-autorange-values-and-modify-them-to-add-some-margin 
				output.puts "plot \"#{folder_outputs}/#{file_VACANCY_basename}.dat\" using ($1/10000):($2 + $3) with boxes notitle"
				output.puts "set arrow from #{coat_width.to_f/10000},0 to #{coat_width.to_f/10000},GPVAL_Y_MAX nohead lw 3 lc rgb 'red'"
				# following two lines add labels denoting coating and cladding part of plot
				output.puts "set label 1 at #{coat_width.to_f/10000}, (GPVAL_Y_MAX - GPVAL_Y_MIN)*0.1 \'   clad\' textcolor rgb 'black' left front"
				output.puts "set label 2 at #{coat_width.to_f/10000}, (GPVAL_Y_MAX - GPVAL_Y_MIN)*0.1 \'coat   \' textcolor rgb 'black' right front"
				output.puts "set style fill transparent solid 0.5 noborder"

				output.puts "set terminal png"
				output.puts "set output \"#{folder_images}/#{file_VACANCY_basename}.png\""
				output.puts "plot \"#{folder_outputs}/#{file_VACANCY_basename}.dat\" using ($1/10000):($2 + $3) with boxes title \"\\\\ce{#{ion_name}}, #{ion_eng.to_f/1000} MeV\""
				
				# output.puts "set terminal cairolatex pdf colortext"
				# output.puts "set output \"#{folder_images}/#{file_VACANCY_basename}.tex\""
				# output.puts "plot \"#{folder_outputs}/#{file_VACANCY_basename}.dat\" using ($1/10000):($2 + $3) with boxes title \"\\\\ce{#{ion_name}}, #{ion_eng.to_f/1000} MeV\""
			end
			system("#{gnuplot} #{folder_outputs}/#{file_VACANCY_basename}.gp")	
			# image_path_correction(folder_images, "#{file_VACANCY_basename}.tex")
			FileUtils.rm("#{folder_outputs}/#{file_VACANCY_basename}.gp")
			# -----------------------------------------------------------------------------------------------------------------

		end

		# -----------------------------------------------------------------------------------------------------------------
		# --------------------------------------   IONIZ.TXT   ------------------------------------------------------------
		# -----------------------------------------------------------------------------------------------------------------
		# processiong of *_IONIZ.txt output file in the folder_outputs
		# creating *_IONIZ.dat in the folder_outputs
		Dir["#{folder_outputs}/*_IONIZ.txt"].each do |file_IONIZ|
			file_IONIZ_basename = file_IONIZ.strip.split("/").last.split(".").first
			puts file_IONIZ_basename

			ion_name = ""						# e.g. O, Fe, ..
			ion_eng = 0
			coat_width = 0 						# tohle je prostě napsaný tak aby to fungovalo; if it looks stupid but it works it ain't stupid
			clad_width = 0
			array_Ioniz_by_Ions = []
			array_Ioniz_by_Recoils = []

			File.open("#{folder_outputs}/#{file_IONIZ_basename}.dat", "w") do |output|
				output.puts "#TARGET_DEPTH[A]  IONIZ._BY_IONS[eV/(Angstrom*Ion)]  IONIZ._BY_RECOILS[eV/(Angstrom*Ion)]"	
				tag_index = 999999				# sem jsem nahulváta fouknul nějaký velký číslo, aby to fungovalo; nemělo by dojít k problému, soubor samotný máš vždy jen 100 řádků s hodnotami, protože terč je vždy rozdělen na 100 úseků
				File.foreach(file_IONIZ).with_index do |line, line_nr|
					if line.include?("Energy =") 
						ion_name = line.strip.split("=")[1].strip.split[0]				# ion name, e.g. Fe
						ion_eng = line.strip.split("=")[2].strip.split[0]				# ion energy [keV]
					end		
					if line.include?("Layer Width =") and coat_width == 0 				# problém je, že ten soubor osahuje řádek s textem 'Layer Width =' pro každou vrstvu (tedy coat i cladd), takže je potřeba nějak rozlišit, ke které vrstvě daný řádek patří (proto jsem na začátku nastavil coat_width = clad_width = 0)
						coat_width = line.strip.split("=").last.strip.split("A").first.strip.gsub! ',', '.'		
						if coat_width.include?(".E")									# width of coat layer [A]
							coat_width = coat_width.gsub! '.E','.0E' 					# tohle tady musí být, protože pokud je číslo zapsáno ve tvaru 500.E-1, tak 500.E-1 = 500, kdežto 500.0E-1 = 50
						end
					end
					if line.include?("Layer Width =") and coat_width != 0
						clad_width = line.strip.split("=").last.strip.split("A").first.strip.gsub! ',', '.'		# width of clad layer [A]
						if clad_width.include?(".E")
							clad_width = clad_width.gsub! '.E','.0E' 
						end
					end
					if line.include?("  TARGET       IONIZ.       IONIZ.  ") 
						tag_index = line_nr + 3
					end
					if line_nr > tag_index 
						output.puts line.strip.gsub! ',', '.'
						array_Ioniz_by_Ions << line.strip.split[1]
						array_Ioniz_by_Recoils << line.strip.split[2]
					end			
				end
			end		
			# -----------------------------------------------------------------------------------------------------------------
			# calculating the overall nr. of vacancies based on the ionization energy per 1 incident ion based on the file *_IONIZ.txt
			array_Ioniz_by_Ions.each do |string|
				string = string.gsub! ',', '.'
			end
			array_Ioniz_by_Ions.collect! {|i| i.to_f}			# convert to floats
			#pp array_Ioniz_by_Ions								# [eV/(Angstrom*Ion)]
			array_Ioniz_by_Recoils.each do |string|
				string = string.gsub! ',', '.'
			end
			array_Ioniz_by_Recoils.collect! {|i| i.to_f}		# convert to floats
			#pp array_Ioniz_by_Recoils							# [eV/(Angstrom*Ion)]
			array_Ioniz_by_both = [array_Ioniz_by_Ions,array_Ioniz_by_Recoils].transpose.map{|a| a.sum}   # adding elements of these two arrays
			array_Ioniz_by_both = array_Ioniz_by_both.map { |value|  value * (coat_width.to_f + clad_width.to_f)/100} # [eV/Ion]
			# ion_eng [keV] se musí přenásobit 1000 -> eV
			number_Vacancies = (ion_eng.to_f*1000 - array_Ioniz_by_both.sum) * 0.8 /(2*28)		# číslo na konci je E_d [eV] - nutno vyplnit manuálně nějakou rozumnou hodnotu!
			puts "nr. of vacancies per ion from ionization = #{number_Vacancies}"
			# -----------------------------------------------------------------------------------------------------------------
			# plot for each _IONIZ.dat
			File.open("#{folder_outputs}/#{file_IONIZ_basename}.gp", "w") do |output|				
				output.puts "set title \"\\\\ce{#{coat}} + Zircaloy--4, Vacancies produced per incident ion\""
				output.puts "set xlabel \"Target depth [$\\\\SI{}{\\\\um}$]\""
				output.puts "set ylabel \"Ionization/($\\\\rm \\\\AA \\\\cdot \\\\: ion$) [$\\\\rm eV/\\\\AA$]\""			# IONIZ._BY_IONS&RECOILS[eV/(Angstrom*Ion)]
				output.puts "set xrange [0:#{coat_width.to_f/10000} + #{clad_width.to_f/10000}]"	# divided by 10 000 to get from angstroms to microns
				# following two lines draw a line at the border of coat and clad
				# first plot is necessary to abtain the value GPVAL_Y_MAX, which is upper yrange
				# see http://stackoverflow.com/questions/7330161/how-to-access-gnuplots-autorange-values-and-modify-them-to-add-some-margin 
				output.puts "plot \"#{folder_outputs}/#{file_IONIZ_basename}.dat\" using ($1/10000):($2 + $3) with boxes notitle"
				output.puts "set arrow from #{coat_width.to_f/10000},0 to #{coat_width.to_f/10000},GPVAL_Y_MAX nohead lw 3 lc rgb 'red'"
				# following two lines add labels denoting coating and cladding part of plot
				output.puts "set label 1 at #{coat_width.to_f/10000}, (GPVAL_Y_MAX - GPVAL_Y_MIN)*0.1 \'   clad\' textcolor rgb 'black' left front"
				output.puts "set label 2 at #{coat_width.to_f/10000}, (GPVAL_Y_MAX - GPVAL_Y_MIN)*0.1 \'coat   \' textcolor rgb 'black' right front"
				output.puts "set style fill transparent solid 0.5 noborder"

				output.puts "set terminal png"
				output.puts "set output \"#{folder_images}/#{file_IONIZ_basename}.png\""
				output.puts "plot \"#{folder_outputs}/#{file_IONIZ_basename}.dat\" using ($1/10000):($2 + $3) with boxes title \"\\\\ce{#{ion_name}}, #{ion_eng.to_f/1000} MeV\""
				
				# output.puts "set terminal cairolatex pdf colortext"
				# output.puts "set output \"#{folder_images}/#{file_IONIZ_basename}.tex\""
				# output.puts "plot \"#{folder_outputs}/#{file_IONIZ_basename}.dat\" using ($1/10000):($2 + $3) with boxes title \"\\\\ce{#{ion_name}}, #{ion_eng.to_f/1000} MeV\""
			end
			system("#{gnuplot} #{folder_outputs}/#{file_IONIZ_basename}.gp")	
			# image_path_correction(folder_images, "#{file_IONIZ_basename}.tex")
			FileUtils.rm("#{folder_outputs}/#{file_IONIZ_basename}.gp")
			# -----------------------------------------------------------------------------------------------------------------
		end
	end
end
#-------------------------------------------------------------------------------------------------------------------------------------

desc "creates dpa outputs and plots based on :simulation_outputs"
task :_05_simulation_dpa do
	folder_data = 					"myData"
	file_simulation_settings = 		"#{folder_data}/simulation_settings"

	simulation_settings = Marshal.load(File.open(file_simulation_settings, 'rb').read)		# simulation_settings is a hash containing all data from the file_simulation_settings		

	simulation_settings.each do |coat, data|												# coat is name of a coating, e.g. "FeCrAl", "Ti2SiC"...; data is a hash containing simulation settings for each coating type
		folder_outputs = 	"#{folder_data}/Outputs_#{coat}"
		folder_images = 	"#{folder_outputs}/Img"
		
		# -------------------------------------------------------------------------------------------------------------------
		# --------------------------------------   DPA.dat & plot  ----------------------------------------------------------
		# -------------------------------------------------------------------------------------------------------------------
		Dir["#{folder_outputs}/*_VACANCY.txt"].each do |file_VACANCY|
			file_VACANCY_basename = file_VACANCY.strip.split("/").last.split(".").first
			file_DPA_basename = file_VACANCY_basename.gsub 'VACANCY','DPA'
			puts file_DPA_basename

			ion_name = ""						# e.g. O, Fe, ..
			ion_eng = 0
			coat_width = 0 						# tohle je prostě napsaný tak aby to fungovalo; if it looks stupid but it works it ain't stupid
			clad_width = 0
			coat_at_density = 0 				# [atoms/cm3]
			clad_at_density = 0 				# [atoms/cm3]
			
			File.foreach(file_VACANCY).with_index do |line, line_nr|
				if line.include?("keV")													# e.g. " Ion    = Fe   Energy = 1700 keV"
						ion_name = line.strip.split("=")[1].strip.split[0]				# ion name, e.g. "Fe"
						ion_eng =  line.strip.split("=")[2].strip.split[0]				# ion energy [keV], e.g. "1700"
				end		

				if line.include?("Layer Width =") and coat_width == 0 				# problém je, že ten soubor osahuje řádek s textem 'Layer Width =' pro každou vrstvu (tedy coat i cladd), takže je potřeba nějak rozlišit, ke které vrstvě daný řádek patří (proto jsem na začátku nastavil coat_width = clad_width = 0)
					coat_width = line.strip.split("=").last.strip.split("A").first.strip.gsub! ',', '.'		# width of coat layer [A], e.g. "3.E+04"
					if coat_width.include?(".E")									
						coat_width = coat_width.gsub! '.E','.0E' 					# tohle tady musí být, protože pokud je číslo zapsáno ve tvaru 500.E-1, tak 500.E-1 = 500, kdežto 500.0E-1 = 50
					end
					coat_width = coat_width.to_f
				end

				if line.include?("Layer Width =") and coat_width != 0
					clad_width = line.strip.split("=").last.strip.split("A").first.strip.gsub! ',', '.'		# width of clad layer [A]
					if clad_width.include?(".E")
						clad_width = clad_width.gsub! '.E','.0E' 
					end
					clad_width = clad_width.to_f
				end

				if line.include?("Density =") and coat_at_density == 0 
					coat_at_density = line.strip.split("=")[1].strip.split[0]
					if coat_at_density.include?(".E")
						coat_at_density = coat_at_density.gsub! '.E','.0E' 
					end
					coat_at_density = coat_at_density.to_f
				end

				if line.include?("Density =") and coat_at_density != 0 
					clad_at_density = line.strip.split("=")[1].strip.split[0]
					if clad_at_density.include?(".E")
						clad_at_density = clad_at_density.gsub! '.E','.0E' 
					end
					clad_at_density = clad_at_density.to_f 
				end			
			end

			File.open("#{folder_outputs}/#{file_DPA_basename}.dat", "w") do |output|
				output.puts "#TARGET_DEPTH[A]  DPA/FLUENCE[dpa*cm2/Ion]"
				# (flux)*(SRIM output)/(atomic density) = dpa/s
				# see https://www.researchgate.net/post/How_can_I_calculate_the_dpa_displacement_per_atom_in_metal
				File.foreach("#{folder_outputs}/#{file_VACANCY_basename}.dat").with_index do |line, line_nr|
					if line_nr > 0 and line.strip.split[0].to_f <= coat_width		# skip first line (header)
						output.print line.strip.split[0] + "       "
						output.puts (line.strip.split[1].to_f + line.strip.split[2].to_f) * 10**8 / coat_at_density   # násobení 10**8=> vacancies/(A*ion) -> vacancies/(cm*ion); coat_at_density [atoms/cm3]
					end														
					if line_nr > 0 and line.strip.split[0].to_f > coat_width		# skip first line (header)
						output.print line.strip.split[0] + "       "
						output.puts (line.strip.split[1].to_f + line.strip.split[2].to_f) * 10**8 / clad_at_density
					end
				end
			end	
			# -----------------------------------------------------------------------------------------------------------------
			# plot for each *_DPA.dat
			File.open("#{folder_outputs}/#{file_DPA_basename}.gp", "w") do |output|	
				output.puts "set title \"\\\\ce{#{coat}} + Zircaloy--4, dpa per fluence\""
				output.puts "set xlabel \"Target depth [$\\\\SI{}{\\\\um}$]\""
				output.puts "set ylabel \"dpa per fluence [$\\\\rm dpa \\\\cdot cm^2 / ion$]\""
				output.puts "unset ytics"	# setting y tics on the right side of the plot to avoid the collison with ylabel text
				output.puts "set y2tics"
				output.puts "set xrange [0:#{coat_width.to_f/10000} + #{clad_width.to_f/10000}]"	# width divided by 10 000 to get from angstroms to microns
				# following two lines draw a line at the border of coat and clad
				# first plot is necessary to abtain the value GPVAL_Y_MAX, which is upper yrange
				# see http://stackoverflow.com/questions/7330161/how-to-access-gnuplots-autorange-values-and-modify-them-to-add-some-margin 
				output.puts "plot \"#{folder_outputs}/#{file_DPA_basename}.dat\" using ($1/10000):2 with boxes notitle"
				output.puts "set arrow from #{coat_width.to_f/10000},0 to #{coat_width.to_f/10000},GPVAL_Y_MAX nohead lw 3 lc rgb 'red'"
				# following two lines add labels denoting coating and cladding part of plot
				output.puts "set label 1 at #{coat_width.to_f/10000}, (GPVAL_Y_MAX - GPVAL_Y_MIN)*0.1 \'   clad\' textcolor rgb 'black' left front"
				output.puts "set label 2 at #{coat_width.to_f/10000}, (GPVAL_Y_MAX - GPVAL_Y_MIN)*0.1 \'coat   \' textcolor rgb 'black' right front"
				output.puts "set style fill transparent solid 0.5 noborder"

				output.puts "set terminal png"
				output.puts "set output \"#{folder_images}/#{file_DPA_basename}.png\""
				output.puts "plot \"#{folder_outputs}/#{file_DPA_basename}.dat\" using ($1/10000):2 with boxes title \"\\\\ce{#{ion_name}}, #{ion_eng.to_f/1000} MeV\""
				
				# output.puts "set terminal cairolatex pdf colortext"
				# output.puts "set output \"#{folder_images}/#{file_DPA_basename}.tex\""
				# output.puts "plot \"#{folder_outputs}/#{file_DPA_basename}.dat\" using ($1/10000):2 with boxes title \"\\\\ce{#{ion_name}}, #{ion_eng.to_f/1000} MeV\""
			end
			system("#{gnuplot} #{folder_outputs}/#{file_DPA_basename}.gp")	
			# image_path_correction(folder_images, "#{file_DPA_basename}.tex")
			FileUtils.rm("#{folder_outputs}/#{file_DPA_basename}.gp")
			# -----------------------------------------------------------------------------------------------------------------
		end
	end
end
#-------------------------------------------------------------------------------------------------------------------------------------

desc "creates results for all simulations"
task :simulation_results do
	folder_data = 					"myData"
	file_simulation_settings = 		"#{folder_data}/simulation_settings"

	simulation_settings = Marshal.load(File.open(file_simulation_settings, 'rb').read)		# simulation_settings is a hash containing all data from the file_simulation_settings		

	simulation_settings.each do |coat, data|												# coat is name of a coating, e.g. "FeCrAl", "Ti2SiC"...; data is a hash containing simulation settings for each coating type
		folder_outputs = 	"#{folder_data}/Outputs_#{coat}"
		folder_images = 	"#{folder_data}/Img"
		folder_paper_images = "C:/Users/vacla/Downloads/SRIM-2013/myData/00results_final_final"
		
		coat_width = data["coat_width"]				
		clad_width = data["clad_width"]		

		FileUtils.mkdir(folder_images) unless File.exists?(folder_images)
		# -----------------------------------------------------------------------------------------------------------------
		# plot DPA results
		hash_cases = {}
		Dir["#{folder_outputs}/*_DPA.dat"].each do |file_DPA|
			file_DPA_basename = file_DPA.strip.split("/").last.split(".").first
			target = file_DPA_basename.split("_")[0]			# "FeCrAl"
			ion = 	 file_DPA_basename.split("_")[1]			# e.g. "Fe56"
			energy = file_DPA_basename.split("_")[2]			# "3000keV"
			#puts energy
			hash_cases[target] = {} unless hash_cases.has_key?(target)
			hash_cases[target] [ion] = [] unless hash_cases[target].has_key?(ion)
			hash_cases[target] [ion] << energy.to_i				# ion energy [keV]
		end
		pp hash_cases											# hash_cases = {"Ti2AlC"=>{"Fe56"=>[1700, 3000, 3400, 6000], "He4"=>[1700, 3000, 3400, 6000], "Ni58"=>[1700, 3000, 3400, 6000], "O16"=>[1700, 3000, 3400, 6000], "Si28"=>[1700, 3000, 3400, 6000]}}
		puts "....."
		pp simulation_settings[coat]							# hash_simulatioun_settings["Ti2AlC"] = {"array_Ion_Energies"=>[1700, 3400, 3000, 6000], "number_of_ions"=>"200", "coat_width"=>"30000", "clad_width"=>"60000", "hash_Ions"=> {"He"=>{"name"=>"He4", "proton_nr_Z"=>"2", "mass_nr_A"=>"4"}, "O"=>{"name"=>"O16", "proton_nr_Z"=>"8", "mass_nr_A"=>"16"}, "Si"=>{"name"=>"Si28", "proton_nr_Z"=>"14", "mass_nr_A"=>"28"}, "Fe"=>{"name"=>"Fe56", "proton_nr_Z"=>"26", "mass_nr_A"=>"56"}, "Ni"=>{"name"=>"Ni58", "proton_nr_Z"=>"28", "mass_nr_A"=>"58"}}}
		puts "---------------"

		hash_cases[coat].each do |ion, array_energy|			# ion is a string, e.g. "Fe56", energy in keV is an ARRAY! of integers
			#jeden graf pro každý typ iontu
			File.open("#{folder_outputs}/#{coat}_#{ion}_DPA.gp", "w") do |output|	
				output.puts "set title \"\\\\ce{#{coat}} + Zircaloy--4, dpa per fluence\""
				output.puts "set xlabel \"Target depth [$\\\\SI{}{\\\\um}$]\""
				output.puts "set ylabel \"dpa per fluence [$\\\\rm dpa \\\\cdot cm^2 / ion$]\""
				output.puts "unset ytics"	# setting y tics on the right side of the plot to avoid the collison with ylabel text
				output.puts "set y2tics"	
				output.puts "set xrange [0:#{coat_width.to_f/10000} + #{clad_width.to_f/10000}]"	# divided by 10 000 to get from angstroms to microns
				# following two lines draw a line at the border of coat and clad
				# first plot is necessary to obtain the value GPVAL_Y_MAX, which is upper yrange
				# see http://stackoverflow.com/questions/7330161/how-to-access-gnuplots-autorange-values-and-modify-them-to-add-some-margin 
				output.puts "plot \\"
				array_energy.each do |energy|
					output.puts "  \"#{folder_outputs}/#{coat}_#{ion}_#{energy}keV_DPA.dat\" using ($1/10000):2, \\"
				end
				output.puts "                "		# je potřeba vložit řádek bez pokrařovacích lomítek
				output.puts "set arrow from #{coat_width.to_f/10000},0 to #{coat_width.to_f/10000},GPVAL_Y_MAX nohead lw 3 lc rgb 'red'"
				# following two lines add labels denoting coating and cladding part of plot
				output.puts "set label 1 at #{coat_width.to_f/10000}, (GPVAL_Y_MAX - GPVAL_Y_MIN)*0.1 \'   clad\' textcolor rgb 'black' left front"
				output.puts "set label 2 at #{coat_width.to_f/10000}, (GPVAL_Y_MAX - GPVAL_Y_MIN)*0.1 \'coat   \' textcolor rgb 'black' right front"
				output.puts "set style fill transparent solid 0.4 noborder"
				output.puts "set terminal png"
				output.puts "set output \"#{folder_outputs}/#{coat}_#{ion}_DPA.png\""
				output.puts "plot \\"
				array_energy.each do |energy|
					output.puts "  \"#{folder_outputs}/#{coat}_#{ion}_#{energy}keV_DPA.dat\" using ($1/10000):2 with boxes title \"\\\\ce{#{ion.scan(/[a-zA-Z]/).join}}, #{energy.to_f/1000} MeV\", \\"
				end
				output.puts "                "		# je potřeba vložit řádek bez pokrařovacích lomítek
				output.puts "set terminal cairolatex pdf colortext"
				output.puts "set output \"#{folder_images}/#{coat}_#{ion}_DPA.tex\""
				output.puts "plot \\"
				array_energy.each do |energy|
					output.puts "  \"#{folder_outputs}/#{coat}_#{ion}_#{energy}keV_DPA.dat\" using ($1/10000):2 with boxes title \"\\\\ce{#{ion.scan(/[a-zA-Z]/).join}}, #{energy.to_f/1000} MeV\", \\"
				end
				output.puts "                "		# je potřeba vložit řádek bez pokrařovacích lomítek
			end
			system("#{gnuplot} #{folder_outputs}/#{coat}_#{ion}_DPA.gp")	
			image_path_correction(folder_images, "#{coat}_#{ion}_DPA.tex")
		end
		# -----------------------------------------------------------------------------------------------------------------
		# latex file with all result plots
		File.open("#{folder_images}/#{coat}_all_results_DPA.tex", "w") do |output|
			hash_cases["#{coat}"].each do |ion, array_energy|
				output.puts "             "
				output.puts "\\begin{figure}[h!]"
				output.puts "\\begin{center}"
				output.puts "\\resizebox{1\\linewidth}{!}{\\input{Img/#{coat}_#{ion}_DPA}}"
				output.puts "\\caption{DPA production by #{ion.scan(/[a-zA-Z]/).join} ion irradiation of \\ce{#{coat}} coating deposited on Zircaloy--4 cladding.}"
				output.puts "\\end{center}"
				output.puts "\\end{figure}"
				output.puts "             "
			end
		end
		# copy all the files from outputs/Img to paper/Img
		#Dir.foreach(folder_images) {|file| FileUtils.cp(file, folder_paper_images)}
		Dir["#{folder_images}/*"].each do |file|
			puts file
			FileUtils.cp(file, folder_paper_images)
		end
	end
end
#-------------------------------------------------------------------------------------------------------------------------------------






#-------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------      FISSION PRODUCTS TRANSPORT      ---------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------
# require 'C:/Users/vacla/Downloads/SRIM-2013/Rakefile_fission_products.rb'

#-------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------      COATINGS     ----------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------
# require 'C:/Users/vacla/Downloads/SRIM-2013/Rakefile_Ti2AlC.rb'
# require 'C:/Users/vacla/Downloads/SRIM-2013/Rakefile_Ti3SiC2.rb'
# require 'C:/Users/vacla/Downloads/SRIM-2013/Rakefile_FeCrAl_test.rb'
# require 'C:/Users/vacla/Downloads/SRIM-2013/Rakefile_PCD.rb'

#-------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------      OPTIMIZATION     --------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------
require 'C:/Users/vacla/Downloads/SRIM-2013/Rakefile_optimization_simple.rb'
require 'C:/Users/vacla/Downloads/SRIM-2013/Rakefile_optimization_genetic_2beams.rb'
require 'C:/Users/vacla/Downloads/SRIM-2013/Rakefile_optimization_genetic_3beams.rb'
require 'C:/Users/vacla/Downloads/SRIM-2013/Rakefile_optimization_genetic_5beams.rb'


#-------------------------------------------------------------------------------------------------------------------------------------
