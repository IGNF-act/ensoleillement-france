# Ensoleillement en France entre 2015 et 2023  
**Données Météo-France – Traitements R – Cartographie IGN**

![Logo IGN](images/logo_ign.png)

##  Contexte du projet

Ce projet vise à analyser et cartographier l’évolution de l’**ensoleillement annuel en France métropolitaine entre 2015 et 2023**, à partir des **données mensuelles de Météo-France**, puis à produire des surfaces interpolées et des seuils d’heures d’ensoleillement exploitables dans un outil de cartographie grand public (Ma carte – IGN).

---

##  Source des données

Les données utilisées proviennent du portail officiel de diffusion des données publiques :

- **Météo-France – Données mensuelles d’insolation**
- Jeu de données :  
  https://meteo.data.gouv.fr/datasets/6569b3d7d193b4daf2b43edc

### Données téléchargées
- Tous les fichiers **MENSQ_*.csv**
- Pour **l’ensemble des départements**
- Période couvrant au minimum **2015 à 2023**

Le téléchargement a été effectué **en amont**, en dehors du script (les fichiers sont ensuite traités automatiquement).

---

##  Traitements réalisés dans le script R

Le script R permet une **chaîne de traitement complète et automatisée**, décrite ci-dessous.

### 1️ Sélection et filtrage des stations

Pour chaque fichier départemental :

- Conversion des coordonnées (LAT / LON)
- Conservation des champs utiles :
  - station, localisation, altitude
  - date (AAAAMM)
  - insolation mensuelle (INST)
  - indicateur de qualité (QINST)

#### Filtres appliqués :
- Période ≥ **janvier 2015**
- **Qualité des données** : `QINST != 2`
- Suppression des stations :
  - sans insolation renseignée
  - avec des mois manquants
  - ne disposant pas d’une série complète **2015–2023**

--> Seules les stations disposant de **9 années complètes (12 mois/an)** sont conservées.

---

### 2️ Agrégation annuelle de l’insolation

- Conversion de l’insolation de **minutes vers heures**
- Agrégation :
  - par **station**
  - par **année**

Produits intermédiaires :
- Total annuel d’insolation (en heures)
- Moyenne annuelle par station
- Moyennes annuelles détaillées pour chaque année entre **2015 et 2023**

---

### 3️ Production d’un jeu de données spatial

- Fusion de l’ensemble des départements
- Conversion en objet spatial (`sf`)
- Projection en **Lambert-93 (EPSG:2154)**
- Export final en **GeoPackage (GPKG)** contenant :
  - des **points** représentant les stations
  - leurs moyennes d’ensoleillement annuelles

---

### 4️ Interpolation spatiale et seuils d’ensoleillement

À partir du GeoPackage :

- Interpolation **IDW (Inverse Distance Weighting)**
- Passage d’une donnée **ponctuelle → surfacique**
- Extraction des **isovaleurs** d’ensoleillement :
  - 1750 h
  - 2000 h
  - 2250 h
  - etc.

Les rasters sont ensuite convertis en **polygones** afin de faciliter la lecture cartographique.

---

### 5️ Cartographie et mise en page (IGN)

La mise en forme finale est réalisée avec l’outil :

- **Ma carte – IGN**

Éléments intégrés :
- Données interpolées
- Polygones de seuils d’ensoleillement
- Mise en page cartographique
- Logo de l’IGN

---

##  Résultats et visualisation

###  Version web (GitHub Pages)
--> https://ctychyj.github.io/Ensoleillement_France_entre_2015_et_2023/

###  Version sur Ma carte (Ma carte – IGN)
--> https://macarte.ign.fr/carte/oPX2Q1/Evolution-de-l-ensoleillement-de-la-France-entre-2015-et-2023-atlas-v2

---

##  Technologies utilisées

- **R**
  - `dplyr`
  - `readr`
  - `tidyr`
  - `sf`
- **QGIS / outils SIG**
- **Ma carte – IGN**
- Formats :
  - CSV
  - GeoPackage (GPKG)
  - Raster / vecteur

---

##  Auteur

Projet réalisé par **Clément Tychyj**  


---

##  Licence et usage

- Données : © Météo-France (données publiques)
- Cartographie : IGN
- Code : usage libre à des fins de recherche, d’analyse et de visualisation (sous réserve de citation des sources)
- Licence ouverte Etalab 2.0

