
#= GUEGUEN - Ronan
   GODET - Antoine
=#

using JuMP, GLPKMathProgInterface


#= Nombreuses autres fonctions à ajouter =#
function analyseSolution(m::JuMP.Model)
	return true
end

function returnTranslation(m::JuMP.Model)
	t = getvalue(m[:x])
	n = length(t[1,:])

	translations = Array{Int}(n)

	for i in 1:n
		for j in 1:n
			if (t[i,j] == 1)
				translations[i] = j
			end
		end
	end

	return translations
end

#= fonction findIndex retournant l'index d'un element dans une liste=#
function findIndice(a::Array{Int}, b::Int)
	for i in 1:length(a)
		if a[i] == b
			return i
		end
	end
end


function findCycle(translation::Array{Int})

	#= Truc à return =#
	cycles = Array{Array{Int}}(0)

	#= Ce tableau sert à stocker les indices des noeuds qui n'ont pas encore été gérés... =#
	indices = Array{Int}(length(translation))

	#= ...il est donc complet au début =#
	for i in 1:length(translation)
		indices[i] = i
	end

	#= Création des cycles =#
	while(length(indices) != 0)
		cycleFind = false
		listeToAdd = Array{Int}(0)

		NoeudEnCours = translation[indices[1]]
		while(cycleFind == false)
			push!(listeToAdd, NoeudEnCours)

			#= Fait un système de tapis roulant =#
			indToDelete = findIndice(indices, NoeudEnCours)
			deleteat!(indices,indToDelete)

			#= On regarde s'il y a un cycle =#
			if(translation[NoeudEnCours] in listeToAdd)
				cycleFind = true
			end

			NoeudEnCours = translation[NoeudEnCours]
		end

		push!(cycles, listeToAdd)
	end

	return cycles
end

#= fonction retournant la bonne fonction affine =#
function createAff(cycleFound::Array{Int}, m::JuMP.Model)
	x = m[:x]
	expr = AffExpr()
	
	for i in 1:length(cycleFound)
		push!(expr,1.0,x[cycleFound[i],cycleFound[(i % length(cycleFound))+1]])
	end
	
	return expr
end
		
		
#= procedure de destruction de sous cycle =#
#= TODO: verifier le fonctionnement =#
function ajoutContrainte(cycle::Array{Array{Int}}, m::JuMP.Model)

	min = length(cycle[1])
    x = m[:x]

	for i in 1:length(cycle)
		if (min > length(cycle[i]))
			min = i
		end
	end

    cycleFound = cycle[min]

    #cons = @constraint(m,sum(x[cycleFound[i],cycleFound[(i+1) mod length(cycleFound)]] for i in 1:length(cycleFound)) <= (length(cycleFound)-1))

	expr = createAff(cycleFound, m)
	@constraint(m, expr <= (length(cycleFound)-1))
end



#=
   .
   .
   .
=#


# Fonction de résolution exacte du problème de voyageur de commerce, dont le distancier est passé en paramètre=#

function TSP(C::Array{Int,2})

	# Déclaration d'un modèle (initialement vide)
	m = Model(solver = GLPKSolverMIP())

	# Nombre de spots
	n = length(C[1,:])

	# Déclaration des variables
	@variable(m, x[1:n,1:n], Bin)
	#Xij = 1 si le drône se rend du lieu i au lieu j ; 0 sinon

	# Déclaration de la fonction objective
	@objective(m, Min, (sum(C[i,j]*x[i,j] for i in 1:n for j in 1:n)))

	@constraint(m, trajetDestination[i = 1:n], sum(x[i,j] for j in 1:n if j != i) == 1)
	@constraint(m, trajetSource[j = 1:n], sum(x[i,j] for i in 1:n if i != j) == 1)


	#Solvation#
	
	status = solve(m)
	
	t = findCycle(returnTranslation(m))
	
	while length(t) > 1
		ajoutContrainte(t, m)
		status = solve(m)
		t = findCycle(returnTranslation(m))
	end




	if status == :Optimal
		println("Problème résolu à l'optimalité")

		println("z = ",getobjectivevalue(m)) # affichage de la valeur optimale

		# affichage des valeurs du vecteur de variables issues du modèle
		println("x = ",getvalue(m[:x]))

		println("-------\n Avec comme cycle :")
		println(findCycle(returnTranslation(m)))

	elseif status == :Unbounded
		println("Problème non-borné")

	elseif status == :Infeasible
		println("Problème impossible")
	end

end


#= Fonction qui résout l'ensemble des instances du projet avec la méthode de résolution exacte,
   le temps d'exécution de chacune des instances est mesuré =#

function scriptTSP()
    # Première exécution sur l'exemple pour forcer la compilation si elle n'a pas encore été exécutée
    C = parseTSP("plat/exemple.dat")
    TSP(C)

    # Série d'exécution avec mesure du temps pour les instances symétriques
    for i in 10:10:150
        file = "plat/plat" * string(i) * ".dat"
        C = parseTSP(file)
        println("Instance à résoudre : plat",i,".dat")
        @time TSP(C)
    end

    # Série d'exécution avec mesure du temps pour les instances asymétriques
    for i in 10:10:150
        file = "relief/relief" * string(i) * ".dat"
        println("Instance à résoudre : relief",i,".dat")
        C = parseTSP(file)
        @time TSP(C)
    end
end

# fonction qui prend en paramètre un fichier contenant un distancier et qui retourne le tableau bidimensionnel correspondant

function parseTSP(nomFichier::String)
    # Ouverture d'un fichier en lecture
    f = open(nomFichier,"r")

    # Lecture de la première ligne pour connaître la taille n du problème
    s = readline(f) # lecture d'une ligne et stockage dans une chaîne de caractères
    tab = parse.(Int,split(s," ",keep = false)) # Segmentation de la ligne en plusieurs entiers, à stocker dans un tableau (qui ne contient ici qu'un entier)
    n = tab[1]

    # Allocation mémoire pour le distancier
    C = Array{Int,2}(n,n)

    # Lecture du distancier
    for i in 1:n
        s = readline(f)
        tab = parse.(Int,split(s," ",keep = false))
        for j in 1:n
            C[i,j] = tab[j]
        end
    end

    # Fermeture du fichier
    close(f)

    # Retour de la matrice de coûts
    return C
end







m = TSP(parseTSP("relief/relief10.dat"))



#=
t = findCycle(returnTranslation(m))
i = length(t)

while i > 1 && status == :Optimal
	status = ajoutContrainte(t, m)
	solve(m);
	t = findCycle(returnTranslation(m))
  i = length(t)
end
=#




