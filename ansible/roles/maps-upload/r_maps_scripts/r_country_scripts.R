##Definir diretório 

dir= "~/infodengue/"
semana = "202544"

#####################################################################
# ---- pacotes ----
pkgs <- c("tidyverse","ggplot2","sf","purrr","mgcv","fs","miceadds")

lapply(pkgs, library, character.only = TRUE ,quietly = T)

ano <- 2025
SEfim <- 23




shapefile <- read_sf(paste0(dir,"maps_uploader/r_maps_scripts/dados/shape/rs_450_RepCor1.shp"))
shape_br <- read_sf(paste0(dir,"maps_uploader/r_maps_scripts/dados/shape/UFEBRASIL.shp"))



load(paste0(dir,"maps_uploader/r_maps_scripts/dados/cidades_infodengue.RData")) 

cidregionais <- cidregionais %>%
  rename(cidade=municipio_geocodigo)


#Diretório definido para os alertas estaduais
file_paths <- fs::dir_ls(paste0(dir,"AlertaDengueAnalise/main/alertas/",semana,"/"))
file_paths


#Load alertas
j <- 1
for (i in seq_along(file_paths)){
  load.Rdata(file_paths[i], "res")
  assign(paste0("res", j),res)
  j = j+1
  load(file_paths[i])
}
rm(res) 

#Unindo dataframe
ale_den<-list()

for (i in seq_along(file_paths)){
  data <- eval(parse(text=paste0("transpose(res",i,"[['ale.den']])[[1]] %>% bind_rows()")))# unlist data
  indices <- eval(parse(text=paste0("transpose(res",i,"[['ale.den']])[[2]] %>% bind_rows()")))
  ale_den[[i]] <-cbind(data,indices)
}

ale_den <- eval(parse(text =paste0("rbind(",paste0("ale_den[[",seq_along(file_paths),"]]", collapse = ","),")")))

ale_chik<-list()

for (i in seq_along(file_paths)){
  data <- eval(parse(text=paste0("transpose(res",i,"[['ale.chik']])[[1]] %>% bind_rows()")))# unlist data
  indices <- eval(parse(text=paste0("transpose(res",i,"[['ale.chik']])[[2]] %>% bind_rows()")))
  ale_chik[[i]] <-cbind(data,indices)
}

ale_chik <- eval(parse(text =paste0("rbind(",paste0("ale_chik[[",seq_along(file_paths),"]]", collapse = ","),")")))


d <- rbind.data.frame(ale_den,ale_chik)

d <- d %>% 
  left_join(cidregionais) 


d <- d %>%
  mutate(
    #data = SE2date(SE)$ini,   # demorado, nao faz sentido ficar calculando tudo de novo
    ano= floor(SE/100),
    sem = SE - ano*100) 



d_inc <- d %>%
  filter(SE >= unique(SE)[length(unique(SE))-3]) %>%
  group_by(regional_codigo,CID10) %>%
  summarise(tcasesmed=sum(tcasesmed), pop= sum(pop)/4)

d_inc <- d_inc %>%
  mutate(inc=tcasesmed/pop*100000)





# juntando os dados
shape <- shapefile %>%
  mutate(primary.id = as.numeric(`primary id`)) %>%
  left_join(d_inc, by = c("primary.id" = "regional_codigo"))




breaks <- c(0,10,50,100,200,300,Inf)
shape_den <- shape %>%
  filter(CID10=="A90") %>%
  mutate(inc_interval_den = cut(inc, breaks,
                                labels=c("0-10","10-50","50-100","100-200","200-300","300 ou mais"), include.lowest = T))




shape_chik <- shape %>%
  filter(CID10=="A92.0") %>%
  mutate(inc_interval_chik = cut(inc, breaks,
                                 labels=c("0-10","10-50","50-100","100-200","200-300","300 ou mais"), include.lowest = T))


paleta <- c("#FFF7EC","#FDD49E","#FC8D59","#EF6548","#B30000","#7F0000")

