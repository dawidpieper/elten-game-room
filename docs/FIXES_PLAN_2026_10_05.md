# Plan poprawek Power Games — 5 października 2026

Status: osiem punktów wdrożonych w źródłach i sprawdzonych lokalnie oraz
w działających kopiach ELTEN-a. Przebudowano i podpisano wersję 2.0.4.4,
build 243, zgodnie z późniejszym poleceniem użytkownika. Granice prób
opisano na końcu dokumentu; nie jest to deklaracja wyczerpania wszystkich
możliwych scenariuszy.

Osiem punktów zebrano na polecenie użytkownika.
Po przedstawieniu obecnych opisów użytkownik doprecyzował
punkt 3: liczba setów w Audio Ballu oraz punkty w Państwach-miastach,
Pikach i UNO, w krótkiej formie bez dodatkowych zdań. Punkt 6 przenosi
ten sam krótki opis wariantu również na listy stołów. Punkt 7 dodaje
lokalny przełącznik komunikatów o literach w Scrabble. Punkt 8 dodaje
wyciszanie samych dźwięków gier poza oknem stołu, niezależne od mowy
i osobnego sygnału własnej tury.

To osobny dokument. Zakończonego planu `NEXT_FIXES_PLAN.md` nie zmieniamy
i nie otwieramy ponownie jego wykonanych punktów.

## 1. Wyszukiwanie w rankingach Krowy obejmuje Dzienne Krowy

Wyszukiwarka wewnątrz rankingów ma znajdować także słowa z Dziennej Krowy,
a nie tylko słowa z pozostałych rankingów.

Obecnie `KrowaLeaderboardClient#search_words` korzysta z `ranked_words`,
które pobiera zwykły ranking. Dołączyć wyszukiwanie w danych rankingu
dziennego i umożliwić otwarcie właściwych wyników dla znalezionego dnia.
Zachować dotychczasowe wyszukiwanie pozostałych wariantów.

Nie ujawniać dzisiejszego rozwiązania przed terminem jego udostępnienia.
Nie wyliczać dawnych słów ponownie z bieżącego słownika ani nie zgadywać
rozwiązania, którego nie ma w wiarygodnym zapisie.

Miejsca pracy: `games/krowa_support/leaderboards.rb` oraz
`games/krowa_support/server_store.rb` i ich testy.

Nie łączyć tego punktu ze zmianą liczenia prób Wieży słów. W ukończonych
próbach na żywych kontach liczby zaakceptowanych zgadnięć zgadzały się
ze stanem partii, zapisem na serwerze i prezentacją wyniku. Sama mała
liczba prób przy długim słowie nie dowodzi błędu licznika.

## 2. Znane języki domyślnie odznaczone i poprawny priorytet polskiego

Przy braku własnego ustawienia lista „Znane języki” ma być pusta:
żaden język nie jest zaznaczony domyślnie. Nie przejmować automatycznie
zaznaczeń z listy języków konta ELTEN-a.

Język interfejsu pozostaje osobnym wyborem. Nadal służy do tłumaczenia
programu, ale nie wymusza zaznaczenia siebie w liście znanych języków.
Pusta lista dodatkowych języków nie może zepsuć języka głównego ani
dotychczasowego angielskiego tekstu zastępczego przy braku tłumaczenia.

Zakres dotyczy wartości domyślnej, nie kasowania świadomie zapisanych
wyborów użytkowników. Masowy reset istniejących ustawień nie został zlecony.

Miejsca pracy: `lib/game_room_localization.rb`,
`lib/game_room_screens.rb` oraz testy ustawień i tłumaczeń.

### Potwierdzony błąd etykiety w Cat, head, tail

Użytkownik zgłosił czeskie „Bodový limit” zamiast „Limit punktów” po
zaznaczeniu czeskiego jako znanego języka, przy głównym języku polskim.
Odtworzono to lokalnie na rzeczywistych katalogach i metodzie budującej
opcje gry: bez czeskiego etykieta jest polska, po dodaniu czeskiego — czeska.
Wspólne polskie tłumaczenie „Score limit” istnieje w obu przypadkach.

