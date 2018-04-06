Projet de Recherche opérationnelle 2018
GUEGUEN Ronan - GODET Antoine / 684I

La fonction appelée est la fonction main(), elle appelle à son tour la fonction scriptTSP() et la fonction scriptApprochee() appelant respectivement les fonctions de résolution exacte et résolution approchée pour chaque fichiers de données de plat et relief (seulement de plat dans la cas de la résolution approchée).

Comme la résolution exacte prend très longtemps pour les grands fichiers, il est possible de mettre l'appel de scriptTSP() en commentaire afin de passer directement à l'appel de scriptApprochee
