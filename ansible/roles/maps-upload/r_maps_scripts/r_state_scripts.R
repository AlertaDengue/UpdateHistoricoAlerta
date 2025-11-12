##Definir diretório UF e semana do mapa 

dir= "~/infodengue/"
semana = "202544"

#####################################################################
# ---- pacotes ----
pkgs <- c("tidyverse","ggplot2","sf","purrr")

lapply(pkgs, library, character.only = TRUE ,quietly = T)

##########################################################################
##########################################################################
sig <- c("SC","CE","PR")
sig <- c("AC","AM","AP","PA","RO","RR","TO",
         "AL","BA","CE","MA","PI","PE","PB","RN","SE",
         "GO","MT","MS","DF",
         "ES","MG","RJ","SP",
         "PR","RS","SC")
for (i in sig){
  eval(parse(text=paste0("load('",dir,"AlertaDengueAnalise/main/alertas/",semana,"/ale-",i,"-",semana,".RData')")))
  uf <- i  
  ## Carregando os objetos  gerados pelo alerta infodengue ----
  
  
  ###########################################################################
  ## Parâmetros
  
  
load(paste0(dir,"maps_uploader/r_maps_scripts/dados/cidades_infodengue.RData")) 
cidregionais <- cidregionais %>%
    rename(cidade=municipio_geocodigo)
  
  
shapefile <- read_sf(paste0(dir,"maps_uploader/r_maps_scripts/dados/shape/muni_br.gpkg"))
  ################################################################################
  ################################################################################
  
  ###Dengue
  
  if("ale.den" %in% names(res)) {data <- transpose(res[['ale.den']])[[1]] %>% bind_rows()    # unlist data
  indices <- transpose(res[['ale.den']])[[2]] %>% bind_rows() 
  
  
  ale_den <- cbind(data,indices)
  
  d <- ale_den
  }
  
  ###Chikungunya
  if("ale.chik" %in% names(res)) {
    data <- transpose(res[['ale.chik']])[[1]] %>% bind_rows()    # unlist data
    indices <- transpose(res[['ale.chik']])[[2]] %>% bind_rows() 
    
    
    ale_chik <- cbind(data,indices)
    
    d <- rbind(ale_chik, ale_den)  
  }
  
  ###Zika
  if("ale.zika" %in% names(res)) {
    data <- transpose(res[['ale.zika']])[[1]] %>% bind_rows()    # unlist data
    indices <- transpose(res[['ale.zika']])[[2]] %>% bind_rows() 
    
    ale_zika <- cbind(data,indices) 
    
    d <- rbind(ale_chik, ale_den, ale_zika)  
     #d <- ale_zika
  }
  
  
  
  d <- d %>% 
    left_join(cidregionais) 
  
  
  d <- d %>%
    mutate(
      ano= floor(SE/100),
      sem = SE - ano*100) 
  
  N <- nrow(d)
  
  lastSE <- d$SE[N]
  esse_ano <- d$ano[N]
  essa_se <- d$sem[N]
  iniSE <- (esse_ano-1)*100+1 
  
  
  inc_acum <- d %>%
    filter(SE >= unique(SE)[length(unique(SE))-3]) %>%
    group_by(cidade,CID10) %>%
    summarise(inc=sum(inc),nome= unique(nome),pop=unique(pop)) 
  
  
  
  # --------------------
  # MAPA receptividade  
  # --------------------
  
  malha <- shapefile
  
  
  malha <- malha %>%
    rename(CD_GEOCMU=code_muni) %>%
    filter(abbrev_state == uf)
  
  
  malha <- malha %>%
    left_join(cidregionais, by = c("CD_GEOCMU" = "cidade"))
  
  malha_inc <- malha %>%
    left_join(inc_acum, by = c("CD_GEOCMU" = "cidade")) 
  
  
  
  breaks <- c(0,10,50,100,200,300,Inf)
  malha_inc <- malha_inc %>%
    mutate(inc_interval = cut(inc, breaks,
                              labels=c("0-10","10-50","50-100","100-200","200-300","300 ou mais"), include.lowest = T))
  
  paleta <- c("#FFF7EC","#FDD49E","#FC8D59","#EF6548","#B30000","#7F0000")
  
  
  if("ale.den" %in% names(res)) {
    plot_den_inc <- ggplot() + 
      geom_sf(data = malha_inc %>% filter(CID10 == "A90"), 
              aes(fill = inc_interval), linewidth =0.02, alpha=1, color= "black") +
      scale_fill_manual(values  = paleta, 
                        name= "Incidência por 100 mil habitantes") +
      ggtitle("Dengue" ,
              subtitle = paste0("SE ",essa_se-3,"-",essa_se,"/",esse_ano)) + 
      coord_sf() +
      theme(plot.title = element_text(family="Helvetica Neue",vjust = 1.5,hjust = 0.5,size = 14),
            plot.subtitle = element_text(family="Helvetica Neue",vjust = 2,hjust = 0.5,size = 10),
            legend.direction = "horizontal",
            legend.position ="bottom",
            legend.title =element_text(family="Helvetica Neue", size = 10),
            legend.key.size  = unit(0.4, "cm"),
            legend.text = element_text(family="Helvetica Neue", size = 8),
            axis.text = element_blank(), 
            axis.ticks =element_blank(),
            axis.title = element_blank(),
            panel.background = element_rect(fill = "transparent"), # bg of the panel
            plot.background = element_rect(fill = "transparent", color = NA), # bg of the plot
            panel.grid.major = element_blank(), # get rid of major grid
            panel.grid.minor = element_blank(), # get rid of minor grid
            legend.background = element_blank(), # get rid of legend bg
            legend.box.background = element_blank()) +
      guides(fill = guide_legend(title.position="top", title.hjust = 0.5, nrow = 1,
                                 label.position ="bottom" ))
    
    
    png(paste0(dir,"maps_uploader/sync_maps/incidence_maps/state/incidence_",uf,"_dengue.png"), width = 390, height = 404,
        bg = "transparent", units = "px", res=85)
    print(plot_den_inc)
    dev.off()
    
  }
  
  if("ale.chik" %in% names(res)) {
    
    plot_chik_inc <- ggplot() + 
      geom_sf(data = malha_inc %>% filter(CID10 == "A92.0"), 
              aes(fill = inc_interval), linewidth=0.02, alpha=1, color= "black") +
      scale_fill_manual(values  = paleta, 
                        name= "Incidência por 100 mil habitantes") +
      ggtitle("Chikungunya",
              subtitle = paste0("SE ",essa_se-3,"-",essa_se,"/",esse_ano)) + 
      coord_sf() +
      theme(plot.title = element_text(family="Helvetica Neue",vjust = 1.5,hjust = 0.5,size = 14),
            plot.subtitle = element_text(family="Helvetica Neue",vjust = 2,hjust = 0.5,size = 10),
            legend.direction = "horizontal",
            legend.position ="bottom",
            legend.title =element_text(family="Helvetica Neue", size = 10),
            legend.key.size  = unit(0.4, "cm"),
            legend.text = element_text(family="Helvetica Neue", size = 8),
            axis.text = element_blank(), 
            axis.ticks =element_blank(),
            panel.background = element_rect(fill = "transparent"), # bg of the panel
            plot.background = element_rect(fill = "transparent", color = NA), # bg of the plot
            panel.grid.major = element_blank(), # get rid of major grid
            panel.grid.minor = element_blank(), # get rid of minor grid
            legend.background = element_blank(), # get rid of legend bg
            legend.box.background = element_blank()) +
      guides(fill = guide_legend(title.position="top", title.hjust = 0.5, nrow = 1,
                                 label.position ="bottom" ))
    
    
    
    
    png(paste0(dir,"maps_uploader/sync_maps/incidence_maps/state/incidence_",uf,"_chikungunya.png"), width = 390, height = 404,
        bg = "transparent", units = "px", res=85)
    print(plot_chik_inc)
    dev.off()
  }
  
  if("ale.zika" %in% names(res)) {  
    plot_zika_inc <- ggplot() + 
      geom_sf(data = malha_inc %>% filter(CID10 == "A92.8"),
              aes(fill = inc_interval), linewidth=0.02, alpha=1, color= "black") +
      scale_fill_manual(values  = paleta, 
                        name= "Incidência por 100 mil habitantes") +
      ggtitle("Zika",
              subtitle = paste0("SE ",essa_se-3,"-",essa_se,"/",esse_ano)) + 
      coord_sf() +
      theme(plot.title = element_text(family="Helvetica Neue",vjust = 1.5,hjust = 0.5,size = 14),
            plot.subtitle = element_text(family="Helvetica Neue",vjust = 2,hjust = 0.5,size = 10),
            legend.direction = "horizontal",
            legend.position ="bottom",
            legend.title =element_text(family="Helvetica Neue", size = 10),
            legend.key.size  = unit(0.4, "cm"),
            legend.text = element_text(family="Helvetica Neue", size = 8),
            axis.text = element_blank(), 
            axis.ticks =element_blank(),
            panel.background = element_rect(fill = "transparent"), # bg of the panel
            plot.background = element_rect(fill = "transparent", color = NA), # bg of the plot
            panel.grid.major = element_blank(), # get rid of major grid
            panel.grid.minor = element_blank(), # get rid of minor grid
            legend.background = element_blank(), # get rid of legend bg
            legend.box.background = element_blank()) +
      guides(fill = guide_legend(title.position="top", title.hjust = 0.5, nrow = 1,
                                 label.position ="bottom" ))
    
    
    
    png(paste0(dir,"maps_uploader/sync_maps/incidence_maps/state/incidence_",uf,"_zika.png"), width = 390, height = 404,
        bg = "transparent", units = "px", res=85)
    print(plot_zika_inc)
    dev.off()
    
  }
  
}

