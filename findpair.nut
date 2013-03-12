class Route
{
start=null;
end=null;
zakazane=null;
start_otoczka=null;
koniec_otoczka=null;
depot_tile = null;
start_station = null;
end_station = null;
start_tile = null;
end_tile = null;
cargo = null;
production = null;
type = null;
station_size = null;
station_direction = null;
first_station = null;
second_station = null;

//track_type; //TODO: do it!

//trasa.type
//0 proceed trasa.cargo
//1 raw
//2 passenger
engine = null;
engine_count = null;
budget = null;
demand = null;
OK = null;

	constructor()
	{
first_station = Station();
second_station = Station();
start=null;
end=null;
zakazane = AIList();
start_otoczka=null; //obsolete TODO //move to Station()
koniec_otoczka=null; //obsolete TODO //move to Station()
depot_tile = null;
end_station = null;  //obsolete TODO //move to Station()
start_tile = null;
end_tile = null;
cargo = null;
production = null;
type = null;
station_size = null; //obsolete TODO //move to Station()
engine = null;
engine_count = null;
budget = null;
	}

	function StationsAllocated()
	{
return first_station.location != null && second_station.location != null
}

	function Print()
	{
	Info(" start " + AIIndustry.GetName(start));
	Info(" end " + AIIndustry.GetName(end));
	Info(" depot_tile " + depot_tile);
	Info(" end_station " + end_station);

	Info(" first_station.location " + first_station.location);
	Info(" first_station.direction " + first_station.direction);
	Info(" second_station.location " + second_station.location);
	Info(" second_station.direction " + second_station.direction);

	Info(" end_tile " + end_tile);
	Info(" cargo " + AICargo.GetCargoLabel(cargo));
	Info(" production " + production);
	Info(" type " + type);
	Info(" station_size " + station_size);
	Info(" engine " + engine);
	//Info(" engine " + AIEngine.GetName(engine));
	Info(" engine_count " + engine_count);
	Info(" budget " + budget);
	Info(" demand " + demand);
	Info("");
	}
}


function DefaultIsConsumerOK(ID)
{
if(AIIndustry.IsValidIndustry(ID)==false) //industry closed during preprocessing
   {
   return false;
   }
return true;
}

function DefaultIsProducerOK(ID)
{
local cargo_list = AIIndustryType.GetProducedCargo(AIIndustry.GetIndustryType(ID));
if(cargo_list==null) return false;
if(cargo_list.Count()==0) return false;
if(AIIndustry.IsValidIndustry(ID)==false) //industry closed during preprocessing
   {
   return false;
   }
return true;
}

function FindPairWrapped
(traska,
GetIndustryList, IsProducerOK, IsConnectedIndustry, ValuateProducer, IsConsumerOK, ValuateConsumer, 
distanceBetweenIndustriesValuator, DualIndustryStationAllocator, GetNiceTownForMe, CityStationAllocator, FindEngine)
{
if(IsProducerOK == null) IsProducerOK = DefaultIsProducerOK;
if(IsConsumerOK == null) IsConsumerOK = DefaultIsConsumerOK;
return FindPairDeepWrapped
(traska,
GetIndustryList, IsProducerOK, IsConnectedIndustry, ValuateProducer, IsConsumerOK, ValuateConsumer, 
distanceBetweenIndustriesValuator, DualIndustryStationAllocator, GetNiceTownForMe, CityStationAllocator, FindEngine);
}

