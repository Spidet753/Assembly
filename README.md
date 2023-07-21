Zadání 
Napište program, který převede zadané číslo uint16 do požadované číselné soustavy zadané 
uživatelem.

Řešení 
Po získání vstupů od uživatele bylo zapotřebí tyto vstupy převést do hexadecimální podoby, aby se 
s nimi mohlo snáze pracovat, poté jsou v registrech uložena dvě čísla, a to uint16 číslo a číslo 
požadované soustavy v hexadecimální soustavě. Dále jsem tyto dvě čísla mezi sebou dělil, a to do té 
doby, dokud nebylo číslo uint16 menší než číslo soustavy. V registru, či registrech jsou nyní uložená 
čísla v dané soustavě, ale ještě je potřeba tyto čísla v registrech upravit; odstranit nuly navíc, které 
přebývají, přetočit čísla do obráceného pořadí, protože abychom získali číslo v požadované soustavě, 
musíme brát zbytky v pořadí opačném, a nakonec tyto čísla ještě řádně uspořádat v registrech tak, 
aby byl výsledek dobře čitelný pro uživatele.

Spuštění programu 
Program je psán v assembleru a je psán pro procesor H8S a je přeložitelný a spustitelný v prostředí 
HEW.

Program 
Program se dělí na dvě části, a to na datový segment a kódový segment.

Datový segment 
V datovém segmentu nadefinujeme jména proměnných s vyhrazeným místem pro ně a to: 
pozadovana_soustava a uint16, do kterých se budou ukládat hodnoty zadané uživatelem. Uživatel 
hodnoty zadává do terminálu po za sebou vyskakujících promptech (prompt1 a prompt2). Dále 
definujeme parametrické bloky a inicializuje zásobník stck s align 1. Poté následuje již kódový 
segment.

Kódový segment 
Zde budu popisovat funkčnost celého kódového segmentu, nejdůležitější podprogramy vždy uvedu 
na samostatný řádek.

Kódový segment začíná _start, program začíná promazáním všech registrů, poté inicializuje zásobník
a pak již následuje načtení prvního vstupu, a to čísla požadované soustavy, toho dosáhneme pomocí 
pomocných služeb GETS, PUTS a syscall. Dále již následují podprogramy.
pocetCifer - zjistí, kolik čísel obsahuje vstup a po skončení pokračuje na navraceni
navraceni – má za úkol vrátit se na adresu prvního bytu vstupu tak, abychom mohli dále pracovat se 
vstupem.

PrevodNaHex – následující podprogram, který má více kroků, prvním krokem je procházení vstupu a 
převádí ascii na decimal tak, abychom ho v následujícím kroku, kterým je Hex, kde díky počtu cifer 
víme zdali je číslo v desítkách, stovkách atd. Zde poté číslo násobíme 10, neboli 0x0A podle počtu 
cifer tak, abychom získali například při třech průchodech hodnotu stovek například z čísla 999, to je 
900, desítek 90… Ty pak v celkových cyklech přičteme k sobě v pricteniHexu. Tím máme 
hexadecimální číslo. Následuje podprogram zadani_uint, ve kterém získáme druhý potřebný vstup a 
proces opakujeme.

Nyní v registru máme 2 hexadecimální čísla a nacházíme se v podprogramu prevodDoSoustavy, ten 
má za úkol daná čísla mezi sebou dělit do té doby, dokud je to možné a výsledná čísla přesouváme do 
registrů ER1 až ER3 podle potřeb, a to podprogramy presun, presun2, presun3, který podle potřeby 
přesunou data z jednoho registru do jiného podle počtu cifer, a podprogramem inverze.

Inverze – při každém průchodu zvyšuje číslo registru o jedničku tak, abychom později věděli, kolik 
čísel později přesouvat. Posouvá data v registru ER3 doleva o 16 bitů a přesouvá do registru ER0, ten 
poté ještě přesouváme doleva o 8 bitů a prvních 16 bitů nulujeme, nakonec ještě odstraníme použitá 
data z ER3. 

prevedPosledniVysledek – číslo nižší něž soustava už se nedělí, tudíž se o něj musíme postarat zvlášť. 
Poté už v ER0 místo na další data nepotřebujeme, proto posouváme o 16 bitů zpátky doprava a 
odstraňujeme nuly pomocí podprogramu kontrolaNul a odstranNulu, abychom v datech neměli 
nepotřebná data navíc. Tyto výsledky ale bohužel nejsou správně, protože jsou otočené, proto 
následuje obracenyPrevodDoRegistru.

obracenyPrevodDoRegistru – obsahuje podprogramy prehod1, _prehod1, prehod2, _prehod2, které 
se starají o správné srovnání v registrech tento program se pak volá do té doby, dokud není čítač 
z inverze na nule, k obrácenému převodu využíváme opět inverze. Poté následuje posledniUprava
přerovnávající data v registrech a využívá kontrolaPoradi, který řeší výjimky v programu. Dále 
využijeme opět kontrolaNul a pak následuje už pouze Preusporadani.

Preusporadani – pro mě jako strůjce kódu by podprogram nebyl potřebný, ale pro uživatele by mohla 
být data v registrech nepřehledně uspořádána a těžko by se četla, jelikož se jedná o číslo uint16 víme, 
že pro uložení dat budou stačit pouze 2 registry. Proto tento podprogram přeuspořádává data tak, 
aby se vešla jen do jednoho, nebo dvou registrů, jestli to bude tak či onak poznáme opět podle 
čítače, kdy můžeme použít jednoduchePreusporadani jeli čítač nižší než 13 a výsledek se poté vejde 
jen na jeden řádek.

V tomhle kroku program skočí na konec a v registrech ER0 – ER2 se nachází výsledek programu.

Proměnné 
pozadovana_soustava FF4000
uint16 FF4083

Obsah registru SP 
pocetCifer 00FF4170
prevodNaHex 00FF4170
zadani_uint 00FF4174
Hex 00FF416C
prevodDoSoustavy 00FF4174
inverze 00FF4170
prevedPosledniVysledek 00FF4174
kontrolaNul 00FF4170
obracenyPrevodDoRegistru 00FF4174
posledniUprava 00FF4174
Preusporadani 00FF4174

Závěr 
Program by měl fungovat pro jakýkoliv vstup čísla z uint16, vyzkoušel jsem mnoho variant vstupů a 
všechny fungovaly, myslím si, že kód je až zbytečně dlouhý a obsahuje až moc podprogramů, tuším, 
že by se dal vymyslet jednodušší algoritmus pro uspořádání dat v registrech který by byl mnohem 
efektivnější, bohužel mě žádný jiný nenapadl.
