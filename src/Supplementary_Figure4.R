library(here)
library(magrittr)
library(tidyverse)
source(here::here('src', 'analysis_helpers.R'))
source(here::here('src', 'Celligner_helpers'))
source(here::here('src', 'global_params.R'))


# Used to create input for Supplementary Figure 4a
calc_uncorrected_tumor_CL_distance <- function(TCGA_mat, CCLE_mat, alignment) {
  uncorrected_comb_obj <- create_Seurat_object(rbind(TCGA_mat, CCLE_mat),
                                               alignment)
  uncorrected_tumor_CL_dist <- calc_tumor_CL_dist(uncorrected_comb_obj)
  return(uncorrected_tumor_CL_dist)
}

# Supplementary Figure 4a
plot_uncorrected_CL_tumor_class <- function(uncorrected_tumor_CL_dist, alignment, filename) {
  uncorrected_cl_tumor_classes <- apply(uncorrected_tumor_CL_dist, 2, 
                                        function(x) 
                                          cell_line_tumor_class(x, uncorrected_tumor_CL_dist, alignment)) %>%
    as.character()
  names(uncorrected_cl_tumor_classes) <- colnames(uncorrected_tumor_CL_dist)

  cl_tissue_type <- dplyr::filter(alignment, type=='CL')
  cl_tissue_type[grep('rhabdomyosarcoma', cl_tissue_type$subtype),'tissue'] <- 'rhabdomyosarcoma'
  rownames(cl_tissue_type) <- cl_tissue_type$sampleID
  classification_freq <- table(uncorrected_cl_tumor_classes, cl_tissue_type[colnames(tumor_CL_dist),'tissue']) %>% as.data.frame()
  classification_freq <- reshape2::dcast(classification_freq, uncorrected_cl_tumor_classes ~ Var2, value.var = 'Freq') %>% tibble::column_to_rownames('uncorrected_cl_tumor_classes')
  
  print(setdiff(intersect(unique(dplyr::filter(alignment, type=='CL')$tissue),
                          unique(dplyr::filter(alignment, type=='tumor')$tissue)),
                rownames(classification_freq)))
  
  thyroid_tumor <- rep(0, ncol(classification_freq))
  classification_freq <- rbind(classification_freq,thyroid= thyroid_tumor) 
  eye_tumor <- rep(0, ncol(classification_freq))
  classification_freq <- rbind(classification_freq,eye= eye_tumor) 
  pancreas_tumor <- rep(0, ncol(classification_freq))
  classification_freq <- rbind(classification_freq,pancreas= pancreas_tumor) 
  
  common_types <- intersect(rownames(classification_freq), colnames(classification_freq))
  common_types_tumor <- c(common_types, 'brain', 'neuroblastoma', 'leukemia', 'lymphoma')
  common_types_CL <- c(common_types, 'central_nervous_system', 'peripheral_nervous_system', 'blood', 'lymphocyte')
  
  uncorrected_prop_agree <- sum(diag(as.matrix(classification_freq[common_types_tumor, common_types_CL])))/sum(as.matrix(classification_freq[common_types_tumor, common_types_CL]))
  
  for(i in 1:ncol(classification_freq)) {
    classification_freq[,i] <- classification_freq[,i]/sum(classification_freq[,i])
  }
  
  
  agreement <- diag(as.matrix(classification_freq[common_types_tumor, common_types_CL]))
  agreement_CL <- agreement
  names(agreement_CL) <- common_types_CL
  agreement_tumor <- agreement
  names(agreement_tumor) <- common_types_tumor
  
  agreement_CL <- base::sort(agreement_CL, decreasing=T)
  agreement_tumor <- base::sort(agreement_tumor, decreasing=T)
  
  
  CL_order <- c('soft_tissue', 'peripheral_nervous_system', 'lymphocyte', 'skin', 'kidney', 'blood', "rhabdomyosarcoma", 'breast','colorectal', 'bone', 'urinary_tract', 'prostate', 'uterus','gastric', 'lung', 'eye',   'upper_aerodigestive', 'ovary', 'liver', 'cervix', 'pancreas', 'central_nervous_system',  'esophagus', 'bile_duct',
                'thyroid')
  tumor_order <- c( 'soft_tissue','neuroblastoma', 'lymphoma', 'skin', 'kidney', 'leukemia',  "rhabdomyosarcoma", 'breast', 'colorectal', 'bone',    'urinary_tract', 'prostate','uterus', 'gastric',  'lung', 'eye', 'upper_aerodigestive', 'ovary', 'liver', 'cervix', 'pancreas',  'brain',
                    'esophagus', 'bile_duct',  'thyroid')
  
  
  classification_freq <- classification_freq[tumor_order, CL_order]
  colnames(classification_freq) <- gsub("_", " ", colnames(classification_freq))
  rownames(classification_freq) <- gsub("_", " ", rownames(classification_freq))
  
  pheatmap:::pheatmap(classification_freq, 
           border_color = heatmap_params$square_border_color,
           na_col=heatmap_params$na_color, 
           cluster_rows = F,
           cluster_cols = F,
           main="", 
           fontsize = heatmap_params$title_font_size, 
           fontsize_col = heatmap_params$column_font_size, 
           fontsize_row = heatmap_params$row_font_size, 
           width = 3.5, 
           height = 3, 
           fontface = heatmap_params$font_face, 
           angle_col=90, 
           filename = filename,
           color=heatmap_params$color_vector)
}

