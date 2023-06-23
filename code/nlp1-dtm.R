## SICSS Paris 2023
## Companion script to lecture NLP1 - From text to (big) matrices
## Julien Boelaert, 23/06/2023

## Text methods on "state of the union" dataset (240 presidential speeches)

library(ggplot2)
library(ggrepel)
library(quanteda)
library(sotu)

################################################################################
## Import the data
################################################################################

sotu_meta <- sotu_meta
sotu_text <- sotu_text

## Naming the documents: year _ president _ number
names(sotu_text) <- paste0(
  sotu_meta$year, "_",
  gsub("^(.)\\S+ (\\S+)$", "\\1_\\2",
       gsub("^(.)\\S+ (.?)\\S* (\\S+)$", "\\1_\\2_\\3", 
            sotu_meta$president)), 
  sotu_meta$X)




################################################################################
## (Option 1) Shortest pipeline with quanteda
################################################################################

## Tokenization into words
q_toks <- tokens(sotu_text)

## DTM
q_dtm <- dfm(q_toks, tolower = T)
dim(q_dtm)

# ## Visual inspection of DTM
# View(as.matrix(q_dtm[, 1:200]))
# View(as.matrix(q_dtm[, order(colSums(q_dtm), decreasing = T)][, 1:200]))

## Filtering on counts
q_dtm <- dfm_trim(q_dtm, min_docfreq = 5) # Keep terms that appear in at least 5 documents
dim(q_dtm)

## Weights: TF-IDF
q_tfidf <- dfm_tfidf(q_dtm, "logcount", "inverse")

# ## Visual inspection of TF-IDF
# View(as.matrix(q_tfidf[, order(colSums(q_tfidf), decreasing = T)][1:60, 1:200]))



################################################################################
## (Option 2) Full pipeline with quanteda
################################################################################

## Tokenization into words, with extra options
f_toks <- tokens(sotu_text, 
                 remove_punct = T, 
                 remove_numbers = T, 
                 remove_symbols = T)

## Consolidate on dictionary (important, benefits from long careful inspection)
f_toks <- tokens_lookup(
  f_toks, 
  exclusive = F, case_insensitive = T,
  dictionary(list("house_of_representatives" = "house of representatives", 
                  "USA" = c("United States", "United States of America"), 
                  "yolo" = "of the")))

## Remove stopwords from dictionary (careful with the dictionary!)
f_toks <- tokens_remove(f_toks, stopwords("en"))

## Use 1- and 2-grams
f_toks <- tokens_ngrams(f_toks, 1:2)

## DTM
f_dtm <- dfm(f_toks, tolower = T)
dim(f_dtm)

f_dtm [1:6, 1:5]

# ## Visual inspection of DTM
# View(as.matrix(f_dtm[, 1:200]))
# View(as.matrix(f_dtm[, order(colSums(f_dtm), decreasing = T)][, 1:200]))

## Filtering on counts
f_dtm <- dfm_trim(f_dtm, min_docfreq = 5) # Keep terms that appear in at least 5 documents
dim(f_dtm)
f_dtm <- dfm_trim(f_dtm, max_docfreq = 90, termfreq_type = "prop") # Keep terms that appear in at most 90% of documents
dim(f_dtm)

## Weights: binary?
f_dtm_bin <- dfm_weight(f_dtm, "boolean")
# View(as.matrix(f_dtm_bin[, order(colSums(f_dtm_bin), decreasing = T)][1:60, 1:200]))

## Weights: TF-IDF
f_tfidf <- dfm_tfidf(f_dtm, "logcount", "inverse")
# View(as.matrix(f_tfidf[, order(colSums(f_tfidf), decreasing = T)][1:60, 1:200]))


################################################################################
## (Option 3) Short pipeline with tidytext
################################################################################

library(dplyr)
library(stringr)
library(SnowballC)
library(tidytext)

## First put the texts in a data.frame (or tibble)
sotu_df <- data.frame(content = sotu_text, doc = names(sotu_text), sotu_meta) 

