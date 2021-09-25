#INCLUDE "Kordef.ch"
**************************************
* Program  : AM_OS.PRG
* Opis     : Amortizacija osn.sredstava
* Autor    : 
* Datum    : juli, '95. god.
* Poziva ga: Amort
***************************************
PROC Am_os         //amortizacija OS
*
LOCAL opcija:=;
{{" Obracun   ", "Obracun amortizacije OS"             , "Am_os1()"   },;
 {" Prikaz    ", "Prikaz obracunate amortizacije OS"   , "Am_os2('P')"},;
 {" Stampa    ", "Stampa obracunate amortizacije OS"   , "Am_os2('S')"},;
 {" Knjizenje ", "Knjizenje obracunate amortizacije OS", "Am_os3()"   }}

Poru1r( "Amortizacija OS")
*
RETURN opcija
***************************************
PROC Am_os1        //obracun amort. OS
*
LOCAL x:=2,dn
*
Poru1r("Obracun amortizacije OS")
Poruka(" ")
*
IF !Netuse( "Am_os", .T. ); RETURN; ENDIF
INDEX ON konto TO Am_os1
ZAP

IF !Netuse( "Amgr" ); RETURN; ENDIF
SET INDEX TO Amgr1

IF !Netuse( "Kplan" ); RETURN; ENDIF
SET INDEX TO Kplan1

IF !Netuse( "Ossr" ); RETURN; ENDIF
SET INDEX TO Ossr1
SET RELATION TO amgr INTO Amgr

IF !Netuse( "Stavke" ); RETURN; ENDIF
SET INDEX TO Stavke3    //konto+DTOS(datdok)
*
wkonto := SPACE(12)     //najnizi nivo subsintetike (tip_a="S")     
wdat1  := DATUM_PRVI    //CTOD("")      //od datuma ("01.01.tg")
wdat2  := CTOD("")      //do datuma
brmes  := 0             //broj meseci za koji se racuna amortizacija
dn:="."