# Supplementary Figure 4b
plot_uncorrected_distribution_of_CL_tumor_distances <- function(uncorrected_tumor_CL_dist, alignment) {
  alignment$compare_types <- alignment$tissue
  # select types/subtypes to compare between cell lines and tumors
  alignment[which(alignment$tissue=='central_nervous_system'),'compare_types'] <- 'brain'
  alignment[which(alignment$tissue=='peripheral_nervous_system'),'compare_types'] <- 'neuroblastoma'
  alignment[which(alignment$tissue=='lymphocyte'),'compare_types'] <- 'lymphoma'
  alignment[which(alignment$subtype=='Ewing sarcoma'),'compare_types'] <- 'Ewing sarcoma'
  alignment[which(alignment$subtype=='osteosarcoma'),'compare_types'] <- 'osteosarcoma'
  alignment[which(alignment$subtype=='uveal melanoma'),'compare_types'] <- 'uveal melanoma'
  alignment[which(alignment$subtype=='acute myeloid leukemia'),'compare_types'] <- 'acute myeloid leukemia'
  alignment[grep('acute lymphoblastic leukemia', alignment$subtype),'compare_types'] <- 'acute lymphoblastic leukemia'
  alignment[dplyr::filter(alignment, tissue=='breast')$sampleID[grep('basal', dplyr::filter(alignment, tissue=='breast')$subtype)],'compare_types'] <- 'basal breast'
  alignment[dplyr::filter(alignment, tissue=='breast')$sampleID[grep('luminal', dplyr::filter(alignment, tissue=='breast')$subtype)],'compare_types'] <- 'luminal breast'
  
  
  common_cancer_types <- intersect(dplyr::filter(alignment, type=='tumor')$compare_types, dplyr::filter(alignment, type=='CL')$compare_types)
  common_cancer_types <- setdiff(common_cancer_types, c('eye', 'bone', 'breast'))
  
  tumor_names <- character()
  CL_names <- character()
  dist_list <- numeric()
  tissue_types <- character()
  for(cancer in common_cancer_types) {
    cur_tumors <- dplyr::filter(alignment, type=='tumor' & compare_types==cancer)$sampleID
    cur_CLs <- dplyr::filter(alignment, type=='CL' & compare_types==cancer)$sampleID
    cur_dist <- reshape2::melt(as.matrix(uncorrected_tumor_CL_dist[cur_tumors, cur_CLs]))
    tumor_names <- c(tumor_names, as.character(cur_dist$Var1))
    CL_names <- c(CL_names, as.character(cur_dist$Var2))
    dist_list <- c(dist_list, cur_dist$value)
    tissue_types <- c(tissue_types, rep(cancer, nrow(cur_dist)))
    
  }
  
  dist_df <- cbind.data.frame(tumor_names, CL_names, dist_list, tissue_types)
  mean_dist <- aggregate(dist_df$dist_list, list(dist_df$tissue_types), 
                         FUN = quantile, probs = 0.25) %>% dplyr::arrange(x)
  
  mean_dist$Group.1 <- rev(mean_dist$Group.1)
  dist_df$tissue_types <- gsub("_", " ", dist_df$tissue_types)
  dist_df$tissue_types <- factor(dist_df$tissue_types, levels = mean_dist$Group.1)
  
  
  uncorrect_tumor_dist_spread <- ggplot2::ggplot(dplyr::filter(dist_df, tissue_types != 'all'),
                                                 ggplot2::aes(x = dist_list, y = tissue_types, fill = tissue_types)) + 
    ggridges::geom_density_ridges(alpha=0.8) +
    ggplot2::theme_ridges() + 
    ggplot2::theme_classic() +
    ggplot2::theme(legend.position = "none",
          text=ggplot2::element_text(size=6),
          axis.text = ggplot2::element_text(size=6)) +
    ggplot2::xlab("distance between cell lines and tumors") + 
    ggplot2::ylab('tissue')
  
  return(uncorrect_tumor_dist_spread)
  
}