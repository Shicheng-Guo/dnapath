entrez_to_description <- function(df, species,
                                  dir_annotation = "data/annotations/") {
  if(!any(names(df) %in% c("entrezgene")))
    stop("df must contain a column nammed 'entrezgene'.")
  species <- pmatch(tolower(species), c("human", "mouse"))
  if(is.na(species))
    stop("species must be either 'human' or 'mouse'.")
  
  if(species == 1) {
    # ! TODO: use instead -> as.list(org.Hs.egSYMBOL)
    # Human
    load_file <- paste0(dir_annotation, "entrez_to_description_hgnc.rds")
    if(file.exists(load_file)) {
      cat("\t- loading gene info from", load_file, "\n")
      gene_info <- readRDS(load_file)
    } else {
      if(!("mart_human" %in% ls())) init_mart_human()
      gene_info <- getBM(attributes = c("entrezgene", "description"), 
                         mart = mart_human)
      gene_info %>%
        filter(!is.na(entrezgene)) %>%
        group_by(entrezgene) %>%
        summarise(description = description[1]) %>%
        mutate(description = gsub("( .Source.*)", "", description)) %>%
        ungroup() ->
        gene_info 
      
      save_file <- load_file
      cat("\t- saving gene info to", save_file, "\n")
      if(!dir.exists(dir_annotation)) dir.create(dir_annotation, recursive = TRUE)
      saveRDS(gene_info, save_file)
    }
    
  } else {
    # Mouse
    load_file <- paste0(dir_annotation, "entrez_to_description_mgi.rds")
    if(file.exists(load_file)) {
      cat("\t- loading gene info from", load_file, "\n")
      gene_info <- readRDS(load_file)
    } else {
      cat("Obtaining gene info from biomart.\n")
      
      if(!("mart_mouse" %in% ls())) init_mart_mouse()
      gene_info <- getBM(attributes = c("entrezgene", "description"), 
                         mart = mart_mouse)
      gene_info %>%
        filter(!is.na(entrezgene)) %>%
        group_by(entrezgene) %>%
        summarise(description = description[1]) %>%
        mutate(description = gsub("( .Source.*)", "", description)) %>%
        ungroup() ->
        gene_info 
      
      save_file <- load_file
      cat("\t- saving gene info to", save_file, "\n")
      if(!dir.exists(dir_annotation)) dir.create(dir_annotation, recursive = TRUE)
      saveRDS(gene_info, save_file)
    }
  }
  
  if(!is.numeric(df$entrezgene)) df$entrezgene <- as.numeric(df$entrezgene)
  
  return(left_join(df, gene_info, by = "entrezgene"))
}