DO WHILE .T.
   Cls2()     
   @ 5,5 TO 11,74
   @ x+5,10 SAY "Konto nabavke" GET wkonto PICT "@K 999999999999" VALID;
            Lukap(,@wkonto,"Kplan",1, ,2,;
                 {{"Konto nabavke","konto "       ,12},;
                  {"Naziv konta"  ,"LEFT(opis,40)",40},;
                  {"A"            ,"tip_a"        ,  }},,20)
   @ x+6,10 SAY "Od datuma...." GET wdat1  VALID !EMPTY(wdat1)
   @ x+7,10 SAY "Do datuma...." GET wdat2 VALID wdat2 > wdat1
   @ x+9,50 SAY "Obrada (D/N)?" GET dn PICT "!" VALID dn $ "DN"
   READ

   IF LASTKEY()=27; EXIT; ENDIF
   IF dn="N";       LOOP; ENDIF

   SELECT Am_os         //---------
   ZAP                  //isprazni stari obracun u Am_os.dbf

   SELECT Stavke        //---------

   //predvidjeno je da se amort.racuna kumulativno, tj. od 01.01.tg do odredjenog
   //perioda. Kada se am. izracuna za sledeci period (I-VI) onda se stornira za
   //I kvartal, zatim se izracuna za I-IX i stornira za I-VI itd...
   //znaci za novi period (od 01.01.tg do ??) se izracuna, a prethodni se stornira

   SEEK RTRIM(wkonto)
   DO WHILE konto=RTRIM(wkonto)

      wsifdok:= sifdok       //sifra dokumenta
      wnvr_os:= 0            //nab.vredn.OS
      wvr_am := 0            //vrednost amortiz. OS
      wstopa := 0            //stopa amortizacije OS
      wdodam := 0            //dodatna stopa amortiz. OS
      ispr_vr:= 0            //ispravka vrednosti OS
      sad_vr := 0            //sadasnja vrednost OS
      wkonto1:= konto        //anal.konto (konto+sifra OS)
      wsifanl:= sifanl       //sifra anal.=sifra OS
      wdatdok:= datdok       //datum dokum.koji knjizi nab.vrednost
      //wkolic := 1          //kolicina OS (16.09.14)-ali ne treba jer se unosi
                             //vrednost za sve komade, a ne po komadu

      Poruka("Konto "+ ALLTRIM(wkonto1) )

      //sabira nab.vred. za jedno OS
      DO WHILE konto = wkonto1
         //wnvr_os += dug //24.01.03
         wnvr_os += dug - pot
         SKIP
      ENDDO

      tek_sl = RECNO()       //zapamti slog

      //sabira vred.amort. za jedno OS
      //wkonto2 = STUFF(wkonto1,4,1,"8") //zameni 4.cifru sa "8" (0231->0238)
      wkonto2 = STUFF(wkonto1,3,0,"9") //ubaci "9" na 3.poz.(0231->02931), 22.01.15
      SEEK RTRIM(wkonto2)
      DO WHILE konto = RTRIM(wkonto2)
         //wvr_am += pot  //24.01.03
         wvr_am += pot - dug
         SKIP
      ENDDO

      sad_vr = wnvr_os - wvr_am        //sadasnja vrednost OS
      IF sad_vr < 0.01  //ako je OS amortizovano (wnvr_os = wvr_am)
         GOTO tek_sl
         LOOP
      ENDIF


      SELECT Ossr       //---------

      //imaKol:=.F.
      //imeKol:="KOLIC"

      //proveri ima li polje "KOLIC" u OSSR (16.09.14)
      //FOR i=1 TO FCOUNT()
      //   IF imeKol = FIELDNAME(i)
      //      imaKol:=.T.
      //   ENDIF
      //NEXT

      SEEK wsifanl
      wdodam = dodam                                                 
      wstopa = Amgr->stopa   //ako je EMPTY(amgr),znaci OS je otpisano (van upotrebe)
      //wkolic:= IF(imaKol, kolic,wkolic)     //16.09.14

      //za gradj.objekte amort.se racunla od naredne godine, a od uvodjenja
      //MRS amort.se racuna od narednog meseca
      //IF YEAR(Ossr->datnab)=VAL(god_sub) .AND. LEFT(wkonto1,3)="022"
      //   LOOP      //isklj. 11.02.05
      //ENDIF

      //resiti "wdatdok" ako "wnvr_os" ima vise od jedne stavke, a razlicitog
      //su datuma (uvesti niz sa 3 elem.=>nvr_os,datdok,brmes)-> Gospova 24.01.02.
      //"datnab" u sif.OS se stavlja kao "datdok" (datnab=datdok)

      //IF wsifdok="01" .OR. YEAR(Ossr->datnab) < VAL(god_sub)  //03.11.05
      IF wsifdok="01" .AND. YEAR(Ossr->datnab) < VAL(god_sub) .AND. !EMPTY(Ossr->datnab)
         //ako je PS i prelazak na FIPO nije od pocetka godine, pa "datdok"
         //ne moze biti 01.01.tg. za prenos stanja, nego npr. 01.07.tg.
         brmes = MONTH(wdat2)/12  //obracun AM od pocetka tek.godine
      ELSE
         //IF DAY(wdatdok) > 15   //Vukica,20.12.10
         brmes = ( MONTH(wdat2)-MONTH(wdatdok) )/12   //naredni mesec
         //ELSE
         //brmes = (MONTH(wdat2)-MONTH(wdatdok)+1)/12   //tekuci mesec
         //ENDIF
      ENDIF

      //SELECT Ossr       //---------
      //SEEK wsifanl
      //wdodam = dodam                                                 
      //wstopa = Amgr->stopa   //ako je EMPTY(amgr),znaci OS je otpisano (van upotrebe)

      //IF wstopa <= 0
      //   Poruka("Amort.grupa za "+ALLTRIM(wsifanl)+ " nije upisana",1)
      //   INKEY(0)
      //ENDIF

      IF !FOUND()
         Poruka("Osnovno sredstvo "+ALLTRIM(wsifanl)+ " ne postoji", 1)
         INKEY(0)
      ENDIF

      ispr_vr:= wnvr_os * brmes * (wstopa+wdodam)/100      //* wkolic 14.10.14
      //ako je AM veca od sad.vrednosti, uzeti sad.vrednost
      ispr_vr:= IF(ispr_vr > sad_vr, sad_vr, ispr_vr)


      SELECT Am_os      //---------
      IF ispr_vr > 0
         IF !Dodrec(); EXIT; ENDIF

         REPLACE konto  WITH wkonto1
         REPLACE sifos  WITH wsifanl
         REPLACE opis   WITH "Amortizacija"      //Ossr->naziv
         REPLACE dat_ob WITH wdat2
         REPLACE nvr_os WITH wnvr_os
         REPLACE am_os  WITH ispr_vr
         REPLACE dat1   WITH wdat1
         REPLACE dat2   WITH wdat2
         DBUNLOCK()
      ENDIF

      //ispr_vr = 0
      SELECT Stavke     //---------
      GOTO tek_sl       //idi na zapmaceni slog
   ENDDO
