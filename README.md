## TO DO

* Konfiguracja projektu
* Zasada działania/Tryby pracy
	* automatyczny
    * manualny
    * STOP awaryjny
* Opis osi
	* oś X - ruch taśmy transportującej
	* oś Y - pozycja frezu
	* oś Z - wysokość frezu
	* ruch obrotowy frezu - zadawanie stałej prędkości
* Wymagania techniczne
	* obliczenie dlugości przedmiotu (ze wskazań czujnika)
	* ograniczenia przy trybie aut.:
    	* odległość od dolnej krawędzi przedmiotu >=20mm
		* głębokość 1mm
		* ruch frezu nad przedmiotem (odstęp) >=10mm
	* położenie początkowe
		- najwyższe położenie w osi Z (300mm)
		- skrajnie dolne na osi Y
	* bazowanie po włączeniu zasilania, pozycja osi dowolna.
	* czujnik znajduje się w miejscu przecięcia osi X i Y, wskazanie czujnika to przełącznik podłączony do wejścia cyfrowego
* Program
	* obróbka sygnalizowana jest poprzez wyjście cyfrowe (lampka)
	* obrót frezu sygnalizowany jest poprzez wyjście cyfrowe (lampka)
- Zadania
	* litera I
	- litera i
	- litera W
	- litera U
	- litera X
	* litera R
* Uwagi
	* osie to system CNC XYZ
	* po każdej realizacji programu frez wraca do pozycji początkowej
	* każda litera to osobny program g-code
	* litery grawerowane sa na środku przedmiotu
	* oś Y to góra/dół, X lewo/prawo
	* jeśli element jest za krótki - odrzucamy , wyświetlamy alarm
* Wizualizacja
	* ekran - 16:10
	* jednosti przy liczbach
	* Przycisk Switch On/Switch Off do włączania i wyłączania napędów
	* Przyciski Start i Stop do włączania i wyłączania programu w trybie automatycznym
	* stop awaryjny
	* info o trybie pracy
	* info o trybie maszyny
	* wybór trybu
	 	- aut., możliwość wyboru programu z listy, po wyborze wymagane jest potwierdzenie zmian w wyskakującym okienku, ma być także widoczny aktualny program
		- manual., możliość zadania pozycji i predk, przyciski do jogowania.Możliwe jest poruszanie tylko jedna osią jendocześnie.
	* wykresy prędk i pozycji
	* pojawienie się migajżcego znaku ostrzegawczego gdy wystapi alarm
	* alarmy
	* stany osi
	* stan całej maszyny
		
## DONE