Przyczyną jest osobna metoda tłumaczenia w `games/cat_head_tail.rb`.
Najpierw szuka wpisu w kontekście `cat_head_tail` we wszystkich dostępnych
językach, a dopiero po niepowodzeniu sięga po wpis wspólny. Kontekstowy
wpis PL jest pusty, CS zawiera tłumaczenie. Znalezienie czeskiego wpisu
przerywa szukanie przed sprawdzeniem wspólnego polskiego „Limit punktów”.
To błąd kolejności wyszukiwania, nie brak polskiego tłumaczenia i nie
zmiana wybranego języka interfejsu. Samo odznaczenie domyślnych języków
nie usunie przyczyny po ich późniejszym ręcznym zaznaczeniu.

Planowana kolejność: specjalny wpis gry w języku głównym, potem wspólny
wpis w tym samym języku, dopiero potem odpowiedniki w dodatkowych znanych
językach. Zachować pierwszeństwo istniejących autorskich tłumaczeń gry
w obrębie danego języka; nie zastępować ich tłumaczeniami innych gier.
Pozostawić działający wybór języka zastępczego, gdy obu wpisów głównych brak.

Testy mają objąć ten przypadek, istniejący polski wpis autorski,
rzeczywisty brak polskiego tłumaczenia oraz czeski wybrany jako język główny.
Dowód reprodukcji: lokalny pomocnik
`tmp/cat_head_tail_language_probe_20261005.rb`. Poprawka produkcyjna
jest częścią zatwierdzonego wdrożenia.

## 3. Krótkie opisy wariantów w powiadomieniach

Poprawa obejmuje zarówno powiadomienia o nowym stole, jak i zaproszenia.
Oba korzystają ze wspólnego opisu wariantu. Zachować istniejące informacje
i dopisać na końcu tylko ustaloną liczbę z jednostką, po przecinku.
Zakres na tym etapie obejmuje cztery gry:

| Gra | Dodawana informacja | Przykład docelowego dopisku wariantu |
| --- | --- | --- |
| Audio Ball | Liczba setów potrzebnych do wygranej (`sets_to_win`). | „Normalny, do 3 wygranych setów” |
| Państwa-miasta | Docelowa liczba punktów (`target_score`). | „Polski, 100 punktów” |
| Piki (Spades) | Limit punktów (`score_limit`). | „Quicksand, 300 punktów” |
| UNO | Limit punktów eliminacji (`score_limit`). | „Klasyczna talia UNO, z przechwytywaniem, 500 punktów” |

Liczby w przykładach zastępuje rzeczywiste ustawienie stołu. W Audio Ballu
nie przedstawiać liczby wygranych setów jako łącznej liczby setów meczu:
wariant do trzech wygranych może trwać dłużej niż trzy sety. Stosować krótkie
formy „do 1 wygranego seta”, „do 2 wygranych setów”, „do 3 wygranych setów”.
Przy punktach wystarczy „100 punktów”, bez „Limit punktów wynosi” ani
innych zdań. Zachować poprawną odmianę jednostek i tłumaczenia.

Nie dodawać informacji o drużynach do Pików ani nie rozszerzać opisów
pozostałych gier w ramach tego ustalenia. Poniższe zestawienie pozostaje
opisem zachowania sprzed wdrożenia, a nie nową specyfikacją po zmianie.

Nie dopisywać samodzielnie wszystkich ustawień stołu. Opis ma pozostać
krótki. Nie zmieniać przy okazji pełnego odczytu ustawień pod Ctrl+R.
Brak danych w otrzymanym powiadomieniu nie może być zastępowany zgadywanymi
ustawieniami domyślnymi.