ENDDO
*
CLOSE ALL
RETURN
***************************************
PROC Am_os2(p_s)   //prikaz i stampa obr.amort. OS
*
LOCAL x:=2,dn
Cls2()     
*
IF p_s="P"
   Poru1r("Prikaz obracunate amortizacije OS")
ELSE
   Poru1r("Stampa obracunate amortizacije OS")
ENDIF
Poruka("")
*
IF !Netuse( "Ossr" ); RETURN; ENDIF
SET INDEX TO Ossr1
*
IF !Netuse( "Am_os" ); RETURN; ENDIF
INDEX ON konto TO Am_os1 
SET RELATION TO sifos INTO Ossr
*
IF p_s="P"
   Prikaz(,,{{"RBR"         ,"0"          , 4},;
             {"Konto "      ,"konto"      ,  },;
             {"Naziv OS"    ,"Ossr->naziv",30},;
             {"Nabvr_OS"    ,"nvr_os"     ,  ,{||nvr_os} },;
             {"Amortizacija","am_os"      ,  ,{||am_os } },;
             {"Knj"         ,"ind_k"      ,  }})
ELSE
   Stampa(SPACE(3)+ST_KRUPNO+"Prikaz obracunate amortizacije"+REPL((CHR(10)+CHR(13)),2)+;
          "Od " +DTOC(dat1) +" do "+DTOC(dat2)+SPACE(20),,,,;
          {{"RBR"         ,"0"          , 4},;
           {"Konto "      ,"konto"      ,  },;
           {"Naziv OS"    ,"Ossr->naziv",30},;
           {"Nab.vred. OS","nvr_os"     ,  ,{||nvr_os} },;
           {"Amortizacija","am_os"      ,  ,{||am_os } }})
ENDIF
*
CLOSE ALL
RETURN
***************************************
PROC Am_os3        //knjizenje obrac.amort. OS
*
LOCAL x:=2,dn
Cls2()     

Poru1r("Knjizenje obracunate amortizacije OS")
*
IF !Netuse( "Dokum" ); RETURN; ENDIF
SET INDEX TO Dokum1

IF !Netuse( "Kplan" ); RETURN; ENDIF
SET INDEX TO Kplan1

IF !Netuse( "Ossr" ); RETURN; ENDIF
SET INDEX TO Ossr1

IF !Netuse( "Evnal" ); RETURN; ENDIF
SET INDEX TO Evnal1, Evnal2

IF !Netuse( "St_kon" ); RETURN; ENDIF
SET INDEX TO St_kon1

IF !Netuse( "Stavke" ); RETURN; ENDIF
SET INDEX TO Stavke1, Stavke2, Stavke3, Stavke4, Stavke5, Stavke6, Stavke7, Stavke8

