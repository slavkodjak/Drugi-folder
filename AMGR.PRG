#INCLUDE "Kordef.ch"
***************************************
* Program  : Amgr.prg
* Opis     : Amortizacione grupe
* Autor    :
* Datum    : februar, '95. god.
* Poziva ga: Ossr
***************************************
PROC Amgr
*
LOCAL opcija:=;
{{" Azuriranje ","Azuriranje podataka o amortizacionim grupama" ,"Amgr1()"},;
 {" Brisanje   ","Brisanje podataka o amortizacionim grupama"   ,"Amgr2()"},;
 {" Prikaz     ","Prikaz podataka o amortizacionim grupama"     ,"AmgrX('P')"},;
 {" Stampa     ","Stampa podataka o amortizacionim grupama"     ,"AmgrX('S')"}}

Poru1r( 'Amortizacione grupe')
*
RETURN opcija
***************************************
PROC Amgr1         //azuriranje
*
LOCAL x:=4,dn //,ekran:=SAVESCREEN(2,0,23,79)
Cls2()
Poru1r('Azuriranje amortizacionih grupa')
Poruka(' ')
*
wamgr  := SPACE(7) 
wnaziv1:= SPACE(50)
wnaziv2:= SPACE(50)
wnaziv3:= SPACE(50)
wstopa := 0
*
IF !Netuse( "Amgr" ); RETURN; ENDIF
SET INDEX TO Amgr1
*
DO WHILE .T.
   @ 5,5 TO 14,74
   @ x+ 2,10 SAY PADR("Sifra amortiz. grupe",29,".") GET wamgr PICT "@R 999.99.99"; 
             VALID IF(EMPTY(wamgr),;
             Lukap(,@wamgr   ,"Amgr",1,,,;
                   {{"Sifra" ,"amgr"  , 7},;
                    {"Stopa" ,"stopa" ,  },;
                    {"Naziv" ,"naziv1",50}},,5), .T.)
   READ
   IF LASTKEY()=K_ESC; EXIT; ENDIF
   Poruka(' ')
   dn:=' '
   SEEK wamgr   
   IF FOUND()
      wnaziv1 := naziv1
      wnaziv2 := naziv2
      wnaziv3 := naziv3
      wstopa  := stopa
   ELSE
      wnaziv1:= SPACE(50)
      wnaziv2:= SPACE(50)
      wnaziv3:= SPACE(50)
      wstopa := 0
   ENDIF
   
   @ x+ 4,10 SAY "Naziv AMGR:" GET wnaziv1
   @ x+ 5,22 GET wnaziv2
   @ x+ 6,22 GET wnaziv3
   @ x+ 8,10 SAY PADR("Godisnja stopa (%)",29,".") GET wstopa PICT "999.999"
   @ x+10,50 SAY "Upis (D/N)?" GET dn PICT "!" VALID dn $ "DN"
   READ
   
   IF (LASTKEY()=K_ESC) .OR. (dn<>"D"); LOOP; ENDIF
   IF FOUND()
      IF !Reclok(); EXIT; ENDIF
   ELSE
      IF !Dodrec(); EXIT; ENDIF
   ENDIF

   REPLACE amgr   WITH wamgr   
   REPLACE naziv1 WITH wnaziv1
   REPLACE naziv2 WITH wnaziv2
   REPLACE naziv3 WITH wnaziv3
   REPLACE stopa  WITH wstopa
   COMMIT
   Poruka("Uspesno azurirani podaci o amort. grupi "+wamgr )
