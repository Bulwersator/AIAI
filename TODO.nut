TODO: error catherw w BuildTrain
TODO: limit 25 jest z�y: zazwyczaj za wysoki je�li jednak faile nast�puj� z powodu za kr�tkiego czasu skanowania to trzeba zwi�kszy�
TODO: max number of trains in station name also: connected industries, cargo
TODO: check cost before train replacing
TODO: remove empty railway tracks

TODO: passing lanes
TODO: dead ends for busses
TODO: handle bus queues

TODO: long term average for secondaries
TODO: replace helis by helis or nothing
TODO: bridge upgrading
TODO: try to clear road in RAILbuilder
TODO: allow replacing small planes by big on big airports!

TODO: 6x ci�szy poci�g je�li podjazdy s� pojedy�cze????
TODO: better findpair
TODO: better busses (managing & construction)
TODO: world scanner and rework main with dynamic strategy
TODO: rework statues
TODO: rebridger over valleys, debridger

TODO: AIAI.GetLastError()
TODO: tourist support
TODO: terminus RV station
TODO: better RV depot placing (replace double flat by test mode)
TODO: more working depots
TODO: check jams before RV building
TODO: reuse existing roads constructed by another players
TODO: For all newly build routes, check both ways. This way, if one-way roads are build, another road is build next to it so vehicles can go back. //from admiralai
TODO: long bridges sometimes are unavailable!
TODO: helicopters
TODO: dodawanie samolot�w zale�ne od pojemno�ci
TODO: air
//lepsze wybieranie przy a8
//industry - valuate before building
//nie pierwsze lepsze tylko najlepsze, nie masowac budowy (wiek reszty) DONE?
//kasowanie nadmiaru
//sprzedawa� samoloty z minusem w obu latach (je�li starsze ni� 2 lata) DONE?

TODO: bus scanner
	- construction of 2 bus stops
	- 1 bus
	- go on route WITHOUT pathfinding
	- vehicle is lost
		- route construction is needed
	- vehicle is profitable - we parasited succesfully
	limitation: real players rarely construct intercity routes

ideas 
function Banker::GetInflationRate() //from simpleai
{
	return (100 * AICompany.GetMaxLoanAmount() / AIGameSettings.GetValue("difficulty.max_loan"));
}