Miejsca pracy: `lib/table_variant.rb`, metody `notification_option_keys`
i `notification_variant` gier oraz wspólna prezentacja w `__app.rb`.

### Stan obecny, sprawdzony w źródłach i lokalnym formatterze PL

Poniżej opisano tylko dopisek wariantu. Nazwa gry i nadawca są osobnymi
częściami powiadomienia. Nowy stół ma typ „Nowy stół”; zaproszenie ma
tytuł „Zaproszenie do gry” i treść z nadawcą, nazwą stołu oraz grą
wraz z dopiskiem. Nie są to propozycje nowych opisów.

| Gra | Co obecnie dodaje |
| --- | --- |
| 3-5-8 | „z wymianą kart” albo „bez wymiany kart”. |
| 99 | „Żetony na początek: …”, np. 9. |
| Audio Ball | Poziom: Bardzo łatwy, Łatwy, Normalny, Trudny albo Bardzo trudny. |
| Axel Pong | Singiel/Debel, Classic/Arcade, poziom trudności; np. „Singiel, Classic, Normalny”. |
| Cat, head, tail | „Limit punktów: …”, np. 100. |
| Domino | Zestaw kostek i gra indywidualna/drużynowa; np. „Podwójna szóstka, Gra indywidualna”. Dla wielokrotnych zestawów także „2 ×” lub „4 ×”. Bez liczby kostek i limitu graczy. |
| Farkle | „Limit punktów: …”, np. 1000. |
| Krowa | Dzienna Krowa, Losowe słowo, Wyścig albo Wieża słów. W Losowym słowie i Wyścigu także „losowa długość słowa” lub „… liter”. |
| Makao | Proste makao, Rozszerzone polskie makao, Makao z jokerami albo Własne zasady. Bez wyliczania poszczególnych reguł. |
| Mankala | Oware, Ayoayo albo Kalah. |
| Monopoly | Nazwa planszy, np. „Plansza polska” albo „Plansza amerykańska / Atlantic City”. |
| Państwa-miasta | Język odpowiedzi: Polski albo Angielski. |
| Piki (Spades) | Standardowy lub włączone warianty: Bez piekła, Quicksand, Samobójstwo. Jeśli włączono więcej niż jeden, wymienia je po przecinku. Bez informacji o drużynach. |
| Poker | Texas Hold'em albo Poker dobierany. |
| Quiz | Język i nazwa zestawu, np. „Polski, Wiedza ogólna” lub „Polski, Wiedźmin”. Bez liczby pytań i kategorii. |
| Remik | Zwykła punktacja/Tryb eliminacyjny oraz z manipulowaniem układami/bez manipulowania układami. |
| Scrabble | Język: Polski albo Angielski. |
| Taboo | Język i nazwa zestawu, obecnie np. „Polski, General”. „General” jest rzeczywistą obecną nazwą w tym dopisku. |
| Tysiąc | Trzy osoby; Dwie osoby i „Musiki: 2 karty” lub „Musiki: 3 karty”; Cztery osoby, jedna pauzuje w każdym rozdaniu; Dwie drużyny po dwie osoby. |
| UNO | Klasyczna talia UNO/Talia UNO No Mercy/Talia UNO Flip oraz z przechwytywaniem/bez przechwytywania. Zwykłe i superprzechwytywanie mają wspólny dopisek „z przechwytywaniem”; strity i buzzer nie są wymieniane. |
| Warcaby | Rozmiar planszy i liczba pól: „8 na 8 (64 pola)”, „10 na 10 (100 pola)” lub „12 na 12 (144 pola)”. To obecne brzmienie, łącznie z odmianą słowa „pola”. |

Bez dodatkowego opisu wariantu: Biblios, Chińczyk, Cztery w rzędzie,
Kółko i krzyżyk, Mexican Train, Reversi, Statki, Szachy, Wojna,
Wojna naukowa i Yahtzee. Powiadomienia nadal zawierają nazwę gry
i podstawowe informacje; pusty dopisek nie oznacza pustego powiadomienia.

