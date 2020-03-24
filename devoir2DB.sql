/*C7) PL/SQL offre la possibilité d’utiliser l’option CURRENT OF nom_curseur dans la clause
WHERE des instructions UPDATE et DELETE. Cette option permet de modifier ou de
supprimer la ligne distribuée par la commande FETCH. Pour utiliser cette option il faut ajouter
la clause FOR UPDATE à la fin de la définition du curseur.
Compléter le script suivant qui permet de modifiant le salaire d’un pilote avec les contraintes
suivantes :
- Si la commission est supérieure au salaire alors on rajoute au salaire la valeur de la
commission et la commission sera mise à la valeur nulle.
- Si la valeur de la commission est nulle alors supprimer le pilote du curseur.
DECLARE
CURSOR C_pilote IS
 SELECT nom, sal, comm
FROM pilote
WHERE nopilot BETWEEN 1280 AND 1999 FOR UPDATE;
 v_nom pilote.nom%type;
 v_sal pilote.sal%type;
 v_comm pilote.comm%type;
BEGIN
. . .
END;*/

SET SERVEROUTPUT ON BEGIN
DECLARE
CURSOR C_pilote IS
 SELECT nom, sal, comm
FROM pilote
WHERE nopilot BETWEEN 1280 AND 1999 FOR UPDATE;
 v_nom pilote.nom%type;
 v_sal pilote.sal%type;
 v_comm pilote.comm%type;
BEGIN
open C_pilote Loop FETCH C_pilote INTO v_nom , v_sal , v_comm;
EXIT WHEN C_pilote%NOTFOUND;
IF (v_comm> v_sal)BEGIN{
	UPDATE PILOTE SET SAL = v_sal+ v_comm AND v_comm=0  WHERE CURRENT OF C_pilote;
	DBMS_OUTPUT.PUT_LINE('------------------UPDATE-----------------');
	DBMS_OUTPUT.PUT_LINE(num);
}
ELSEIF(v_comm = 0)BEGIN{
	DELETE FROM  PILOTE WHERE CURRENT OF C_pilote ;
	DBMS_OUTPUT.PUT_LINE('------------------DELETE-----------------');
	DBMS_OUTPUT.PUT_LINE(num);
}
END IF;
END Loop;
CLOSE C_pilote;
END;

#-------------------------------------------------------------------------------------------------
/*	C8) Écrire une procédure PL/SQL qui réalise l’accès à la table PILOTE par l’attribut nopilote.Si le
 	numéro de pilote existe, elle envoie dans la table ERREUR, le message « NOM PILOTE-OK »
	sinon le message « PILOTE INCONNU ». De plus si sal<comm, elle envoie dans la table
	ERREUR le message « « NOM PILOTE, COMM >SAL ».
	Indication : une erreur utilisateur doit être explicitement déclenchée dans la procédure PL/SQL par
	l’ordre RAISE. La commande RAISE arrête l’exécution normale du bloc et transfert le contrôle
	au traitement de l’exception.*/ 

CREATE OR REPLACE PROCEDURE Proc1(NPIL in PILOTE.NOPILOT%type)
IS P_pilot PILOTE%rowtype 
BEGIN
 SELECT NOPILOT,SAL ,COMM into P_pilot FROM Pilote WHERE PILOTE.NOPILOT=NPIL ;
 IF (P_pilot.COMM > P_pilot.SAL)BEGIN{
 	RAISE ERREUR_COMM;
}
END IF;
EXCEPTION 
WHEN NO_DATA_FOUND THEN
INSERT INTO ERREUR VALUES (P_pilot.NOPILOTE,'known');
WHEN DATA_FOUND THEN
INSERT INTO ERREUR VALUES (P_pilot.NOPILOTE,'UnKnown');
END;

#--------------------------------------Création des vues-----------------------------------------------------------
/*	D1) Créer une vue (v-pilote) constituant une restriction de la table pilote, aux pilote qui habitent Paris. */

CREATE VIEW V_PILOTE AS SELECT * FROM PILOTE WHERE VILLE='PARIS';

#-------------------------------------------------------------------------------------------------
/*	D2) Vérifier est ce qu’il est possible de modifier les salaires des pilotes habitant Paris à travers la vue v-pilote */

UPDATE V_PILOTE SET SAL =SAL*10 ; SELECT * FROM V_PILOTE;

#-------------------------------------------------------------------------------------------------
/*	D3) Créer une vue (dervol) qui donne la date du dernier vol réalisé par chaque avion */

CREATE VIEW DERVOL AS SELECT AVION,MAX(DATE_VOL) AS MAX FROM AFFECTATION GROUP BY AVION;

#-------------------------------------------------------------------------------------------------
/*	D4) Une vue peut être utilisée pour contrôler l’intégrité des données grâce à la clause ‘CHECK OPTION’.
Créer une vue (cr_pilote) qui permette de vérifier lors de la modification ou de l’insertion d’un
pilote dans la table PILOTE les critères suivants :
- Un pilote habitant Paris a toujours une commission
- Un pilote qui n’habite pas Paris n’a jamais de valeur de commission. */

CREATE VIEW CR_PILOTE AS SELECT * FROM PILOTE 
WHERE(COMM IS NOT NULL AND VILLE='PARIS')
OR(COMM IS NULL AND VILLE<>'PARIS')
WITH CHECK OPTION;

#-------------------------------------------------------------------------------------------------
/*	D5) Créer une vue (nomcomm) qui permette de valider, en saisie et mise à jour, le montant
commission d’un pilote selon les critères suivant :
- Un pilote qui n’est affecté à au moins un vol, ne peut pas avoir de commission
- Un pilote qui est affecté à au moins un vol peut recevoir une commission.
Vérifier les résultats par des mises à jour sur la vue nomcomm */

CREATE VIEW NOMCOMM AS SELECT * FROM PILOTE 
WHERE(NOPILOT IN (SELECT PILOTE FROM AFFECTATION) AND COMM IS NOT NULL)
OR(NOPILOT NOT IN (SELECT PILOTE FROM AFFECTATION) AND COMM IS NULL)
WITH CHECK OPTION;