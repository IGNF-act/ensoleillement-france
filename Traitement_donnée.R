##################### 
Code pour extraire des données de METEO France les données d'ensoleillement agrégé par an entre 2015 et 2023.
######################

##### Tout les fichiers   Automatique
library(readr)
library(dplyr)
library(sf)
library(tidyr)

# Chemin vers le dossier contenant les fichiers donnée de Meteo France
dossier <- ""

# Lister tous les fichiers MENSQ_*.csv dans le dossier
fichiers <- list.files(path = dossier, pattern = "^MENSQ_.*\\.csv$", full.names = TRUE)

# Initialiser une liste pour stocker les résultats de chaque fichier
resultats_par_fichier <- list()

# Boucle sur chaque fichier
for (fichier in fichiers) {
  # Lire le fichier
  data <- read_csv2(fichier)%>%
    mutate(
      LAT = as.numeric(LAT) / 1e6,
      LON = as.numeric(LON) / 1e6
    )
  
  # Nettoyage des données
  data <- data[, c("NUM_POSTE", "NOM_USUEL", "LAT", "LON", "ALTI", "AAAAMM", "INST", "QINST", "NBINST")]
  
  # Supprimer les lignes où INST est NA ou vide
  data <- data %>%
    filter(!is.na(INST), INST != "")
  
  # Garder uniquement les données depuis 2015 et QINST != 2
  data <- data %>%
    filter(AAAAMM >= 201501 & QINST != 2)

  # Vérifier que min_AAAAMM = 201501 pour chaque NOM_USUEL
  result <- data %>%
    group_by(NOM_USUEL) %>%
    summarise(
      min_AAAMM = min(AAAAMM, na.rm = TRUE),
      max_AAAMM = max(AAAAMM, na.rm = TRUE)
    )
  
  valid_usuel <- result %>%
    filter(min_AAAMM == 201501 & max_AAAMM == 202312) %>%
    pull(NOM_USUEL)
  
  data <- data %>%
    filter(NOM_USUEL %in% valid_usuel)
  
  # Ajouter un champ pour l'insolation en heures
  data <- data %>%
    mutate(INS_H = INST / 60)
  
  # Vérifier que tous les mois sont complets (12 mois par année)
  count_station <- data %>%
    group_by(NOM_USUEL) %>%
    summarise(n_lignes = n(), .groups = "drop")
  
  stations_supprimer <- count_station %>%
    filter(n_lignes %% 12 != 0) %>%
    pull(NOM_USUEL)
  
  data <- data %>%
    filter(!(NOM_USUEL %in% stations_supprimer))
  
  # Extraire l'année depuis AAAAMM
  data <- data %>%
    mutate(AAAAMM = as.character(AAAAMM),
           year = substr(AAAAMM, 1, 4))
  
  # Agrégation par année et par station
  insolation_annee <- data %>%
    group_by(NOM_USUEL, year) %>%
    summarise(
      LAT = first(LAT),
      LON = first(LON),
      ALTI = first(ALTI),
      total_INS_H = sum(INS_H, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(NOM_USUEL, year)
  
  # Vérifier qu'on a bien 9 années (2015-2023) par station
  count_years <- insolation_annee %>%
    group_by(NOM_USUEL) %>%
    summarise(n_years = n(), .groups = "drop")
  
  stations_valides <- count_years %>%
    filter(n_years == 9) %>%
    pull(NOM_USUEL)
  
  insolation_annee <- insolation_annee %>%
    filter(NOM_USUEL %in% stations_valides)
  
  
  # Calcul de la moyenne d'insolation par année et par station
  moyennes_annuelles <- insolation_annee %>%
    group_by(NOM_USUEL, year) %>%
    summarise(
      moyenne_annuelle_INS_H = mean(total_INS_H, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    pivot_wider(
      names_from = year,
      values_from = moyenne_annuelle_INS_H,
      names_prefix = "moyenne_"
    )
  
  ###Tableau final.
  moyenne_globale <- insolation_annee %>%
    group_by(NOM_USUEL) %>%
    summarise(
      LAT = first(LAT),
      LON = first(LON),
      ALTI = first(ALTI),
      moyenne_TOTAL_INS_H = mean(total_INS_H, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(NOM_USUEL)
  
  # Fusion des deux tableaux
  moyenne_insolation <- left_join(moyenne_globale, moyennes_annuelles, by = "NOM_USUEL")
  
  # Ajouter le nom du fichier comme identifiant
  moyenne_insolation$fichier <- basename(fichier)
  
  # Stocker le résultat dans la liste avec le nom du fichier comme clé
  resultats_par_fichier[[basename(fichier)]] <- moyenne_insolation
}

# Afficher les noms des fichiers traités
names(resultats_par_fichier)

# Exemple : Accéder au résultat pour un fichier spécifique
resultats_par_fichier[["MENSQ_01_previous-1950-2023.csv"]




###### On met tout dans le même tableau

# Initialiser un tableau vide pour stocker tous les résultats
moyenne_insolation_combinee <- tibble()

# Boucle pour traiter chaque fichier dans resultats_par_fichier
for (nom_fichier in names(resultats_par_fichier)) {
  # Extraire le tableau du fichier courant
  resultat_fichier <- resultats_par_fichier[[nom_fichier]]
  
  # Corriger les colonnes LAT et LON (uniquement si |LAT| < 1 ou |LON| < 1)
  resultat_fichier <- resultat_fichier %>%
    mutate(
      LAT = ifelse(abs(LAT) < 1, as.numeric(LAT) * 1e6, as.numeric(LAT)),
      LON = ifelse(abs(LON) < 1, as.numeric(LON) * 1e6, as.numeric(LON))
    )
  
  # Ajouter le nom du fichier comme colonne
  resultat_fichier$fichier <- nom_fichier
  
  # Combiner avec le tableau global
  moyenne_insolation_combinee <- bind_rows(moyenne_insolation_combinee, resultat_fichier)
}

# Afficher le tableau combiné
head(moyenne_insolation_combinee)

### Conversion en objet spatial
moyenne_insolation_sf <- moyenne_insolation_combinee %>%
  st_as_sf(coords = c("LON", "LAT"), crs = 4326)  # CRS 4326 = WGS84 (lat/lon)

# En lambert 93 
moyenne_insolation_lambert <- st_transform(moyenne_insolation_sf, crs = 2154)

# Sauvegarder en GeoPackage
st_write(
  obj = moyenne_insolation_lambert,
  dsn = "C:/Users/ctychyj/Desktop/Clément/Carto_et_idée/Ensoleillement france/Ensoleillement/moyenne_insolation_lambert_toute_année.gpkg",  # Chemin et nom du fichier
  layer = "moyenne_insolation",              # Nom de la couche dans le GeoPackage
  driver = "GPKG"                            # Format GeoPackage
)