## 4. Audio Ball — naprzemienne rozpoczynanie kolejnych setów

Po zakończeniu setu następny ma zaczynać drugi gracz: A, B, A, B itd.,
względem osoby wylosowanej na początek pierwszego setu. Nie uzależniać
tego od zwycięzcy ani parzystości liczby rozegranych punktów.

Obecny wybór serwującego wynika z pierwszego serwującego i licznika
wszystkich wymian (`first_server` oraz `rally / 2`), bez osobnego
uwzględnienia początku nowego setu. Oddzielić naprzemienność setów
od dotychczasowej zmiany serwującego w obrębie setu. Sprawdzić również
klienta realtime, zapowiedzi i wznowienie, aby zgadzały się z odtworzonym
stanem partii. Nie zmieniać zasad punktacji ani długości przerw.

Miejsca pracy: `games/audio_ball.rb` i korzystające ze stanu serwu
fragmenty `lib/audio_ball/`.

## 5. Nieprzetłumaczalna nazwa Cat, head, tail

Tytuł gry ma zawsze brzmieć „Cat, head, tail”, bez tłumaczenia na
którykolwiek język interfejsu. Dotyczy list gier, stołów, powiadomień,
zasad i pozostałych miejsc prezentujących nazwę gry.

Nie zmieniać identyfikatora gry, jej zasad ani tłumaczeń zwykłych
komunikatów. Wyłączyć tłumaczenie samego tytułu i uporządkować jego
wpisy w katalogach, aby kolejne tłumaczenie nie przywróciło problemu.

Miejsca pracy: `games/cat_head_tail.rb`, miejsca podające tytuł
oraz katalogi `locale/`.

## 6. Krótki opis wariantu na listach stołów

Na liście stołów w widgecie oraz w „Dołącz do stołu” przy wybranej grze
wyświetlać ten sam krótki opis wariantu, który ustalono dla powiadomień
w punkcie 3. Dotyczy wszystkich gier mających taki opis, w tym nowych
dopisków o setach Audio Balla oraz punktach Państw-miast, Pików i UNO.

Zachować obecne informacje w wierszu stołu i uzupełnić je opisem wariantu,
bez powtarzania nazwy gry, pełnych zdań ani wszystkich ustawień. Gry bez
krótkiego opisu nie dostają pustego dopisku ani zbędnego separatora.

Wykorzystać wspólne tworzenie opisu dla list i powiadomień, nie osobne
listy ustawień lub tłumaczeń. Opis ma wynikać z dostępnych danych stołu;
nie dodawać osobnego żądania sieciowego dla każdego wiersza ani przy
naciskaniu strzałek. Przy braku danych nie zgadywać wariantu.

Pełne ustawienia pod Ctrl+R i dokładna obsada pod Ctrl+W pozostają bez
zmian. Po odświeżeniu listy opis ma uwzględniać aktualne ustawienia stołu,
z zachowaniem zaznaczenia i dotychczasowych zasad odświeżania.

## 7. Lokalne komunikaty o kładzeniu i zabieraniu liter w Scrabble

Dodać opcjonalne komunikaty o zmianach widocznych w publicznym podglądzie
układanego ruchu, jeszcze przed zatwierdzeniem słowa. Przykłady:
„peterman kładzie G na G7” oraz „peterman zabiera G z G7”.

Domyślnie komunikaty są wyłączone. Ctrl+P w Scrabble bezpośrednio przełącza
je między włączonymi a wyłączonymi i krótko potwierdza nowy stan.
Nie otwiera okna ustawień ani dodatkowego wyboru. Nie tworzyć osobnego
interfejsu ustawień Scrabble dla tej jednej opcji. Skrót opisać w pomocy gry.