ENDDO
*
CLOSE ALL
RETURN
***************************************
PROC Amgr2         //brisanje AMGR
*
LOCAL x:=4,dn //,ekran:=SAVESCREEN(2,0,23,79)
Cls2()
Poru1r('Brisanje amortizacionih grupa')
Poruka(' ')
*
wamgr  := SPACE(7) 
wnaziv1:= SPACE(50)
wnaziv2:= SPACE(50)
wnaziv3:= SPACE(50)
wstopa := 0
*
IF !Netuse( "Amgr" ); RETURN; ENDIF
SET INDEX TO Amgr1
*
DO WHILE .T.
   @ 5,5 TO 14,74
   @ x+2,10 SAY PADR("Sifra amortiz. grupe",29,".") GET wamgr PICT "@R 999.99.99"; 
            VALID  Lukap(,@wamgr  ,"Amgr",1,,,;
                        {{"Sifra" ,"amgr"  , 7},;
                         {"Naziv ","naziv1",50}},,10)
   READ
   IF LASTKEY()=K_ESC ;EXIT;ENDIF
   Poruka(' ')
   dn:=' '
   SEEK wamgr   
   IF FOUND()
      wnaziv1 :=naziv1
      wnaziv2 :=naziv2
      wnaziv3 :=naziv3
      wstopa  :=stopa
   ELSE
      wnaziv1 :=SPACE(50)
      wnaziv2 :=SPACE(50)
      wnaziv3 :=SPACE(50)
      wstopa  :=00.00
   ENDIF
   
   @ x+ 4,10 SAY "Naziv AMGR:" GET wnaziv1 WHEN .F.
   @ x+ 5,22 GET wnaziv2 WHEN .F.
   @ x+ 6,22 GET wnaziv3 WHEN .F.
   @ x+ 8,10 SAY PADR("Godisnja stopa (%)",29,".") GET wstopa PICT "999.999"  WHEN .F.
   
   @ x+10,50 SAY "Brisati (D/N)?" GET dn PICT "!" VALID dn $ "DN"
   READ
   
   IF (LASTKEY()=K_ESC) .OR. (dn<>"D"); LOOP; ENDIF
   IF !FOUND() 
      Poruka('Neko je u medjuvremenu obrisao stavku '+wmagr,1)
   ENDIF   
   IF !Reclok(); LOOP; ENDIF

   DELETE
   COMMIT
   Poruka("Uspesno obrisani podaci o amort. grupi "+wamgr,2 )
ENDDO
*
CLOSE ALL
RETURN
***************************************
PROC AmgrX(p_s)    //prikaz i stampa
*
LOCAL x:=4,dn //,ekran:=SAVESCREEN(2,0,23,79)
Cls2()
Poru1r(IF(p_s="P","Prikaz","Stampa") + ' amortizacionih grupa')
Poruka(' ')
*
wgrupa :=SPACE(3) 
wpodgr :=SPACE(2)
*
IF !Netuse( "Amgr" ); RETURN; ENDIF
SET INDEX TO Amgr1
*
DO WHILE .T.
   @ 3,2 SAY "Grupa:" GET wgrupa PICT "999"
   @ 3,20 SAY "Podgrupa:" GET wpodgr PICT "99"
   READ

   IF LASTKEY()=K_ESC ;EXIT;ENDIF
   
   
   IF p_s="P"
      Prikaz(RTRIM(wgrupa+wpodgr),,;
            {{"Gr."   ,"SUBSTR(amgr ,1,3)",  },;
             {"Pod"   ,"SUBSTR(amgr ,4,2)", 3},;
             {"Poz"   ,"SUBSTR(amgr ,6,2)", 3},;
             {"Stopa" ,"stopa"            , 7},;
             {"Naziv1","naziv1"           ,50},;
             {"Naziv2","naziv2"           ,50},;
             {"Naziv3","naziv3"           ,50}})
   ELSE         
      t:=St_kr(ST_KRUPNO+"AMORTIZACIONE GRUPE",{5,{||QOUT()}}, RTRIM(wgrupa+wpodgr),,;
            {{"Gr."        ,"SUBSTR(amgr ,1,3)"   ,  3},;
             {"Pod"        ,"SUBSTR(amgr ,4,2)"   ,  3},;
             {"Poz"        ,"SUBSTR(amgr ,6,2)"   ,  3},;
             {"Stopa"      ,"stopa"               ,  7},;
             {"Naziv AMGR" ,"naziv1"              ,   }})

      t:cargo[CR_PRORED]:={||QOUT(SPACE(20),naziv2),;
                             QOUT(SPACE(20),naziv3),;
                             QOUT("") }
      St_ak(t)

   ENDIF           
ENDDO
*
CLOSE ALL
RETURN
***************************************