IF !Netuse( "Am_os" ); RETURN; ENDIF
INDEX ON konto TO Am_os1 
SET RELATION TO sifos INTO Ossr
*
SETCOLOR(sc_crv)
@ 5,5,8,74 BOX B_SINGLE+" "
@ 6,8 SAY "Amortizacija se knjizi kao privremena - knjizenje ZBIRNO,"
@ 7,8 SAY "                      ili kao konacna - knjizenje ANALITICKI."
SETCOLOR(sc_st)
*
wkonto = SPACE(12)
wsifdok= "46"
wbrnal = SPACE(10)
wdatnal= dat_ob    //datum obracuna
wbrsta = 0         //broj stavki
wam_os = 0         //vredn.amortizacije (anal.stavka)
zam_os = 0         //vredn.amortizacije (zbirna stavka)
ind_k= " "         //ind.knjiz. (K-knjizeno, " "-nije knjizeno
pk   = " "         //privremena ili konacna amort.
dn   = "."
*
DO WHILE .T.
   Poruka(" ")
   @ 11,5 TO 20,74
   @ x+11,10 SAY "Vrsta dokumenta" GET wsifdok VALID;
             Lukap(,@wsifdok,"Dokum",1, ,2,   ;
                  {{"Sifra"          ,"sifdok",  },;
                   {"Naziv dokumenta","nazdok",30}})

   @ x+12,10 SAY "Broj naloga...." GET wbrnal  VALID !EMPTY(wbrnal) .AND.;
             Imanal1(wsifdok,wbrnal)
   @ x+13,10 SAY "Datum naloga..." GET wdatnal VALID !EMPTY(wdatnal)
   @ x+14,10 SAY "Konto nabavke.." GET wkonto  PICT "@K 999999999999" VALID;
             Lukap(,@wkonto,"Kplan",1, ,2,;
                  {{"Konto"        ,"konto "       ,12},;
                   {"Naziv konta"  ,"LEFT(opis,40)",40},;
                   {"A"            ,"tip_a"        ,  }},,20)
   @ x+16,10 SAY "Privremena/konacna amortizacija (P/K)" GET pk PICT "!" VALID pk $ "PK"
   @ x+18,45 SAY "Knjizenje (D/N)?" GET dn PICT "!" VALID dn $ "DN"
   READ

   Poruka(" ")
   IF LASTKEY()=27 .OR. dn="N"; EXIT; ENDIF

   //Amortizacija se moze izracunati za sva OS, a knjiziti po pojedinim grupama
   //odnosno nalozima/kontima. "Ind_k" omogucuje da se ponovo knjizi nalog koji
   //nije korektno proknjizen zbog nestanka struje ili iz drugog razloga, a
   //istovremeno sprecava da se vec jednom proknjizeni konto knjizi ponovo pod
   //drugim nalogom.

   SEEK RTRIM(wkonto)
   DO WHILE konto = RTRIM(wkonto)
      Poruka("Konto "+ ALLTRIM(konto) )

      IF ind_k=" "      //stavka nije knjizena       
         wkonto1 = STUFF(konto,3,0,"9")     //ubaci "9" na 3.pozicju (0231->02931)
         wopis   = opis
         wsifanl = Ossr->sifos
         wdat_ob = dat_ob
         wam_os  = am_os
         zam_os += am_os
         wbrsta += 1
      ELSE              //stavka je knjizena
         SKIP
         LOOP
      ENDIF

      IF pk="K" .AND. wam_os<>0   //konacna amortizacija

         SELECT Stavke  //----------
         IF !Dodrec(); CLOSE ALL; RETURN; ENDIF

         //upis stavki u dat. STAVKE (analiticki-za konacnu AM)
         REPLACE sifdok WITH wsifdok, brnal  WITH wbrnal, datnal WITH wdatnal,;
                 brdok  WITH wbrnal, datdok WITH wdatnal, konto WITH wkonto1
         REPLACE sifanl WITH wsifanl, opissk WITH wopis, pot WITH wam_os
         DBUNLOCK()

         St_konta(sifdok, datdok, konto, dug, pot)
         SELECT Am_os   //----------
      ENDIF

      IF !Reclok(); CLOSE ALL; RETURN; ENDIF
      REPLACE ind_k WITH "K"      //"K" - stavka je knjizena, ovo je dobro
      DBUNLOCK()                  //ako ne bude prekida posle line 300 (ENDDO)
      SKIP
      wam_os=0
   ENDDO
   DBCOMMIT()

   IF zam_os = 0
      Poruka("Konto "+RTRIM(wkonto) +" nema neproknjizenih stavki", 1)
      INKEY(0)
      EXIT
   ENDIF

   //upis zbirne stavke u dat. STAVKE (i za konacnu i za privr. AM)
   SELECT Stavke   //----------
   IF !Dodrec(); CLOSE ALL; RETURN; ENDIF

   REPLACE sifdok WITH wsifdok, brnal  WITH wbrnal, datnal WITH wdatnal,;
           brdok  WITH wbrnal, datdok WITH wdatnal, konto WITH "5400"
   REPLACE sifanl WITH wsifanl, opissk WITH wopis, dug WITH zam_os
   DBUNLOCK()

   St_konta(sifdok, datdok, konto, dug, pot)

   //upis zbirne stavke u dat. STAVKE (za privr. AM)
   IF pk="P" .AND. zam_os>0       //privremena amortizacija
      IF !Dodrec(); CLOSE ALL; RETURN; ENDIF

      REPLACE sifdok WITH wsifdok, brnal  WITH wbrnal, datnal WITH wdatnal,;
              brdok  WITH wbrnal, datdok WITH wdatnal, konto WITH IF(wkonto="022", "022888","023888")
      REPLACE sifanl WITH wsifanl, opissk WITH wopis, pot WITH zam_os
      DBUNLOCK()

      St_konta(sifdok, datdok, konto, dug, pot)
   ENDIF


   //upis zbirnih podataka naloga u EVNAL
   SELECT Evnal    //----------
   SEEK wsifdok+wbrnal
   IF FOUND()
      IF !Reclok(); CLOSE ALL; RETURN; ENDIF
   ELSE
      IF !Dodrec(); CLOSE ALL; RETURN; ENDIF
   ENDIF

   REPLACE sifdok WITH wsifdok,;
           brnal  WITH wbrnal ,;
           datnal WITH wdatnal,;
           datum  WITH DATE() ,;
           opis   WITH "Amortizacija",;
           brsta  WITH wbrsta,;
           dug    WITH zam_os,;
           pot    WITH zam_os,;
           ind_k  WITH "D"   ,;
           oper   WITH sif_kor
   DBUNLOCK()
   DBCOMMIT()

   SELECT Am_os    //----------
   zam_os=0