Wybór jest lokalny i zapamiętywany w lokalnych preferencjach: każdy
uczestnik lub obserwator decyduje tylko o swoim odczycie. Nie jest to
ustawienie stołu, nie zmienia preferencji innych osób ani samego podglądu
planszy. Korzystać z istniejących aktualizacji szkicu; nie dodawać nowych
żądań sieciowych ani ujawniania niepołożonych liter ze stojaka.

Odczytywać rzeczywiste położenie i zabranie litery, bez powtarzania tego
samego komunikatu przy odświeżeniu, ponownym odebraniu aktualizacji lub
powrocie do okna. Włączenie opcji nie odczytuje wstecz całego szkicu.
Zatwierdzenie słowa nie może być przedstawiane jako zabranie wszystkich
liter tylko dlatego, że szkic został przeniesiony na zatwierdzoną planszę.
Zachować dotychczasowe potwierdzenia własnych czynności bez podwójnego
odczytu tego samego działania.

## 8. Wyciszanie dźwięków gier poza oknem stołu

W kategorii „Ogólne”, obok ustawień mowy i sygnału własnej tury, dodać
lokalną, zapamiętywaną listę „Wyciszaj dźwięki gier po przejściu do innego
okna”, zamiast pola wyboru. Trzy pozycje:

- „Wszystkich gier”.
- „Tylko gier audio”.
- „Nie wyciszaj” — wartość domyślna.

„Tylko gier audio” obejmuje Axel Ponga i Audio Balla. W tym trybie
dźwięki pozostałych gier, w tym muzyka Krowy, nie są wyciszane przez
to ustawienie. „Wszystkich gier” obejmuje również te pozostałe gry.
„Nie wyciszaj” zachowuje dotychczasowy odsłuch.

Korzystać z tych samych zasad rozpoznawania tła co przy mowie: inna część ELTEN-a,
np. Wiadomości lub Konferencje, albo przejście do innego programu.
Nie wprowadzać drugiego, rozbieżnego sposobu rozpoznawania aktywnego okna.

Zgodnie z doprecyzowaniem użytkownika wyciszenie obejmuje tylko dźwięki
samych gier: efekty rozgrywki, piłkę i paletki, muzykę gry oraz nagrane
zapowiedzi, np. wyników Ponga. Nie wycisza dźwięków czatu, wejścia i wyjścia
uczestników, zaproszeń ani powiadomień o nowych stołach. Nie zmienia
dźwięków pozostałych części ELTEN-a ani rozmowy w konferencji.
„Ding” własnej tury pozostaje sterowany osobnym, istniejącym ustawieniem,
także gdy nowe wyciszanie dźwięków gier jest włączone.

Ustawienie działa niezależnie od mowy. Nie nadpisuje zapisanych głośności
ani lokalnych ustawień audio poszczególnych gier. Ma obejmować także
dźwięki już odtwarzane w chwili przejścia do innego okna, w tym zapętloną
piłkę i muzykę, a nie tylko blokować uruchamianie następnych nagrań.
Po powrocie przywrócić odsłuch aktualnego stanu, bez odtwarzania zaległych
efektów i zapowiedzi. Nie zatrzymywać partii, synchronizacji, aktualizacji
historii ani nie zmieniać ustalonych przerw rozgrywki z powodu wyciszenia.

Miejsca pracy: `lib/game_room_screens.rb`, `lib/game_room_preferences.rb`,
`lib/game_background_policy.rb`, wspólne odtwarzanie w `lib/game_sounds.rb`
oraz odrębne odtwarzacze Ponga, Audio Balla i muzyki Krowy. Rozróżnić
dźwięki gry od dźwięków stołu; nie wyciszać całej aplikacji jednym
globalnym ustawieniem głośności.

### Obecne działanie przełącznika mowy

Sprawdzona etykieta brzmi „Odczytuj komunikaty stołu poza jego oknem”.
Odznaczenie blokuje automatyczną syntezę nowych zdarzeń rozgrywki,
zmiany tury, wyniku, przypomnień i nowych cudzych wiadomości czatu stołu.
Obejmuje też automatyczne komunikaty klienta Ponga i Audio Balla oraz
rozpoczęcie partii odbierane w tle. Partia i historia nadal się aktualizują.