function FindPairDeepWrapped
(traska,
GetIndustryList, IsProducerOK, IsConnectedIndustry, ValuateProducer, IsConsumerOK, ValuateConsumer, 
distanceBetweenIndustriesValuator, DualIndustryStationAllocator, GetNiceTownForMe, ToCityStationAllocator, FindEngine)
{
local industry_list = GetIndustryList();
local choise = Route();
Error(industry_list.Count()+"");
local best=0;
local new;

for (traska.start = industry_list.Begin(); !industry_list.IsEnd(); traska.start = industry_list.Next()) //from Chopper
   {
   if(IsProducerOK(traska.start)==false)continue;
   if(traska.zakazane.HasItem(traska.start))continue;
   local cargo_list = AIIndustryType.GetProducedCargo(AIIndustry.GetIndustryType(traska.start));
   for (traska.cargo = cargo_list.Begin(); !cargo_list.IsEnd(); traska.cargo = cargo_list.Next())
   {
   traska.production = AIIndustry.GetLastMonthProduction(traska.start, traska.cargo)*(100-AIIndustry.GetLastMonthTransportedPercentage (traska.start, traska.cargo))/100;

   if(IsConnectedIndustry(traska.start, traska.cargo))continue;
   
   local industry_list_accepting_current_cargo = rodzic.GetIndustryList_CargoAccepting(traska.cargo);
   local base = ValuateProducer(traska.start, traska.cargo);
   if(industry_list_accepting_current_cargo.Count()>0)
   {
   for(traska.end = industry_list_accepting_current_cargo.Begin(); !industry_list_accepting_current_cargo.IsEnd(); traska.end = industry_list_accepting_current_cargo.Next())
        {
		if(traska.zakazane.HasItem(traska.end))continue;
		if(!IsConsumerOK(traska.end))continue; 
		
	    new = ValuateConsumer(traska.end, traska.cargo, base)	
		local distance = AITile.GetDistanceManhattanToTile(AIIndustry.GetLocation(traska.end), AIIndustry.GetLocation(traska.start)); 
		new*= distanceBetweenIndustriesValuator(distance); 
		if(AITile.GetCargoAcceptance (AIIndustry.GetLocation(traska.end), traska.cargo, 1, 1, 4)==0)
              {
			  if(rodzic.GetSetting("other_debug_signs"))AISign.BuildSign(AIIndustry.GetLocation(traska.end), AICargo.GetCargoLabel(traska.cargo) + "refused here");
			  new=0;
			  }
		//Info(new + " (" + best + ")");	  
		if(new>best)
			{
			traska = DualIndustryStationAllocator(traska);
			if(traska.StationsAllocated())
			{
				traska = FindEngine(traska);
				if(traska.engine != null)
				   {
				best = new;
				traska.start_tile = AIIndustry.GetLocation(traska.start);
				traska.end_tile = AIIndustry.GetLocation(traska.end);
				//choise = traska;
				
				choise.start = traska.start;
				choise.end = traska.end;
				choise.zakazane = traska.zakazane;
				choise.start_otoczka = traska.start_otoczka;
				choise.koniec_otoczka = traska.koniec_otoczka;
				choise.depot_tile = traska.depot_tile;
				choise.end_station = traska.end_station;
				choise.start_tile = traska.start_tile;
				choise.end_tile = traska.end_tile;
				choise.cargo = traska.cargo;
				choise.production = traska.production;
				choise.type = traska.type;
				choise.station_size = traska.station_size;
				choise.engine = traska.engine;
				choise.engine_count = traska.engine_count;
				choise.budget = traska.budget;
				choise.demand = traska.demand;
				choise.first_station.direction = traska.first_station.direction;
				choise.second_station.direction = traska.second_station.direction;
				choise.first_station.location = traska.first_station.location;
				choise.second_station.location = traska.second_station.location;
					}
				}
			}
		}
	}

	else 
	   {
	   traska.end = GetNiceTownForMe(AIIndustry.GetLocation(traska.start)); 
	   if(traska.end == null)continue;
	   local distance = AITile.GetDistanceManhattanToTile(AITown.GetLocation(traska.end), AIIndustry.GetLocation(traska.start));
	   new=base;
	   new*= distanceBetweenIndustriesValuator(distance);
	   /*if(AIIndustry.GetStockpiledCargo(x, traska.cargo)==0)*/ new*=2;
		if(new>best)
			{
	        Info("Z " + AIIndustry.GetName(traska.start) + " nie ma dokad wysylac. Sorry. Or maybe " + AITown.GetName(traska.end));
			traska = ToCityStationAllocator(traska)
			if(traska.StationsAllocated())
				{
				traska = FindEngine(traska);
				if(traska.engine != null)
				   {
				best = new;
				choise.start = traska.start;
				choise.end = traska.end;
				choise.zakazane = traska.zakazane;
				choise.start_otoczka = traska.start_otoczka;
				choise.koniec_otoczka = traska.koniec_otoczka;
				choise.depot_tile = traska.depot_tile;
				choise.end_station = traska.end_station;
				choise.start_tile = traska.start_tile;
				choise.end_tile = traska.end_tile;
				choise.cargo = traska.cargo;
				choise.production = traska.production;
				choise.type = traska.type;
				choise.station_size = traska.station_size;
				choise.engine = traska.engine;
				choise.engine_count = traska.engine_count;
				choise.budget = traska.budget;
				choise.demand = traska.demand;
				choise.first_station.direction = traska.first_station.direction;
				choise.second_station.direction = traska.second_station.direction;
				choise.first_station.location = traska.first_station.location;
				choise.second_station.location = traska.second_station.location;

				choise.start_tile = AIIndustry.GetLocation(traska.start);
				choise.end_tile = AITown.GetLocation(traska.end);
					}
				}
			}
		}
	}
	}
this.Info("");
this.Info("(" + best + " points)");

if(best==0) 
   {
   traska.OK=false;
   return traska;
   }
choise.OK=true;
if(AIIndustryType.IsRawIndustry(AIIndustry.GetIndustryType(choise.start))) choise.type=1;
else choise.type=0;

choise.Print();

return choise;
}