ENDDO
*
CLOSE ALL
RETURN
***************************************
PROC St_konta(wsifdok,wdatdok,wkonto,wdug,wpot)  //upis stanja konta u St_kon.dbf
*
//wsifdok - sifra dokumenta proknjizene stavke u Stavke.dbf
//wkonto  - anal. konto proknjizene stavke u Stavke.dbf
//wdug    - iznos "dug" proknjizene stavke u Stavke.dbf
//wpot    - iznos "pot" proknjizene stavke u Stavke.dbf
//wdatdok - datum dokumenta proknjizene stavke u Stavke.dbf

LOCAL sbaza := ALIAS()  //ime aktivne baze

//upis stanja konta za svaki konto iz zadatog naloga
SELECT St_kon           //---------
SEEK wkonto 
IF FOUND()
   IF !Reclok(); RETURN; ENDIF
ELSE
   IF !Dodrec(); RETURN; ENDIF
ENDIF

IF wsifdok="01"    //poc.stanje
   REPLACE konto WITH wkonto, ps_dug WITH ps_dug+wdug,;
           ps_pot WITH ps_pot+wpot
ELSE
   d="d"+PADL(MONTH(wdatdok),2,"0")        //D01,D02,...
   p="p"+PADL(MONTH(wdatdok),2,"0")        //P01,P02,...
   REPLACE konto WITH wkonto, &d WITH &d+wdug, &p WITH &p+wpot 
ENDIF

REPLACE s_dug WITH s_dug+wdug, s_pot WITH s_pot+wpot 
DBUNLOCK()

SELECT (sbaza)     //----------
*
RETURN
***************************************
*****************************
FUNC Imanal1(wsifdok,wbrnal)      //postiji li nalog
*
sbaza=ALIAS()
SELECT Evnal       //----------
SEEK wsifdok+wbrnal
IF FOUND()
   SELECT (sbaza)  //----------
   Poruka("Nalog "+wsifdok+"/"+RTRIM(wbrnal)+ " vec postoji",1)
   RETURN .F.
ENDIF
SELECT (sbaza)     //----------
*
RETURN .T.
*****************************