Nie jest to globalne wyłączenie syntezatora ELTEN-a ani odczytu ręcznie
wywoływanego skrótem. Nie steruje globalnymi powiadomieniami o zaproszeniach
i nowych stołach. Nie wycisza efektów, muzyki, „ding” ani nagranych głosów
lektora: nagranie wyniku jest dźwiękiem, nawet gdy jego odpowiednik
wypowiadany syntezą podlega ustawieniu mowy. Przełącznik blokuje nowe
automatyczne odczyty; sam nie ucina wypowiedzi rozpoczętej przed zmianą
okna. Własne okno pomocy gry nie jest traktowane jak wyjście do innej
części ELTEN-a, o ile ELTEN pozostaje na pierwszym planie.

## Obowiązkowe sprawdzenie wdrożenia

Każdy z ośmiu punktów musi przejść zarówno celowane testy lokalne,
jak i testy w działającym ELTEN-ie na rzeczywistych kontach. Sam test
lokalny nie kończy żadnego punktu. Liczbę kont dobrać do scenariusza:
jedno dla ustawień i wyszukiwania, co najmniej dwa dla dostawy zmian,
czatu, powiadomień i partii, dodatkowe konto dla obserwatora tam, gdzie
ma to znaczenie. Sprawdzić także zachowanie istniejących funkcji
dotkniętych zmianą, nie tylko obecność nowej opcji. Zapisać wyniki,
nieudane próby i granice testu w lokalnym raporcie. Scenariusz zablokowany
lub pominięty pozostaje niepotwierdzony, nie jest zaliczony.

Wykonać testy lokalne dotkniętych miejsc, a następnie próby na żywych
kontach odpowiednie do zmian: wyszukiwanie starej Dziennej Krowy i ochrona
dzisiejszego rozwiązania; ustawienia bez zapisanej listy oraz z własnymi
wyborami języków oraz polskim interfejsem z dodatkowym czeskim;
oba rodzaje powiadomień według uzgodnionego zakresu;
kilka kolejnych setów Audio Balla z różnymi wynikami i oboma pierwszymi
serwującymi; stały tytuł gry w obsługiwanych językach. Dla punktu 6
porównać opis tego samego stołu w powiadomieniu, w widgecie i w „Dołącz
do stołu”, także po zmianie ustawień i odświeżeniu. Sprawdzić gry bez
dopisku oraz brak dodatkowych żądań podczas poruszania się po listach.

Dla punktu 7 sprawdzić co najmniej dwa żywe konta: domyślne wyłączenie,
bezpośrednie przełączanie Ctrl+P bez dialogu, niezależne preferencje oraz
odczyt kładzenia i zabierania liter przed zatwierdzeniem. Uwzględnić
obserwatora, ponowne wejście, powtórzoną aktualizację, anulowanie szkicu
i zatwierdzenie słowa; odświeżenie nie może generować fałszywych czynności.

Dla punktu 8 sprawdzić lokalnie i na żywych partiach grę turową, Ponga,
Audio Balla oraz muzykę Krowy, we wszystkich trzech trybach listy.
Potwierdzić domyślne „Nie wyciszaj” oraz zapamiętywanie wybranej pozycji.
W trybie „Tylko gier audio” sprawdzić także brak wyciszania pozostałych gier.
Przejść do Wiadomości, Konferencji i poza
okno ELTEN-a, a potem wrócić, także w trakcie odtwarzania ciągłego dźwięku.
Sprawdzić niezależne kombinacje ustawień mowy, dźwięków gier i „ding”,
zachowanie ustawionych głośności oraz brak zaległych zapowiedzi po powrocie.
Potwierdzić dalszą grę i aktualizacje w tle oraz niezmienione dźwięki
czatu, wejścia i wyjścia, zaproszeń i powiadomień o stołach. Uwzględnić
obserwatora i własne okno pomocy, bez tworzenia wyjątków dla konkretnej gry.

