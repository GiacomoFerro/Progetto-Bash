#!/bin/bash
#$1 passwd e $2 group

#PasswdManager.sh created by Giacomo Ferro

#definizione di funzioni:

function menu {
	echo "";
	echo "1 = stampa tutti gli utenti";
	echo "2 = stampa l'elenco dei gruppi";
	echo "3 = stampa gli utenti per gruppo";
	echo "4 = inserisci un nuovo utente";
	echo "5 = modifica un utente";
	echo "6 = elimina un utente";
	echo "7 = esci";
	echo "";
	echo "inserisci la tua scelta:";
	read scelta;
	return $scelta;
}

function stampaScelte {

	echo "";
	echo "1 = modifica password";
	echo "2 = modifica gruppo";
	echo "3 = modifica informazioni utente";
	echo "4 = modifica il path per la home";
	echo "5 = modifica il path per la bash";
	echo "";
	echo "inserisci la tua scelta:";
	read modifica;
	return $modifica;

}

#controllo se ci sono gli argomenti corretti..
if test $# -gt 2 -o $# -lt 2 ; then 

	echo "";
	echo "Hai inserito un numero di parametri diverso da due.";
	echo "Questo script esegue delle manipolazioni sui file passwd e group.";
	echo "Per fare ciò sono necessari i percorsi relativi dei due file da riga di comando.";
	echo "I percorsi devono essere nella forma .../passwd e .../group".
	echo "";
	exit;
fi