mapa_dengue <- ggplot() + 
  #geom_sf(data = teste4, size=0.5, color = "black") +
  #geom_sf_text(data=teste3,aes(label = name),size=2, colour = "black",fontface="bold", family="Helvetica Neue" ) +
  #geom_sf_text(data=shape,aes(label = text_map),size=2.5, colour = "black") +
  geom_sf(data = shape_den, aes(fill = inc_interval_den), linewidth=0.02, alpha = 1) +
  scale_fill_manual(values  = paleta, 
                    name= "Incidência por \n100 mil habitantes") +
  ggtitle("Dengue ", 
          subtitle =paste0("SE ",str_sub(unique(d$SE)[length(unique(d$SE))-3], start  = -2L),"-",SEfim,"/",ano)) + 
  geom_sf(data =shape_br, linewidth=0.08, fill="transparent") +
  coord_sf() +
  theme(plot.title = element_text(family="Helvetica Neue",vjust = 1.5,hjust = 0.5,size = 14),
        plot.subtitle = element_text(family="Helvetica Neue",vjust = 2,hjust = 0.5,size = 12),
        legend.position =c(0.16,0.20),
        plot.margin = unit(c(0.5,-0.5,-0.5,-0.5), "cm"),
        plot.background = element_rect(fill = "transparent", color = NA), # bg of the plot
        legend.box.background = element_rect(fill = "transparent", color = NA),
        panel.background =element_rect(fill = "transparent", color = NA),
        panel.grid.major = element_blank(), # get rid of major grid
        panel.grid.minor = element_blank(), # get rid of minor grid
        legend.title =element_text(family="Helvetica Neue", size = 10,hjust = 0.5),
        legend.background =  element_rect(fill = "transparent", color = NA),
        legend.key.size  = unit(0.4, "cm"),
        legend.text = element_text(family="Helvetica Neue", size = 8),
        axis.text = element_blank(), 
        axis.ticks =element_blank(),axis.title = element_blank())


png(paste0(dir,"maps_uploader/sync_maps/incidence_maps/country/incidence_Nacional_dengue.png"), width = 390, height = 404,
    bg = "transparent", units = "px", res=85)
print(mapa_dengue)
dev.off()




mapa_chik <- ggplot() + 
  #geom_sf(data = teste4, size=0.5, color = "black") +
  #geom_sf_text(data=teste4,aes(label = name),size=2, colour = "black") +
  #geom_sf_text(data=shape,aes(label = text_map),size=2.5, colour = "black") +
  geom_sf(data = shape_chik, aes(fill = inc_interval_chik), linewidth=0.02, alpha = 1) +
  scale_fill_manual(values  = paleta, 
                    name= "Incidência por \n100 mil habitantes") +
  ggtitle("Chikungunya ", 
          subtitle =paste0("SE ",str_sub(unique(d$SE)[length(unique(d$SE))-3], start  = -2L),"-",SEfim,"/",ano)) + 
  geom_sf(data =shape_br, linewidth=0.08, fill="transparent") +
  coord_sf() +
  theme(plot.title = element_text(family="Helvetica Neue",vjust = 1.5,hjust = 0.5,size = 14),
        plot.subtitle = element_text(family="Helvetica Neue",vjust = 2,hjust = 0.5,size = 12),
        legend.position =c(0.16,0.20),
        plot.margin = unit(c(0.5,-0.5,-0.5,-0.5), "cm"),
        plot.background = element_rect(fill = "transparent", color = NA), # bg of the plot
        legend.box.background = element_rect(fill = "transparent", color = NA),
        panel.background =element_rect(fill = "transparent", color = NA),
        panel.grid.major = element_blank(), # get rid of major grid
        panel.grid.minor = element_blank(), # get rid of minor grid
        legend.title =element_text(family="Helvetica Neue", size = 10, hjust = 0.5),
        legend.background =  element_rect(fill = "transparent", color = NA),
        legend.key.size  = unit(0.4, "cm"),
        legend.text = element_text(family="Helvetica Neue", size = 8),
        axis.text = element_blank(), 
        axis.ticks =element_blank(),axis.title = element_blank())


png(paste0(dir,"maps_uploader/sync_maps/incidence_maps/country/incidence_Nacional_chikungunya.png"), width = 390, height = 404,
    bg = "transparent", units = "px", res=85)
print(mapa_chik)
dev.off()