Nie publikować próbnych wyników do publicznych rankingów. Późniejsze
polecenie użytkownika objęło przebudowę tej samej paczki i changelog.
Nie zlecono publikacji na GitHubie ani zmiany schematów lub ochrony serwera.

## Wynik wdrożenia

Ostatnie wyniki 38 różnych celowanych skryptów źródeł są poprawne.
To kilka przebiegów dotkniętych miejsc, nie pełny runner całego projektu.
Osobno sprawdzono podpis oraz zgodność wszystkich 492 plików instalatora
ze źródłami, ładowanie binarne, Krowę, formularze opcji i zasady z paczki.
Starszy test binarny Krowy początkowo oczekiwał dawnej liczby słów;
zaktualizowano jego oczekiwania i sprawdzanie dopisanych haseł, po czym
ponowienie przeszło. Bajty gotowej paczki nie wymagały przez to zmiany.

W żywych próbach użyto kont papierek, papiertestowy, papiertestowy1
i papiertestowy2 na jednym komputerze. Scrabble sprawdzono z dwoma
graczami i obserwatorem: przełącznik, odczyt położeń i usunięć, wyłączenie
oraz zatwierdzenie słowa bez fałszywego komunikatu o zabraniu liter.
Audio Ball rozegrał pełne trzy sety, rozpoczynane kolejno przez A, B i A;
oba konta zachowały zgodny wynik 2:1. Pong przeszedł dwie osobne próby
wymian i punktów. Muzykę Krowy oraz piłkę obu gier audio sprawdzono
na rzeczywistych strumieniach dźwięku we wszystkich trzech trybach listy.
Wyciszone nagrania ciągłe pozostają uruchomione i przywracają bieżący dźwięk.
Czat i sygnał tury zachowują własne ustawienia.

W głównej kopii wpisanie „jeż” w normalną wyszukiwarkę rankingu znalazło
Dzienną Krowę z 1 października 2026 i otworzyło właściwy ranking.
Nie dodawano ani nie zmieniano opublikowanych wyników. Ustawienia języków,
trzy pozycje wyciszania i etykiety Cat, head, tail sprawdzono w działającym
ELTEN-ie. Formatter obu typów powiadomień otrzymał natywne obiekty
powiadomień; opis listy i widgetu pochodził także z rzeczywistego stołu.
Nie wysyłano serii ośmiu powiadomień przez serwer wyłącznie do próby tekstu.

Granice: sterowanie prób odbywało się przez natywne handlery kontrolek
i MCP, nie fizyczną klawiaturą ani odsłuchem człowieka. Na żywo użyto
Wiadomości oraz nieaktywnego okna ELTEN-a. Konferencje, własna pomoc,
drugi wylosowany pierwszy serwujący i wszystkie kombinacje ustawień
zostały objęte testami lokalnymi odpowiednich reguł, nie osobnymi pełnymi
próbami na serwerze. Nie jest to test różnych komputerów i łączy.

Dodano również 34 słowa podane przez użytkownika. Słownik zawiera
98 221 wpisów; wcześniejszy tekst i kolejność pozostały bez zmian.
Definicje nadal są pobierane z SJP na żądanie, z dotychczasową informacją
o braku definicji, jeśli słownik internetowy jej nie zwróci.

Zamknięto własne prywatne stoły i przywrócono zmienione na próbę
preferencje. We wszystkich czterech kopiach pozostawiono bieżące źródła
w pamięci po zwykłym przeładowaniu programu, bez pomocników testowych.
Nie zmieniano zainstalowanych plików, ochrony tabel ani publicznych rankingów.
Prywatne dowody: `diagnostics/fixes-243-20261005` w nadrzędnym workspace.