t_toks <- sotu_df %>% 
  filter(between(year, 1900, 2000)) %>%                      ## Filter on year
  unnest_tokens(output = token, input = content) %>%         ## Tokenize
  anti_join(get_stopwords(), by = c("token" = "word")) %>%   ## Remove stopwords
  filter(!str_detect(token, "[:digit:]")) %>%                ## Remove numbers
  mutate(token = wordStem(token, language = "en")) %>%       ## Stemming
  group_by(token) %>% filter(n() > 3)                        ## Filter on counts

t_dtm <- t_toks %>% 
  count(doc, token) %>% cast_dfm(doc, token, n)              ## Compute DTM

t_tfidf <- t_toks %>% 
  count(doc, token) %>% bind_tf_idf(token, doc, n) %>%       ## Compute tf-idf
  cast_dfm(doc, token, tf_idf)                               ## Format as DTM



################################################################################
## (Option 4) Short powerful pipeline with spacyr and quanteda
################################################################################

library(spacyr)

## One-time installation of spacy python backend and spacy language model
# spacy_install(lang_models = "en_core_web_trf")

# ## Initialize spacy model, run parsing and shut down spacy backend
# # spacy_initialize(model = "en_core_web_trf") ## Takes several hours without GPU!
# spacy_initialize(model = "en_core_web_sm") ## Takes 5min on fast CPU
# spa_parse <- spacy_parse(sotu_text) 
# spacy_finalize()
# gc()

## Alt: Import pre-computed spacy parsing (from largest trf model)
spa_parse <- read.csv("sotu-spacy-trf.csv") ## Correct file path here!
class(spa_parse) <- c("spacyr_parsed", "data.frame") # trick to make it usable

## Consolidate named entities
spa_cons <- entity_consolidate(spa_parse)

## Filter on POS
spa_filter <- spa_cons[
  spa_cons$pos %in% c("ADJ", "ADV", "ENTITY", "NOUN", "PROPN", "VERB"), ]
spa_filter <- spa_filter[
  ! spa_filter$entity_type %in% c("CARDINAL", "DATE", "MONEY", "ORDINAL", 
                                  "PERCENT", "QUANTITY", "TIME"), ]

## Convert filtered lemmas to quanteda-friendly tokens list
spa_toks <- tapply(spa_filter$lemma, spa_filter$doc_id, identity)
spa_toks <- spa_toks[names(sotu_text)] # Important (not here but in general) to keep good order

## Compute DTM
spa_dtm <- dfm(as.tokens(spa_toks))

## Filter on counts
spa_dtm <- dfm_trim(spa_dtm, min_docfreq = 5)

## TF-IDF
spa_tfidf <- dfm_tfidf(spa_dtm, "logcount", "inverse")


################################################################################
## Unsupervised visualization: UMAP on tf_idf
################################################################################

library(uwot)

## Choose DTM to reduce
# the_dtm <- q_tfidf
the_dtm <- f_tfidf
# the_dtm <- spa_tfidf

## Compute UMAP
dtm_umap <- umap(as.matrix(the_dtm), metric = "cosine", min_dist = .1)

## Plot
ggplot(data.frame(name = names(sotu_text), dtm_umap, sotu_meta), 
       aes(X1, X2, label = name, color = party)) + 
  geom_text_repel(size = 2, max.overlaps = 30) + 
  geom_path(aes(X1, X2), inherit.aes = F) +
  theme_bw() + xlab(NULL) + ylab(NULL)


################################################################################
## Unsupervised visualization: CA on tf_idf, by president
################################################################################

##############
## Prepare data for CA
##############

## Choose DTM to reduce
# the_dtm <- q_dtm
the_dtm <- f_dtm
# the_dtm <- spa_dtm

## Compress the DTM: sum by president
the_dtm <- dfm_group(the_dtm, sotu_meta$president)

## Compute tf-idf (each president is a document)
the_dtm <- dfm_tfidf(the_dtm, "logcount", "inverse")


##############
## V1: CA with FactoMineR (slow, not sparse, but interpretable)
##############

library(FactoMineR)
library(explor)

## Compute CA (non-sparse)
dtm_ca <- CA(as.matrix(the_dtm))

# explor(dtm_ca) ## Interactive graphs

## Simple plot
plot(dtm_ca, invisible = "col")

