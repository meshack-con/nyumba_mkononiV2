# Ripoti za PDF - Muonekano Mpya (Kama Picha Uliyonipa)

Nimeandika upya jinsi ripoti ZOTE za PDF zinavyochorwa (`app/reports/
pdf_reports.py`) ili zifuate muundo uliokubaliwa:

- **Banner ya kijani** juu yenye kichwa cheupe cha ripoti, na mstari
  mfupi + duara ndogo chini yake.
- **"Meta bar"** - "Imetengenezwa: tarehe/saa" (na baadhi ya ripoti
  zina taarifa za ziada, mfano "Wenye Akaunti / Wasio na Akaunti").
- Kila sehemu ya ripoti sasa ni **"kadi"** yenye mstari wa kijani
  upande wa kushoto, icon ya duara + kichwa cha kijani, mstari mfupi,
  kisha jedwali.
- Jedwali zenye idadi (Jinsia, Hadhi, Mkoa, Kazi/Utaalamu, n.k.)
  zina mstari wa **"Jumla"** chini kiotomatiki.
- Nimebadilisha "Membership Code" (Kiingereza) kuwa "Namba ya
  Uwanachama" kwenye vichwa vya majedwali kote.

## NIMEJARIBU KWA VITENDO (siyo nadharia tu)
Nimetengeneza PDF halisi kutoka kwa code hii (Ripoti ya Muhtasari,
Wanachama, Mkoa/Tawi, Kazi/Utaalamu, Akaunti) na kuziangalia kama
picha - zote zinaonekana sahihi na zinafanana kwa karibu sana na
picha uliyonipa. Sikutuma kitu ambacho sijakithibitisha kinafanya
kazi.

## Faili iliyobadilika
- app/reports/pdf_reports.py (faili MOJA tu - kazi zote za kutengeneza
  PDF ziko humu humu)

## Kitu kimoja kidogo kisichofanana 100%
Kwenye picha yako, kila mstari wa jedwali (mfano "Hajawekwa") una icon
ndogo ya mtu kabla ya jina. Sikuiongeza (ingehitaji "icon" kwa kila
mstari mmoja mmoja, jambo dogo la ziada) - kila kitu kingine
kinafanana. Kama unaihitaji hiyo pia, niambie nitaiongeza.

## Muhimu
- Hakuna mabadiliko ya database/migration.
- Weka faili hii mahali pake, anzisha upya backend - ripoti zote za
  PDF (Wanachama, Uongozi, Elimu, Muhtasari, Mkoa/Tawi, Ajira,
  Mafunzo, Kazi/Utaalamu, Wadau, Akaunti, Usajili kwa Kipindi, Taarifa
  Zisizokamilika, Uthibitisho Unaosubiri) zitatumia muundo huu mpya
  MOJA KWA MOJA.
