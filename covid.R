
library(tidyverse)

# Get the latest VA file
va <- read_csv("https://data.virginia.gov/api/views/28k2-x2rj/rows.csv?accessType=DOWNLOAD")
head(va)
colnames(va)

# Get the total doses by county
va_totals <- 
  va %>% group_by(FIPS, Locality, `Dose Number`) %>%  
      summarise(total = sum(`Vaccine Doses Administered Count`))
va_totals <- va_totals %>% 
  pivot_wider(id_cols = c(FIPS, Locality), values_from = total, names_from = `Dose Number`, 
              names_prefix = 'Dose_')

# Get 2019 ACS 5-year population by age
# https://data.census.gov/cedsci/table?q=population&g=0100000US.050000&tid=ACSDP5Y2019.DP05&hidePreview=true
pop <- read_csv(file = "ACSDP5Y2019.DP05_data_with_overlays_2021-03-04T082446.csv")
pop2 <- pop %>% 
        mutate(FIPS = substr(GEO_ID,10,14), DP05_0021E = as.numeric(DP05_0021E), DP05_0024E =
                 as.numeric(DP05_0024E)) %>% 
        select(FIPS,DP05_0021E,DP05_0024E)
# Drop the secondary column names
pop2 <- pop2[-1,]

# Add the pop to vaccines
va_with_pop <- inner_join(va_totals, pop2, by = "FIPS")

# Calculate vaccines as share of pop
va_with_pop2 <- mutate(va_with_pop, 
                       Dose_1_share = Dose_1 / DP05_0021E, 
                       Dose_2_share = Dose_2 / DP05_0021E,
                       Dose_1_share_eld = Dose_1 / DP05_0024E, 
                       Dose_2_share_eld = Dose_2 / DP05_0024E,
                       Dose_1_share = scales::percent(Dose_1_share, accuracy = 0.01),
                       Dose_2_share = scales::percent(Dose_2_share, accuracy = 0.01),
                       Dose_1_share_eld = scales::percent(Dose_1_share_eld, accuracy = 0.01),
                       Dose_2_share_eld = scales::percent(Dose_2_share_eld, accuracy = 0.01))
                       

# List of NOVA counties per wikipedia
nova <- c("51510","51013","51043","51047","51059","51061","51069","51107",
          "51113","51153","51157","51177","51179","51187","51600","51610",
          "51630","51683","51685","51840")

nova_vaccines <- va_with_pop2 %>% 
  filter(FIPS %in% nova)

nova_total <- nova_vaccines %>% 
  ungroup() %>% 
  summarise(Total_Dose_1 = sum(Dose_1), Total_Dose_2 = sum(Dose_2), pop = sum(DP05_0021E),
            eld_pop = sum(DP05_0024E)) %>% 
  mutate(Dose_1_share = Total_Dose_1 / pop, 
         Dose_2_share = Total_Dose_2 / pop,
         Dose_1_share_eld = Total_Dose_1 / eld_pop, 
         Dose_2_share_eld = Total_Dose_2 / eld_pop,
         Dose_1_share = scales::percent(Dose_1_share, accuracy = 0.01),
         Dose_2_share = scales::percent(Dose_2_share, accuracy = 0.01),
         Dose_1_share_eld = scales::percent(Dose_1_share_eld, accuracy = 0.01),
         Dose_2_share_eld = scales::percent(Dose_2_share_eld, accuracy = 0.01))

va_total <- va_with_pop2 %>% 
  ungroup() %>% 
  summarise(Total_Dose_1 = sum(Dose_1), Total_Dose_2 = sum(Dose_2), pop = sum(DP05_0021E),
            eld_pop = sum(DP05_0024E)) %>% 
  mutate(Dose_1_share = Total_Dose_1 / pop, 
         Dose_2_share = Total_Dose_2 / pop,
         Dose_1_share_eld = Total_Dose_1 / eld_pop, 
         Dose_2_share_eld = Total_Dose_2 / eld_pop,
         Dose_1_share = scales::percent(Dose_1_share, accuracy = 0.01),
         Dose_2_share = scales::percent(Dose_2_share, accuracy = 0.01),
         Dose_1_share_eld = scales::percent(Dose_1_share_eld, accuracy = 0.01),
         Dose_2_share_eld = scales::percent(Dose_2_share_eld, accuracy = 0.01)
         )

# Get US Vaccine totals
us_total <- read_csv("https://raw.githubusercontent.com/youyanggu/covid19-cdc-vaccination-data/main/cdc_vaccination_trends_data.csv")
us_total  

us_raw <- jsonlite::fromJSON("https://covid.cdc.gov/covid-data-tracker/COVIDData/getAjaxData?id=vaccination_trends_data")
us_total <- as_tibble(us_raw[["vaccination_trends_data"]])
current_total <- us_total[1,]
current_total
current_total <- select(current_total, Date, Administered_Cumulative, Admin_Dose_1_Cumulative,
                        Admin_Dose_2_Cumulative)
total_pop <- pop2 %>% 
  summarise(total_adult = sum(DP05_0021E), total_eld = sum(DP05_0024E))

current_total <- cbind(current_total,total_pop)
current_total2 <- current_total %>% 
  transmute(Dose_1 = Admin_Dose_1_Cumulative,
         Dose_2 = Admin_Dose_2_Cumulative,
         Dose_1_share = Admin_Dose_1_Cumulative/total_adult, 
         Dose_1_share = scales::percent(Dose_1_share, accuracy = 0.01),
         Dose_1_share_eld = Admin_Dose_1_Cumulative/total_eld, 
         Dose_1_share_eld = scales::percent(Dose_1_share_eld, accuracy = 0.01),
         Dose_2_share = Admin_Dose_2_Cumulative/total_adult, 
         Dose_2_share = scales::percent(Dose_2_share, accuracy = 0.01),
         Dose_2_share_eld = Admin_Dose_2_Cumulative/total_eld, 
         Dose_2_share_eld = scales::percent(Dose_2_share_eld, accuracy = 0.01),
         Locality = "US"
         )
current_total2
nova_vaccines2 <- nova_vaccines %>% 
  ungroup() %>% 
  select(Locality, Dose_1, Dose_2, Dose_1_share, Dose_2_share, Dose_1_share_eld, Dose_2_share_eld)

nova_total2 <- nova_total %>% 
  ungroup() %>% 
  mutate(Locality = "NoVA Total", Dose_1 = Total_Dose_1, Dose_2 = Total_Dose_2) %>% 
  select(Locality, Dose_1, Dose_2, Dose_1_share, Dose_2_share, Dose_1_share_eld, Dose_2_share_eld) 
  
out1 <- rbind(current_total2, nova_total2, nova_vaccines2)