## Advanced plot: plot rows and high-contributing words (in first two dims)
ca_row <- data.frame(dtm_ca$row$coord, name = rownames(dtm_ca$row$coord))
ca_col <- data.frame(dtm_ca$col$coord, name = rownames(dtm_ca$col$coord), 
                     contrib = dtm_ca$col$contrib)

min_contrib <- .01
bool_contrib <- ca_col$contrib.Dim.1 >= min_contrib | 
  ca_col$contrib.Dim.2 >= min_contrib
table(bool_contrib)

ggplot(ca_row, aes(Dim.1, Dim.2, label = name)) + 
  geom_text(data= ca_col[bool_contrib, ], color = "red", alpha = .5, size = 3) +
  geom_point() + geom_label() + 
  theme_bw()


##############
## V2: CA with quanteda.textmodels (sparse, no inbuilt contribution stats)
##############

library(quanteda.textmodels)

## Compute fast CA
dtm_ca2 <- textmodel_ca(the_dtm, nd = 50, smooth = .01)

## Apply same weighting as FactoMineR (otherwise result is essentially ~ 1D)
dtm_ca2_row <- (dtm_ca2$rowcoord %*% diag(dtm_ca2$sv))[, !is.na(dtm_ca2$sv)]
dtm_ca2_col <- (dtm_ca2$colcoord %*% diag(dtm_ca2$sv))[, !is.na(dtm_ca2$sv)]

## Plot
ggplot(data.frame(dtm_ca2_row, name = rownames(dtm_ca2_row)), 
       aes(X1, X2, label = name)) + 
  geom_text(data = data.frame(dtm_ca2_col, name = rownames(dtm_ca2_col)), 
            color = 2, size = 2, alpha = .3) +
  geom_point() + geom_text() + 
  theme_bw()


## Plot: zoom in
ggplot(data.frame(dtm_ca2_row, name = rownames(dtm_ca2_row)), 
       aes(X1, X2, label = name)) + 
  geom_text(data = data.frame(dtm_ca2_col, name = rownames(dtm_ca2_col)), 
            color = 2, size = 3, alpha = .6) +
  geom_point() + geom_text() + 
  theme_bw() + coord_cartesian(xlim = c(1, 2), ylim = c(-1.5, -0.5))



################################################################################
## Supervised (linear/svm): predict party from text
################################################################################

library(forcats)
library(quanteda.textmodels)
library(Metrics)

## Recode party to Dem, Rep, Other
sotu_party <- fct_recode(
  sotu_meta$party, 
  Other = "Democratic-Republican", 
  Other = "Federalist", 
  Other = "Nonpartisan", 
  Other = "Whig", 
  Dem = "Democratic", Rep = "Republican")

## Prepare predictors and DV

# the_dtm <- q_tfidf
the_dtm <- f_tfidf
# the_dtm <- spa_tfidf

the_dv <- sotu_party

## Split training and testing samples
set.seed(4321)
trainsamp <- sample(length(the_dv), round(.8 * length(the_dv)))
testsamp <- (1:length(the_dv))[-trainsamp]

## Estimate prediction model
lin_model <- textmodel_svm(the_dtm[trainsamp, ], the_dv[trainsamp], 
                           type = 1, cost = 128)

## Predictions on full dataset
lin_pred <- predict(lin_model, the_dtm)

## Estimate prediction quality on holdout test sample
table(the_dv[testsamp], lin_pred[testsamp])
mean(the_dv[testsamp] == lin_pred[testsamp])

lin_metrics <- sapply(levels(the_dv), function(x) {
  truth <- the_dv[testsamp] == x
  pred <- lin_pred[testsamp] == x
  data.frame(acc = accuracy(truth, pred), 
             f1 = fbeta_score(truth, pred))
})


## Inspect model weights for interpretation
lin_model$weights[, order(lin_model$weights[1, ], decreasing = T)[1:10]]
lin_model$weights[, order(lin_model$weights[1, ], decreasing = F)[1:10]]
lin_model$weights[, order(abs(lin_model$weights[1, ]), decreasing = T)[1:10]]

lin_model$weights[, order(lin_model$weights[2, ], decreasing = T)[1:10]]
lin_model$weights[, order(abs(lin_model$weights[2, ]), decreasing = T)[1:10]]