if [ $# -eq 2 ]; then 
	if [ -f $1 -a -f $2 ]; then
	
		pathPasswd=$(basename $1); # controllo se la parte finale del percorso è corretta
		
		if [[ $pathPasswd == "passwd" ]]; then
			
			pathGroup=$(basename $2);
			
	 		if [[ $pathGroup == "group" ]]; then
	 			echo "";
				echo "Hai inserito tutti i parametri correttamente.";
		 	else # se passwd o group non esistono allora stampo errore
		 		echo "";
				echo "Hai inserito due parametri in cui sono presenti degli errori nel percorso.";
				echo "In alternativa uno dei due file non esiste in quel percorso.";
				echo "";
				exit;
		 	fi
		else # se passwd o group non esistono allora stampo errore
			echo "";
			echo "Hai inserito due parametri in cui sono presenti degli errori nel percorso.";
			echo "In alternativa almeno un file non esiste in quel percorso.";
			echo "";
			exit;
		fi
	else # se uno dei due percorsi è sbagliato allora ritorno un errore
		echo "";
		echo "Hai inserito due parametri in cui sono presenti degli errori nel percorso.";
		echo "In alternativa almeno un file non esiste in quel percorso.";
		echo "";
		exit;
	fi
fi

scelta=0; #=0 all'inizio

while [ $scelta -lt 7 -o $scelta -gt 7 ]; do #ciclo finchè non inserisco 7
	
	menu;
	echo "";
	
	#eseguo le operazioni scelte
	if test $scelta -eq 1; then 
		
		cp $1 passwdTemp.txt; # copia temporanea
		
		cat $1 | wc -l > riga.txt; # salvo il numero totale di righe
		
		riga=$(cat riga.txt); #mi serve per proseguire nell'associazione dei GID
		cont=1;
		
		diff=$riga;
		let diff-=1;
		
		echo "UTENTE---->GRUPPO";
		while [ $cont -le $riga ]; do
			
			cat passwdTemp.txt | head -1 | cut -d: -f4 > GID.txt;
			grep -w $(cat GID.txt) $2 | cut -d: -f1 > gruppo.txt;
			
			cat passwdTemp.txt | head -1 | cut -d: -f1 > utente.txt;
			
			#salvo le informazioni degli utente e del suo gruppo di appartenza
			user=$(cat utente.txt);
			gruppo=$(cat gruppo.txt);
			
			#stampo l'utente
			echo $user"---->"$gruppo;
	
			#escludo la prima riga e poi aggiorno passwdTemp.txt
			cat passwdTemp.txt | tail -$diff > passwdTemp2.txt;
			
			cp passwdTemp2.txt passwdTemp.txt;
			
			let diff-=1; # aggiorno il contatore dell'aggiornamento del file
			let cont+=1; # aggiorno sentinella del file
			
		done
		
		if [ $riga -gt 0 ]; then # elimino i file se il file non è vuoto
			#rimuovo i file temporanei
			rm passwdTemp.txt;
			rm passwdTemp2.txt;
			rm riga.txt;
			rm gruppo.txt;
			rm GID.txt;
			rm utente.txt;
		else
			rm passwdTemp.txt;
			rm riga.txt;
		fi	
	fi
	
	if test $scelta -eq 2; then

		echo "ELENCO GRUPPI" > comando2.txt; # creo il titolo
		cut -d: -f1 $2 >> comando2.txt;
		cat comando2.txt;
		
		# cancello il file temporaneo
		rm comando2.txt;
		
	fi	

	if test $scelta -eq 3; then 

		echo "inserisci il nome del gruppo da elaborare:";
		read gruppo;
		
		cp $1 passwdTemp.txt; # copio passwd per manipolarlo
		cut -d: -f1 $2 > gruppi.txt; # creo un file con i nomi dei gruppi
	
		if [ $(grep -xc "$gruppo" gruppi.txt) -eq 0 ]; then
			echo "";
			echo "ERRORE. Nome del gruppo non esistente.";
			#rimuovo i file temporanei
			rm passwdTemp.txt;
			rm gruppi.txt;
		else
		
			#Cerco il gruppo e salvo la riga corrispondente.
			grep -xn "$gruppo" gruppi.txt | cut -d: -f1 > riga.txt;
		
			cut -d: -f1,2 $2 > gruppi.txt; #prendo anche gli ID dei gruppi oltre ai nomi
		
			cat gruppi.txt | head -$(cat riga.txt) | tail -1 | cut -d: -f2 > GID.txt; #isolo il GID del gruppo desiderato
		
			# cerco gli utenti associati perfettamente al GID e li salvo a parte
			cat passwdTemp.txt | cut -d: -f4 > UserGID.txt; # salvo solo i GID degli utenti
			
			grep -wn "$(cat GID.txt)" UserGID.txt | cut -d: -f1 > riga.txt; #in riga ci sono gli utenti associati al GID
		
			if [ $(grep -c . riga.txt) -eq 0 ]; then
				echo "";
				echo "ERRORE. Non ci sono utenti associati al GID";
			else
				#echo "UTENTI ASSOCIATI AL GID NUMERO:" $(cat PID.txt) ;
				echo "";
				echo "Gli utenti associati al gruppo "$gruppo "sono:"; 
				echo "";
				
				diff=$(cat riga.txt | wc -l);
				let diff-=1;
				
				while [ $(grep -c . riga.txt) -gt 0 ]; do #finchè riga.txt non è vuoto...
							
					rigaUser=$(cat riga.txt | head -1); #prendo ogni volta la prima riga
					
					#salvo il nome dell'utente alla riga corrispondente
					cat passwdTemp.txt | head -$rigaUser | tail -1 | cut -d: -f1 >> comando3.txt;
					
					cat riga.txt | tail -$diff > riga2.txt; # tolgo la prima riga
					cp riga2.txt riga.txt;
					let diff-=1;
					
				done
				cat comando3.txt;
				echo "";
				#rimuovo i file creati nel while
				rm comando3.txt;
				rm riga2.txt;
			fi
 		
			#rimuovo i file temporanei
			rm passwdTemp.txt;
			rm GID.txt;
			rm gruppi.txt;
			rm riga.txt;
			rm UserGID.txt;
		
		fi

	fi
	
	if test $scelta -eq 4; then
	
		echo "";
		echo "***Creazione di un nuovo profilo utente***";
		echo "";
	
		#chiedo i campi 
		echo "inserisci nome utente:";
		read nome;
		
		echo "";
		echo "inserisci la password:";
		read password;

		echo "";
		echo "inserisci UID:";
		read userId;
	
		echo "";
		echo "inserisci nome del gruppo:";
		read gruppo;
		
		echo "";
		echo "inserisci informazioni sull'utente:";
		read inform;
		
		echo "";
		echo "inserisci il path della home:";
		read home;
		
		echo "";
		echo "inserisci il path della bash:";
		read Nbash;
		
		echo "";
		echo "";

		#controllo i dati..
		check=0; #variabile sentinella nell'inserimento
	
		lung=${#nome};
		
		if [ $lung -gt 32 ]; then
			echo "";
			echo "ERRORE. Nome utente troppo lungo (> 32 caratteri)";
			check=1;
		fi
	
		lung2=${#password};
		
		if [ $lung2 -gt 32 ]; then
			echo "";
			echo "ERRORE. Password troppo lunga (> 32 caratteri)";
			check=1;
		fi
	
		if [ $check -eq 0 ]; then
	
			cut -d: -f1 $1 > nomi.txt
	
			if [ $(grep -xc "$nome" nomi.txt) -gt 0 -a $check -eq 0 ]; then 
				echo "ERRORE. Nome utente già presente.";
				check=1;
				rm nomi.txt;
			fi
	
			cut -d: -f3 $1 > UID.txt
		
			if [ $(grep -xc "$userId" UID.txt) -gt 0 -a $check -eq 0 ]; then
				echo "ERRORE. UID del nuovo utente è già presente.";
				check=1;
				rm nomi.txt;
				rm UID.txt;
			fi
	
			cut -d: -f1 $2 > gruppi.txt # creo un file con i nomi dei gruppi
	
			if [ $(grep -xc "$gruppo" gruppi.txt) -eq 0 -a $check -eq 0 ]; then
				echo "ERRORE. Nome del gruppo NON esistente.";
				check=1;
				rm nomi.txt;
				rm UID.txt;
				rm gruppi.txt;
			fi
		fi #fine if check=0
		
		if [ $check -eq 0 ]; then # se check non è mai stato toccato 
			
			cat $2 | cut -d: -f1 > gruppi.txt;
			
			grep -xn "$gruppo" gruppi.txt | cut -d: -f1 > riga.txt; #salvo la riga che combacia perfettamente con il pattern
			
			cat $2 | head -$(cat riga.txt) | tail -1 | cut -d: -f2 > GID.txt; 
				
			echo $nome:$password:$userId:$(cat GID.txt):$inform:$home:$Nbash >> $1;
			
			#elimino i file temporanei	
			rm nomi.txt;
			rm UID.txt;
			rm gruppi.txt;
			rm GID.txt;
			rm riga.txt;
			
			echo "";
			echo "Utente inserito con successo!";
			echo "";

		fi
	fi

	if test $scelta -eq 5; then
	
	
		echo "";
		echo "***Modifica di un profilo utente***";
		echo "";
	
		echo "inserisci nome utente da modificare:";
		read nome;
		echo "";
		echo "Sto controllando che l'utente esista..";
	
		cut -d: -f1 $1 > nomi.txt; #devo checkare il nome
		
		check=0;
		
		if [ $(grep -xc "$nome" nomi.txt) -eq 0 ]; then
			echo "";
			echo "ERRORE. Nome utente non presente.";
			rm nomi.txt;
			check=1;
		fi

		if [ $check -eq 0 ]; then
	
			#rimuovo nomi.txt
			rm nomi.txt;
	
			echo "";
			echo "Utente esistente. Bene, ora dimmi quello che vuoi modificare:";
			stampaScelte; # stampo le possibili modifiche
	
			if test $modifica -eq 1; then 
		
				echo "inserisci la nuova password:"
				read NewPassword;
				
				check=0;
				
				lung2=${#NewPassword};
		
				if [ $lung2 -gt 32 ]; then
					echo "";
					echo "ERRORE. Password troppo lunga (> 32 caratteri)";
					check=1;
				fi
		
				if [ $check -eq 0 ]; then
		
					cat $1 > passwdTemp.txt; #copia di passwd
				
					cat passwdTemp.txt | cut -d: -f1 > nomi.txt;
					grep -xn "$nome" nomi.txt | cut -d: -f1 > riga.txt; 
					
					cat passwdTemp.txt | head -$(cat riga.txt) | tail -1 > modificaUt.txt;
		
					#modifico l'utente desiderato con la nuova password
					echo $nome:$(echo $NewPassword):$(cut -d: -f3-7 modificaUt.txt) > nuovoUt.txt;
			
					#elimino l'user vecchio prendendo solo la riga interessata
					cat passwdTemp.txt | head -$(cat riga.txt) | tail -1 > UserKey.txt;
				
					#procedimento per l'elimazione del vecchio user da passwd
					grep -w "$nome" UserKey.txt | cut -d: -f1-4 > riga.txt; # salvo i primi 4 campi della riga da eliminare
			
					riga=$(cat riga.txt);
	
					sed /"${riga}"/d passwdTemp.txt > NewPasswdTemp.txt;
	
					cp NewPasswdTemp.txt $1;
		
					cat nuovoUt.txt >> $1;
					#cat $1; 
		
					#rimuovo i file temporanei
					rm modificaUt.txt;
					rm nuovoUt.txt;
					rm passwdTemp.txt;
					rm NewPasswdTemp.txt;
					rm riga.txt;
					rm UserKey.txt;
					rm nomi.txt;
					
					echo "";
					echo "Password modificata con successo!";
					echo "";
					
				fi # fine if di check
			fi
			if test $modifica -eq 2; then #devo modificare il gruppo d'appartenenza ma prima controllare l'esistenza
		
				echo "inserisci il nome del nuovo gruppo:"
				read NewGroup;
		
				cut -d: -f1 $2 > gruppi.txt; # creo un file con i nomi dei gruppi
		
				if [ $(grep -xc "$NewGroup" gruppi.txt) -eq 0 ]; then
					echo "";
					echo "ERRORE. nome gruppo non esistente";
					rm gruppi.txt;
				else
					#se il gruppo esiste prelevo da group il nuovo GID da mettere nel posto 4 dell'user selezionato
		
					cat $2 | cut -d: -f1 > gruppi.txt;
			
					grep -xn "$NewGroup" gruppi.txt | cut -d: -f1 > riga.txt; 
					
					cat $2 | head -$(cat riga.txt) | tail -1 | cut -d: -f2 > GID.txt; 
 		
					cat $1 > passwdTemp.txt; #copia di passwd
					
					cat passwdTemp.txt | cut -d: -f1 > nomi.txt;
					grep -xn "$nome" nomi.txt | cut -d: -f1 > riga.txt; 
					
					cat passwdTemp.txt | head -$(cat riga.txt) | tail -1 > modificaUt.txt;
		
					#creo la riga nuova con il nuovo GID per l'user desiderato
			echo $nome:$(cut -d: -f2-3 modificaUt.txt):$(echo $(cat GID.txt)):$(cut -d: -f5-7 modificaUt.txt) > nuovoUt.txt;
			
					#elimino l'user vecchio prendendo solo la riga interessata
					cat passwdTemp.txt | head -$(cat riga.txt) | tail -1 > UserKey.txt;
					
					grep -w "$nome" UserKey.txt | cut -d: -f1-4 > riga.txt; # salvo i primi 4 campi della riga da eliminare
			
					riga=$(cat riga.txt);
	
					sed /"${riga}"/d passwdTemp.txt > NewPasswdTemp.txt;
	
					cp NewPasswdTemp.txt $1;
		
					cat nuovoUt.txt >> $1;
					echo "";
					#cat $1; 		
		
					#rimuvo i file temporeanei
					rm gruppi.txt;
					rm GID.txt;
					rm passwdTemp.txt;
					rm modificaUt.txt;
					rm nuovoUt.txt;
					rm NewPasswdTemp.txt;
					rm riga.txt;
					rm nomi.txt;
					rm UserKey.txt;
					
					echo "";
					echo "Gruppo di appartenenza modificato con successo!";
					echo "";
					
				fi # fine di else
			fi
	
			if test $modifica -eq 3; then #modifica le info dell'utente
		
				echo "inserisci la nuova informazione utente:";	
				read informaz;
		
				cat $1 > passwdTemp.txt; #copia di passwd
				
				cat passwdTemp.txt | cut -d: -f1 > nomi.txt;
				grep -xn "$nome" nomi.txt | cut -d: -f1 > riga.txt; 
				cat passwdTemp.txt | head -$(cat riga.txt) | tail -1 > modificaUt.txt;
		
				#modifico l'utente desiderato con la nuova password
				echo $nome:$(cut -d: -f2-4 modificaUt.txt):$(echo $informaz):$(cut -d: -f6-7 modificaUt.txt) > nuovoUt.txt;
			
				#elimino l'user vecchio prendendo solo la riga interessata
				cat passwdTemp.txt | head -$(cat riga.txt) | tail -1 > UserKey.txt;
			
				grep -w "$nome" UserKey.txt | cut -d: -f1-4 > riga.txt; # salvo i primi 4 campi della riga da eliminare
			
				riga=$(cat riga.txt);
	
				sed /"${riga}"/d passwdTemp.txt > NewPasswdTemp.txt;
	
				cp NewPasswdTemp.txt $1;
		
				cat nuovoUt.txt >> $1;
				#cat $1; 
			
				#rimuovo i file temporanei
				rm passwdTemp.txt;
				rm modificaUt.txt;
				rm nuovoUt.txt;
				rm NewPasswdTemp.txt;
				rm riga.txt;
				rm UserKey.txt;
				rm nomi.txt;
				
				echo "";
				echo "Informazioni aggiornate con successo!";
				echo "";
				
			fi 
	
			if test $modifica -eq 4; then #modifica della path della home
		
				echo "inserisci la nuova path della home:";
				read pathHome;
		
				cat $1 > passwdTemp.txt; #copia di passwd
				
				cat passwdTemp.txt | cut -d: -f1 > nomi.txt;
				grep -xn "$nome" nomi.txt | cut -d: -f1 > riga.txt; 
				cat passwdTemp.txt | head -$(cat riga.txt) | tail -1 > modificaUt.txt;
		
				#modifico l'utente desiderato con la nuova password
				echo $nome:$(cut -d: -f2-5 modificaUt.txt):$(echo $pathHome):$(cut -d: -f7 modificaUt.txt) > nuovoUt.txt;
			
				#elimino l'user vecchio prendendo solo la riga interessata
				cat passwdTemp.txt | head -$(cat riga.txt) | tail -1 > UserKey.txt;
			
				grep -w "$nome" UserKey.txt | cut -d: -f1-4 > riga.txt; # salvo i primi 4 campi della riga da eliminare
			
				riga=$(cat riga.txt);
	
				sed /"${riga}"/d passwdTemp.txt > NewPasswdTemp.txt;
	
				cp NewPasswdTemp.txt $1;
			
				cat nuovoUt.txt >> $1;
				#cat $1; 
		
				#rimuovo i file temporanei
				rm passwdTemp.txt;
				rm modificaUt.txt;
				rm nuovoUt.txt;
				rm NewPasswdTemp.txt;
				rm riga.txt;
				rm UserKey.txt;
				rm nomi.txt;
				
				echo "";
				echo "Percorso della home modificato con successo!";
				echo "";
	
			fi
	
			if test $modifica -eq 5; then #modifica della path della bash
		
				echo "inserisci la nuova path della bash:";
				read pathBash;
		
				cat $1 > passwdTemp.txt; #copia di passwd
				
				cat passwdTemp.txt | cut -d: -f1 > nomi.txt;
				grep -xn "$nome" nomi.txt | cut -d: -f1 > riga.txt; 
				cat passwdTemp.txt | head -$(cat riga.txt) | tail -1 > modificaUt.txt;
		
				#modifico l'utente desiderato con la nuova password
				echo $nome:$(cut -d: -f2-5 modificaUt.txt):$(cut -d: -f6 modificaUt.txt):$(echo $pathBash) > nuovoUt.txt;
			
				#elimino l'user vecchio prendendo solo la riga interessata
				cat passwdTemp.txt | head -$(cat riga.txt) | tail -1 > UserKey.txt;
			
				grep -w "$nome" UserKey.txt | cut -d: -f1-4 > riga.txt; # salvo i primi 4 campi della riga da eliminare
			
				riga=$(cat riga.txt);
	
				sed /"${riga}"/d passwdTemp.txt > NewPasswdTemp.txt;
	
				cp NewPasswdTemp.txt $1;
			
				cat nuovoUt.txt >> $1;
				#cat $1; 
		
				#rimuovo i file temporanei
				rm passwdTemp.txt;
				rm modificaUt.txt;
				rm nuovoUt.txt;
				rm NewPasswdTemp.txt;
				rm riga.txt;
				rm UserKey.txt;
				rm nomi.txt;
				
				echo "";
				echo "Percorso della bash aggiornato con successo";
				echo "";
			fi
		fi # fine di if check=0 (prima si controllava se l'ut esisteva)
	fi

	if test $scelta -eq 6; then
	
		echo "";
		echo "Inserisci il nome dell'utente da eliminare da passwd:";
		read SearchedUser;
	
		check=0;
		
		if [ $(grep -c . $1) -eq 0 ]; then
			echo "";
			echo "ERRORE. Il file passwd è vuoto";
			check=1;
		fi
	
		cat $1 > passwdTemp.txt;
		cat passwdTemp.txt | cut -d: -f1 > nomi.txt; #prendo solo i nomi
	
		if [ $(grep -xc "$SearchedUser" nomi.txt) -eq 0 -a $check -eq 0 ]; then
				echo "";
				echo "ERRORE. Utente non esistente";
				rm passwdTemp.txt;
				rm nomi.txt;
				check=1;
		fi
		
		if [ $check -eq 0 ]; then
		 	# elimino l'utente se è presente..
		
			cat passwdTemp.txt | cut -d: -f1 > nomi.txt;
			grep -xn "$SearchedUser" nomi.txt | cut -d: -f1 > riga.txt; 
			#cat passwdTemp.txt | head -$(cat riga.txt) | tail -1 > modificaUt.txt;
		
			#elimino l'user vecchio prendendo solo la riga interessata
			cat passwdTemp.txt | head -$(cat riga.txt) | tail -1 > UserKey.txt;
		
			grep -w "$SearchedUser" UserKey.txt | cut -d: -f1-4 > riga.txt; # salvo i primi 4 campi della riga da eliminare
																			# (che dovrebbe essere una sola)
			riga=$(cat riga.txt);
	
			sed /"${riga}"/d passwdTemp.txt > NewPasswdTemp.txt;
	
			cp NewPasswdTemp.txt $1;
			
			#cat $1;
	
			#rimuovo i file temporanei
			rm passwdTemp.txt;
			rm NewPasswdTemp.txt;
			rm riga.txt;
			rm UserKey.txt;
			rm nomi.txt;
			#rm modificaUt.txt;
	
		fi
	fi
	
	if test $scelta -gt 7; then
		echo "SCELTA NON VALIDA. Riprova.";
	fi
	
	
done # fine while

if test $scelta -eq 7; then
		echo "TERMINAZIONE IN CORSO";
		exit;
fi

