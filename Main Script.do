cd "D:/Kerjaan/Research Consultant/Project CFA and Ordinal Logistic Regression in STATA"

clear all
set more off

import excel "Dataset.xlsx", sheet("Sheet1") firstrow

drop in 417/l

* Encoding Variabel Kategorik
encode Jeniskelamin, gen(gender)
encode ProgramStudi, gen(prodi)
rename Angkatantahunpendidikan angkatan
rename UangsakuperbulanMIN uang_saku


* UNIVARIAT - Frekuensi & Persentase
* Data ordinal (BDI1-BDI21, OSSS1-3) dan nominal (jika ada)
foreach var of varlist BDI1-BDI21 OSSS1-OSSS3 {
    tab `var', missing
}

* Data rasio (PAS1-PAS18, PASA1-PASA16, GSE1-GSE3, EES1-EES24)
foreach var of varlist PAS1-PAS18 PASA1-PASA16 GSE1-GSE3 EES1-EES24 {
    summarize `var', detail
}

* BIVARIAT
* Hitung skor total BDI (variabel ordinal sebagai variabel dependen)
gen total_BDI = BDI1 + BDI2 + BDI3 + BDI4 + BDI5 + BDI6 + BDI7 + BDI8 + BDI9 + BDI10 + BDI11 + BDI12 + BDI13 + BDI14 + BDI15 + BDI16 + BDI17 + BDI18 + BDI19 + BDI20 + BDI21

* Kategorikan skor BDI (Contoh: 0–13 = ringan, 14–19 = sedang, dst)
gen kategori_BDI = .
replace kategori_BDI = 0 if total_BDI <= 13
replace kategori_BDI = 1 if total_BDI > 13 & total_BDI <= 19
replace kategori_BDI = 2 if total_BDI > 19 & total_BDI <= 28
replace kategori_BDI = 3 if total_BDI > 28

label define bdi 0 "Minimal" 1 "Ringan" 2 "Sedang" 3 "Berat"
label values kategori_BDI bdi

* Hitung total PAS
egen total_PAS = rowmean(PAS1-PAS18)

* Uji bivariat ordinal logistic regression
ologit kategori_BDI total_PAS

egen total_PAS = rowmean(PAS1-PAS18)
gen PAS = round(total_PAS)
tabulate PAS gender, chi2 row col

tabulate kategori_BDI prodi, chi2 row col
tabulate kategori_BDI angkatan, chi2 row col


* MULTIVARIAT
* Pastikan kamu menggunakan STATA versi 15 atau lebih tinggi dengan modul SEM
sem (anger -> EES1 EES2 EES5 EES7 EES12 EES13 EES15 EES17 EES21 EES22 EES24) (anxiety -> EES3 EES6 EES9 EES11 EES14 EES18 EES19 EES20) (depression -> EES4 EES8 EES10 EES16 EES23), method(mlmv) latent(anger anxiety depression)

* Tampilkan hasil CFA
estat gof, stats(all)

predict skor_EES_anger skor_EES_anxiety skor_EES_depression, latent
gen skor_EES_total = (skor_EES_anger + skor_EES_anxiety + skor_EES_depression)/3

egen total_PASA = rowmean(PASA1-PASA16)
egen total_GSE = rowmean(GSE1-GSE3)
egen total_OSSS = rowmean(OSSS1-OSSS3)

* Variabel moderator: skor_EES_total
* Interaksi: total_PAS#c.skor_EES_total
ologit kategori_BDI c.total_PAS##c.skor_EES_total
ologit kategori_BDI c.total_PAS##c.skor_EES_total c.total_PASA c.total_GSE c.total_OSSS c.gender c.prodi c.angkatan c.uang_saku
