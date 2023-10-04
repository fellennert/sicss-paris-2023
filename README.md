# Intro

This repository contains the code and slides used for teaching the 2023 edition of the Summer Institute in Computational Social Science at Institut Polytechnique de Paris. The R script can also be found in [bookdown form](https://bookdown.org/f_lennert/sicss-bookdown/). Relevant data sets are distributed via Dropbox, and code for directly loading them into the session is included in the scripts. Hence, no data needs to be downloaded upfront.

Make sure that you have installed a current version of R and RStudio before running the scripts. We are working with the `needs` package to take care of the installation of packages on the fly, so make sure that you have it installed. We assume familiarity with R and mostly follow the "tidy dialect." If you are entirely unfamiliar with this, you can find introductory material in the final section of the index file.

The scripts are ordered in the way the material is taught. Throughout the course, the theory behind the concepts will be introduced in the morning lectures, and the practical implementation in R in the afternoon sessions.

The following list connects the corresponding files:

* Day 1: intro to CSS and ethical considerations ([slides: Intro to CSS](slides/1.1-SICSS2023-WhatAreCSS.html), [slides: Ethical considerations](slides/1.2-SICSS2023-Ethics.html))
* Day 2: building crawlers ([slides: building crawlers](slides/2-SICSS2023-Crawlers.html), [R material setup](code/00-intro_setup.Rmd), [R material: crawlers and apis](code/01-crawlers_apis.Rmd))
* Day 3: scraping structured content from the web ([slides: structured scraping](slides/3-SICSS2023-Structured.html), [R material: scraping structured](code/02-scraping_structured.Rmd))
* Day 4: scraping unstructured content from the web ([slides](slides/3-SICSS2023-Structured.html), [R material](code/03-scraping_unstructured.Rmd))
* Day 5: NLP I ([slides](slides/5-SICSS2023-NLP1.pdf), [R material](code/04-text_preprocessing.Rmd))
* Day 6: NLP II ([slides](slides/6-SICSS2023-embeddings.pdf), [R material](code/05-ml.Rmd))
* Day 7: NLP III ([slides](slides/7-SICSS2023-transformers.pdf), [R material](code/06-word-embeddings.Rmd))
* Day 8: The Augmented Social Scientist (Google Colab)


The solutions to the exercises are included in the bookdown script but not in the "raw" RMD scripts.
