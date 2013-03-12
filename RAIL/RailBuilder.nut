class RailPathProject
{
start = null;
end = null;
ignore = null;
function addToArray(arr, plus)
{
if(arr==null)
	{
	arr=array(1);
	arr[0]=plus;
	}
else
	{
	local arr_new=array(arr.len()+1)
	for(local i =0; i<arr.len(); i++)
		{
		arr_new[i]=arr[i]
		}
	arr_new[arr.len()]=plus;
	arr=arr_new;
	}
return arr;
}

function addStart(plus)
{
//Info("Newstart");
if(plus == null)return;
start = addToArray(start, plus)
}

function addEnd(plus)
{
//Info("Newend");
if(plus == null)return;
end = addToArray(end, plus)
}

function addIgnore(plus)
{
//Info("Newigmore");
if(plus == null)return;
ignore = addToArray(ignore, plus)
}
}

class RailBuilder extends Builder
{
trasa = Route();
path = null;
ignore = null;

//[start_tile, tile_before_start]
start = array(2);
end = array(2);
};

require("RailBuilderPathfinder.nut")
require("RailBuilderDepotConnection.nut")

class tiles
{
a = null;
b = null;
}

function RailBuilder::Maintenance() 
{
if(AIStationList(AIStation.STATION_TRAIN).Count()==0)return;
local new_trains = this.AddTrains();
Info(new_trains + " new train(s)");
}

function RailBuilder::AddTrains()
{
local ile=0;
local cargo_list=AICargoList();
for (local cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next())
	{
	local station_list=AIStationList(AIStation.STATION_TRAIN);
	for (local station = station_list.Begin(); station_list.HasNext(); station = station_list.Next())
		{
		if(AgeOfTheYoungestVehicle(station)>110) // -spam
		if(IsItNeededToImproveThatNoRawStation(station, cargo))
			{
			local vehicle_list=AIVehicleList_Station(station);
			local how_many = vehicle_list.Count();
			vehicle_list.Valuate(rodzic.CzyNaSprzedaz);
			vehicle_list.KeepValue(0);
			if(how_many != vehicle_list.Count()) continue; //wait for sell
			local max_train_count=LoadDataFromStationNameFoundByStationId(station, "{}");

			Warning(max_train_count+"<>"+how_many)
			if(how_many>=max_train_count)continue;

			vehicle_list.Valuate(AIBase.RandItem);
			vehicle_list.Sort(AIAbstractList.SORT_BY_VALUE, AIAbstractList.SORT_DESCENDING);
			if(vehicle_list.Count()==0)continue;
			local original=vehicle_list.Begin();
			if(AIStation.GetLocation(station)!=GetLoadStationLocation(original))abort("wtf");
		 
			local loaded_and_empty=0;
			if(AIVehicle.GetProfitLastYear(original)<0)continue;
			for (local vehicle = vehicle_list.Begin(); vehicle_list.HasNext(); vehicle = vehicle_list.Next())
				{
				if(rodzic.CzyNaSprzedaz(vehicle)) loaded_and_empty=-1001;
				if(AIVehicle.GetCargoLoad(vehicle, cargo)==0){
					loaded_and_empty--;
					if(AITile.GetDistanceManhattanToTile(GetLoadStationLocation(vehicle), AIVehicle.GetLocation(vehicle))<30)
						{
						loaded_and_empty-=100;
						}
					}
				else { 
					if(AITile.GetDistanceManhattanToTile(GetUnloadStationLocation(vehicle), AIVehicle.GetLocation(vehicle))<30)
						{
						loaded_and_empty-=100;
						}
					else
						{
						loaded_and_empty++;
						}
					}
				Info(loaded_and_empty+" - loaded_and_empty")
				}
			Warning(loaded_and_empty+"loaded_and_empty")
			if(loaded_and_empty<1)continue; //station may be filled with cargo, but trains may still wait (poor station design/hills)

			local end = AIOrder.GetOrderDestination(original, AIOrder.GetOrderCount(original)-2);
			//if(AITile.GetCargoAcceptance (end, cargo, 1, 7, 5)==0) //TODO: improve it to have real data
			//   {
			//	if(rodzic.GetSetting("other_debug_signs"))AISign.BuildSign(end, "ACCEPTATION STOPPED");
			//	continue;
			//	}
			if(this.copyVehicle(original, cargo )) ile++;
			}
		}
	}
return ile;
}

function RailBuilder::copyVehicle(main_vehicle_id, cargo)
{
Info("Copying "+AIVehicle.GetName(main_vehicle_id))
if(!AIVehicle.IsValidVehicle(main_vehicle_id))return false;

local depot_tile = GetDepotLocation(main_vehicle_id);
if(AIVehicleList_SharedOrders(main_vehicle_id).Count()<LoadDataFromStationNameFoundByStationId( AIStation.GetStationID(GetLoadStationLocation(main_vehicle_id)), "{}"))
   {
   local vehicle_id = AIVehicle.CloneVehicle(depot_tile, main_vehicle_id, true);
   if(AIVehicle.IsValidVehicle(vehicle_id))
      {
 	  if(AIVehicle.StartStopVehicle (vehicle_id))return true;
	  }
   }   
return false;
}

function RailBuilder::TrainReplace()
{
	local station_list = AIStationList(AIStation.STATION_TRAIN);
	if(station_list.Count()==0)return;
	Info("function RailBuilder::TrainReplace()");
	local i=0;
	for (local station_id = station_list.Begin(); station_list.HasNext(); station_id = station_list.Next()){
		local vehicle_list=AIVehicleList_Station(station_id);
		if(vehicle_list.Count()==0)continue;
		local front_vehicle = vehicle_list.Begin();
		if( station_id != AIStation.GetStationID(GetLoadStationLocation(front_vehicle)))
			{
			continue;
			}
		i++;
		Info(i + " of " + station_list.Count() + " stations [ " + AIStation.GetName(station_id) + " ] ");
		if(vehicle_list.Count()==0)continue;
		Info("vehicles!");
		local j=0;
		for (local vehicle = vehicle_list.Begin(); vehicle_list.HasNext(); vehicle = vehicle_list.Next()){
			j++;
			Info(j + " of " + vehicle_list.Count() + " trains [ " + AIVehicle.GetName(vehicle) + " ] ");
			if(rodzic.CzyNaSprzedaz(vehicle)){
				Info("Skip for sell");
				continue;
				}
			Info("!sell");
			local cargo_list = AICargoList();
			local max = 0;
			local max_cargo;
			for (local cargo = cargo_list.Begin(); cargo_list.HasNext(); cargo = cargo_list.Next()){
				if(AIVehicle.GetCapacity(vehicle, cargo)>max){
					max = AIVehicle.GetCapacity(vehicle, cargo);
					max_cargo = cargo;
					}
				}
			local wrzut = Route();
			wrzut.cargo = max_cargo;
			wrzut.station_size = this.GetStationSize(GetLoadStationLocation(vehicle));
			wrzut.depot_tile = GetDepotLocation(vehicle);
			wrzut.track_type = AIRail.GetRailType(GetLoadStationLocation(vehicle));
			wrzut = RailBuilder.FindTrain(wrzut);
			local engine = wrzut.engine[0];
			local wagon = wrzut.engine[1];
			local new_speed = this.GetMaxSpeedOfTrain(engine, wagon);

			local old_engine = AIVehicle.GetEngineType(vehicle);
			local old_wagon = AIVehicle.GetWagonEngineType(vehicle, 0);
	
			local old_speed = this.GetMaxSpeedOfTrain(old_engine, old_wagon);

			if(new_speed>old_speed){
				if(AIAI.CzyNaSprzedaz(vehicle)==false){
					local train = this.BuildTrain(wrzut, "replacing");
					if(train != null){
						if(AIOrder.ShareOrders(train, vehicle)){
							AIAI.gentleSellVehicle(vehicle, "replaced");
						}
					}
				}	
			}
		}
	}
}

function RailBuilder::GetStationSize(station_tile)
{
if(AIRail.GetRailStationDirection(station_tile)==AIRail.RAILTRACK_NE_SW) //x_is_constant__horizontal
   {
   for(local i = 0; true; i++)
      {
	  if(AIStation.GetStationID(station_tile + AIMap.GetTileIndex(i, 0))!=AIStation.GetStationID(station_tile))return i;
	  }
   }
else
   {
   for(local i = 0; true; i++)
      {
	  if(AIStation.GetStationID(station_tile + AIMap.GetTileIndex(0, i))!=AIStation.GetStationID(station_tile))return i;
	  }
   }
}

function RailBuilder::GetMaxSpeedOfTrain(engine, wagon)
{
if(engine == null || wagon == null)return 0;
  local speed_wagon = AIEngine.GetMaxSpeed(wagon);
  if(speed_wagon == 0) {speed_wagon = 2500;}
  local speed_engine = AIEngine.GetMaxSpeed(engine);
  if(speed_wagon < speed_engine) return speed_wagon;
  return speed_engine;
}

function RailBuilder::RailwayLinkConstruction(path)
{
AIRail.SetCurrentRailType(trasa.track_type); 
return DumbBuilder(path);
}

function RailBuilder::DumbRemover(path, goal)
{
local prev = null;
local prevprev = null;
while (path != null) {
  if (prevprev != null) {
  //AISign.BuildSign(prev, "prev");
  if(prev==goal)return true;
  
    if (AIMap.DistanceManhattan(prev, path.GetTile()) > 1) {
      if (AITunnel.GetOtherTunnelEnd(prev) == path.GetTile()) {
        AITile.DemolishTile(prev);
      } else {
        AITile.DemolishTile(prev);
      }
      prevprev = prev;
      prev = path.GetTile();
      path = path.GetParent();
    } else {
      AIRail.RemoveRail(prevprev, prev, path.GetTile());
    }
  }
  if (path != null) {
    prevprev = prev;
    prev = path.GetTile();
    path = path.GetParent();
  }
}
return true;
}

function RailBuilder::DumbBuilder(path)
	{
	local copy = path;
	local prev = null;
	local prevprev = null;
	while (path != null) {
		if(prevprev != null) {
			if(AIMap.DistanceManhattan(prev, path.GetTile()) > 1) {
				if(AITunnel.GetOtherTunnelEnd(prev) == path.GetTile()) {
					if(!AITunnel.BuildTunnel(AIVehicle.VT_RAIL, prev)){
						DumbRemover(copy, prev);
						return false;
						}

					} 
				else{
					local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), prev) + 1);
					bridge_list.Valuate(AIBridge.GetMaxSpeed);
					bridge_list.Sort(AIAbstractList.SORT_BY_VALUE, false);
					if(!AIBridge.BuildBridge(AIVehicle.VT_RAIL, bridge_list.Begin(), prev, path.GetTile())){
						DumbRemover(copy, prev);
						return false;
						}
					}
				prevprev = prev;
				prev = path.GetTile();
				path = path.GetParent();
				}
			else { //!AIMap.DistanceManhattan(prev, path.GetTile()) > 1
				if(!AIRail.BuildRail(prevprev, prev, path.GetTile())){
					DumbRemover(copy, prev);
					return false;
					}
				}
			}
		if (path != null) {
			prevprev = prev;
			prev = path.GetTile();
			path = path.GetParent();
			}
		}
	return true;
	}

function RailBuilder::GetCostOfRoute(path)
{
local costs = AIAccounting();
costs.ResetCosts ();

/* Exec Mode */
local test = AITestMode();
/* Test Mode */

if(this.DumbBuilder(path))
   {
   return costs.GetCosts();
   }
else return null;
}

class RPathItem
{
	_tile = null;
	_parent = null;

	constructor(tile)
	{
		this._tile = tile;
	}

	function GetTile()
	{
		return this._tile;
	}

	function GetParent()
	{
		return this._parent;
	}
};

function RailBuilder::WeightOfEngine(engine, cargo)
{
local weight = AIEngine.GetWeight(engine);
local capacity = max(AIEngine.GetCapacity(engine), 0);
if(AICargo.IsFreight(cargo)) weight += capacity * AIGameSettings.GetValue("vehicle.freight_trains");
return weight;
}

function RailBuilder::BuildTrain(route, string) //from denver & RioGrande
{	
	Info("BuildTrain")
	local costs = AIAccounting();
	costs.ResetCosts ();
	local bestEngine = route.engine[0];
	local bestWagon = route.engine[1];
	local depotTile = route.depot_tile;
	local stationSize = route.station_size;
	local cargoIndex = route.cargo;
	if(!AIEngine.IsBuildable(bestEngine) || !AIEngine.IsBuildable(bestWagon)) abort("impossible engine");
	
	local engineId = AIAI.BuildVehicle(depotTile, bestEngine);
	if(!AIVehicle.IsValidVehicle(engineId)){	
		Info("Failed to build engine '" + AIEngine.GetName(bestEngine) +"':" + AIError.GetLastErrorString() +" **@@*");
		//TODO - ban engine
		return null;
		}
	SetNameOfVehicle(engineId, "in construction");
	
	AIVehicle.RefitVehicle(engineId, trasa.cargo);

	local max_number_of_wagons = 1000;
	local maximal_weight = AIEngine.GetMaxTractiveEffort(bestEngine) * 3;
	local capacity_of_engine = AIVehicle.GetCapacity(engineId, cargoIndex);	
	local weight_of_engine = AIEngine.GetWeight(bestEngine) + (capacity_of_engine * AIGameSettings.GetValue("vehicle.freight_trains"));
	local length_of_engine = AIVehicle.GetLength(engineId);
	local weight_of_wagon;
	local length_of_wagon=null;

	for(local i = 0; i<max_number_of_wagons; i++) {
		if(i==1) {
			weight_of_wagon = AIEngine.GetWeight(bestWagon);
			weight_of_wagon += (AIVehicle.GetCapacity(engineId, cargoIndex) - capacity_of_engine) * AIGameSettings.GetValue("vehicle.freight_trains");		
			if(AIGameSettings.GetValue("vehicle.train_acceleration_model")==1) max_number_of_wagons = (maximal_weight-weight_of_engine)/weight_of_wagon;
			length_of_wagon = AIVehicle.GetLength(engineId) - length_of_engine;
			Info("length_of_wagon "+length_of_wagon+"; length_of_engine "+length_of_engine);
			if (max_number_of_wagons > (AIGameSettings.GetValue("max_train_length")*16-length_of_engine)/length_of_wagon) {
				max_number_of_wagons = (AIGameSettings.GetValue("max_train_length")*16-length_of_engine)/length_of_wagon;
				}
			Info("Limit:"+max_number_of_wagons);
			}
		//Info("Train length: "+AIVehicle.GetLength(engineId));
		local newWagon = AIAI.BuildVehicle(depotTile, bestWagon);        
		if(!AIVehicle.IsValidVehicle(newWagon)){	
			Info("Failed to build wagon '" + AIEngine.GetName(bestWagon) +"':" + AIError.GetLastErrorString());
			}
		AIVehicle.RefitVehicle(newWagon, cargoIndex);
		if(!AIVehicle.IsValidVehicle(newWagon))abort("!IsValidVehicle(newWagon)");
		if(! (0 < AIVehicle.GetNumWagons(newWagon))) abort("0 < GetNumWagons(newWagon)");
		if(!(AIVehicle.IsValidVehicle(engineId))) abort("AIVehicle.IsValidVehicle(engineId)");
		if(! (0 < AIVehicle.GetNumWagons(engineId)))abort("0 < AIVehicle.GetNumWagons(engineId)");
		if(! (AIVehicle.GetVehicleType(engineId) == AIVehicle.VT_RAIL)) abort("AIVehicle.GetVehicleType(engineId) == VT_RAIL")
		if(!AIVehicle.MoveWagon(newWagon, 0, engineId, 0)) {
			Error("Couldn't join wagon to train: " + AIError.GetLastErrorString());
			if(AIError.GetLastError() == AIError.ERR_PRECONDITION_FAILED) {
				abort("ERR_PRECONDITION_FAILED in MoveWagon");
				}
			if(i==0) {
				Error("Couldn't join any wagon to train: " + AIError.GetLastErrorString());   
				return null;
				}
			}
		if(AIVehicle.GetLength(engineId)>stationSize*16) {
			if(!AIVehicle.SellWagon(engineId, AIVehicle.GetNumWagons(engineId)-1)) {
				Abort("error on sell engine");
				return null;
				}
			break;
			}	
		}

	//multiplier: for weak locos it may be possible to merge multiple trains ito one (2*loco + 10*wagon, instead of loco+5 wagons)
	//multiplier = how many trains are merged into one
   	local multiplier = min(GetAvailableMoney()/costs.GetCosts(), route.station_size*16/AIVehicle.GetLength(engineId));
	multiplier--; //one part of train is already constructed
	for(local x=0; x<multiplier; x++){
		local newengineId = AIAI.BuildVehicle(route.depot_tile, bestEngine);
		AIVehicle.RefitVehicle(newengineId, route.cargo);
		AIVehicle.MoveWagon(newengineId, 0, engineId, 0);
		for(local i = 0; i<max_number_of_wagons; i++){
			if(AIVehicle.GetLength(engineId)>route.station_size*16){
				AIVehicle.SellWagon(engineId, AIVehicle.GetNumWagons(engineId)-1);
				break;
				}
			local newWagon = AIAI.BuildVehicle(route.depot_tile, bestWagon);        
			AIVehicle.RefitVehicle(newWagon, cargoIndex);
			if(!AIVehicle.MoveWagon(newWagon, 0, engineId, AIVehicle.GetNumWagons(engineId)-1)){
				Error("Couldn't join wagon to train: " + AIError.GetLastErrorString());
				}
			}
		}
	if(AIVehicle.GetCapacity(engineId, route.cargo) == 0) return null;
	if(AIVehicle.StartStopVehicle(engineId))
		{
		SetNameOfVehicle(engineId, string);
		return engineId;
		}
	local error=AIError.GetLastError();
	Error("StartStopVehicle failed! Evil newgrf?");
	if(!AIVehicle.IsValidVehicle(engineId))
		{
		AISign.BuildSign(depotTile, "Please, post savegame on ttforums - http://tinyurl.com/ottdaiai (or send mail on bulwersator@gmail.com)");
		abort("Sth happened with train (invalid id)!");
		}
	if(error==AIVehicle.ERR_VEHICLE_NO_POWER)
		{
		AISign.BuildSign(depotTile, "Please, post savegame on ttforums - http://tinyurl.com/ottdaiai (or send mail on bulwersator@gmail.com)");
		abort("Sth happened with train (no power)!");
		}
	Error("Brake van?");
	AIVehicle.SellWagon(engineId, AIVehicle.GetNumWagons(engineId)-1);
	Error("Last wagon sold");
	
	local newWagon = AIAI.BuildVehicle(route.depot_tile, GetBrakeVan());        
	if(!AIVehicle.MoveWagon(newWagon, 0, engineId, AIVehicle.GetNumWagons(engineId)-1))
		Error("Couldn't join brake van to train: " + AIError.GetLastErrorString());

	if(AIVehicle.StartStopVehicle(engineId))
		{
		SetNameOfVehicle(engineId, string);
		return engineId;
		}
	Error("ARGHHHHHHHHHHHHHHHHHHHHHHHHHHHHH!");
	//TODO - ignore this train, retry with another engine?
	return null;
}

function RailBuilder::GetBrakeVan()
	{
	local wagons = AIEngineList(AIVehicle.VT_RAIL);
	wagons.Valuate(AIEngine.IsWagon);
	wagons.RemoveValue(0);
	wagons.Valuate(AIEngine.IsBuildable);
	wagons.RemoveValue(0);
	wagons.Valuate(AIEngine.CanRunOnRail, AIRail.GetCurrentRailType());
	wagons.RemoveValue(0);
	local cargo_list=AICargoList();
	for (local cargoIndex = cargo_list.Begin(); cargo_list.HasNext(); cargoIndex = cargo_list.Next()){
		wagons.Valuate(AIEngine.CanRefitCargo, cargoIndex);
		wagons.RemoveValue(1);
		}
	if(wagons.Count() == 0){
		Error("No brake van on the current track (" + AIRail.GetCurrentRailType() + ").");
	} else {
		wagons.Valuate(AIEngine.GetMaxSpeed);
		return wagons.Begin();
		}
	}
	
function RailBuilder::SignalPath(path, flip) //admiral
{
SignalPathAdvanced(path, flip, 0, 999999)
}

function RailBuilder::SignalPathAdvanced(path, flip, skip, signal_count_limit) //admiral
{
	local prev = null;
	local prevprev = null;
	local tiles_skipped = 50-(skip)*10;
	local lastbuild_tile = null;
	local lastbuild_front_tile = null;
	while (path != null) {
		if (prevprev != null) {
			if (AIMap.DistanceManhattan(prev, path.GetTile()) > 1) {
				tiles_skipped += 10 * AIMap.DistanceManhattan(prev, path.GetTile());
			} else {
				if (path.GetTile() - prev != prev - prevprev) {
					tiles_skipped += 7;
				} else {
					tiles_skipped += 10;
				}
				//AISign.BuildSign(path.GetTile(), "tiles skipped: "+tiles_skipped)
				if (AIRail.GetSignalType(prev, path.GetTile()) != AIRail.SIGNALTYPE_NONE) tiles_skipped = 0;
				//AISign.BuildSign(path.GetTile(), tiles_skipped)
				if (tiles_skipped > 49 && path.GetParent() != null && signal_count_limit>0) {
					local status=false;
					if (flip)
						{
						status=AIRail.BuildSignal(path.GetTile(), prev, AIRail.SIGNALTYPE_PBS_ONEWAY);
						}
					else
						{
						status=AIRail.BuildSignal(prev, path.GetTile(), AIRail.SIGNALTYPE_PBS_ONEWAY);
						}
					if (status) {
						tiles_skipped = 0;
						lastbuild_tile = prev;
						lastbuild_front_tile = path.GetTile();
						signal_count_limit--;
					}
				}
			}
		}
		prevprev = prev;
		prev = path.GetTile();
		path = path.GetParent();
	}
	/* Although this provides better signalling (trains cannot get stuck half in the station),
	 * it is also the cause of using the same track of rails both ways, possible causing deadlocks.
	if (tiles_skipped < 50 && lastbuild_tile != null) {
		AIRail.RemoveSignal(lastbuild_tile, lastbuild_front_tile);
	}*/
}

function RailBuilder::TrainOrders(engineId)
{
if(trasa.type==1) //1 raw
   {
	AIOrder.AppendOrder (engineId, trasa.first_station.location, AIOrder.AIOF_FULL_LOAD_ANY | AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (engineId, trasa.second_station.location, AIOrder.AIOF_NON_STOP_INTERMEDIATE | AIOrder.AIOF_NO_LOAD );
	}
else if(trasa.type==0) //0 proceed trasa.cargo
   {
	AIOrder.AppendOrder (engineId, trasa.first_station.location, AIOrder.AIOF_FULL_LOAD_ANY | AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (engineId, trasa.second_station.location, AIOrder.AIOF_NON_STOP_INTERMEDIATE | AIOrder.AIOF_NO_LOAD );
	}
else if(trasa.type == 2) //2 passenger
   {
	AIOrder.AppendOrder (engineId, trasa.first_station.location, AIOrder.AIOF_FULL_LOAD_ANY | AIOrder.AIOF_NON_STOP_INTERMEDIATE );
	AIOrder.AppendOrder (engineId, trasa.second_station.location, AIOrder.AIOF_FULL_LOAD_ANY | AIOrder.AIOF_NON_STOP_INTERMEDIATE );
   }
else
   {
   abort("Wrong value in trasa.type. (" + trasa.type + ") Prepare for explosion.");
   }
}
function RailBuilder::ValuatorRailType(rail_type_id)
{
local max_speed = AIRail.GetMaxSpeed(rail_type_id);
if(max_speed==0){
	local engines = AIEngineList(AIVehicle.VT_RAIL);
	engines.Valuate(AIEngine.IsWagon);
	engines.RemoveValue(1);  
	engines.Valuate(AIEngine.IsBuildable);
	engines.RemoveValue(0);
	engines.Valuate(AIEngine.HasPowerOnRail, rail_type_id);
	engines.RemoveValue(0);
	engines.Valuate(AIEngine.CanRunOnRail, rail_type_id);
	engines.RemoveValue(0);
	engines.Valuate(AIEngine.GetMaxSpeed);
	engines.Sort(AIAbstractList.SORT_BY_VALUE, false); //descending
	max_speed=engines.GetValue(engines.Begin());
	}
return max_speed*5-AIRail.GetBuildCost(rail_type_id, AIRail.BT_TRACK);
}

function RailBuilder::GetRailTypeList() //modified //from DenverAndRioGrande
	{
	local railTypes = AIRailTypeList();
	if(railTypes.Count() == 0){
		Error("No rail types!");
		return null;
		}
	railTypes.Valuate(AIRail.IsRailTypeAvailable);
	railTypes.KeepValue(1);

	if(railTypes.Count() == 0){
		Error("No available rail types!");
		return null;
		}
  
	railTypes.Valuate(this.ValuatorRailType);
	railTypes.Sort(AIAbstractList.SORT_BY_VALUE, false); //descending

	return railTypes;
	}

function RailBuilder::FindTrain(trasa)//from DenverAndRioGrande
	{
	local wagon = RailBuilder.FindBestWagon(trasa.cargo, trasa.track_type)
	local engine = null;
	if(wagon != null)
		{
		engine = RailBuilder.FindBestEngine(wagon, trasa.station_size, trasa.cargo, trasa.track_type);
		}
	trasa.engine = array(2);
	trasa.engine[0] = engine;
	trasa.engine[1] = wagon;
	return trasa;
	}

function RailBuilder::GetTrain(trasa)//from DenverAndRioGrande
	{
	local railTypes = GetRailTypeList();

	/*
	for(local rail_type = railTypes.Begin(); railTypes.HasNext(); rail_type = railTypes.Next()){
		local max_speed = AIRail.GetMaxSpeed(rail_type);
		local cost = AIRail.GetBuildCost(rail_type, AIRail.BT_TRACK);
		Info("Railtype " + AIRail.GetName(rail_type) + "("+rail_type+") with " + max_speed + " max speed and cost of " + cost + " has " + (max_speed*5-cost) + " points.");
		}
	*/

	for(local rail_type = railTypes.Begin(); railTypes.HasNext(); rail_type = railTypes.Next()){		
		local max_speed = AIRail.GetMaxSpeed(rail_type);
		local cost = AIRail.GetBuildCost(rail_type, AIRail.BT_TRACK);
		Info("Railtype "+ AIRail.GetName(rail_type) + " ( " +rail_type+" ) with " + max_speed + " max speed and cost of " + cost)// + " has " + (max_speed*5-cost) + " points.");

		trasa.track_type = rail_type;
		trasa = RailBuilder.FindTrain(trasa);
		if(trasa.engine[0] != null && trasa.engine[1] != null ) {
			//Info("Return OK: " + trasa.engine);
			//Info("engine:" + trasa.engine[0] + "wagon:" + trasa.engine[1] )
			//Info("engine:" + AIEngine.GetName(trasa.engine[0]) + "wagon:" + AIEngine.GetName(trasa.engine[1]) )
			return trasa;
		}
	}
	Error("No engine!")
	trasa.engine = null;
	return trasa;
	}

function RailBuilder::FindWagons(cargoIndex, track_type)//from DenverAndRioGrande
	{
    local wagons = AIEngineList(AIVehicle.VT_RAIL);
    wagons.Valuate(AIEngine.IsWagon);
    wagons.RemoveValue(0);
    wagons.Valuate(AIEngine.IsBuildable);
    wagons.RemoveValue(0);
    wagons.Valuate(AIEngine.CanRefitCargo, cargoIndex);
    wagons.RemoveValue(0);
    wagons.Valuate(AIEngine.CanRunOnRail, track_type);
    wagons.RemoveValue(0);
    if(wagons.Count() == 0){
		Error("No wagons can pull or be refitted to this cargo (" + AICargo.GetCargoLabel(cargoIndex) + ") on the current track (" + AIRail.GetCurrentRailType() + ").");
		}
    return wagons;
	}

function RailBuilder::WagonValuator(engineId)//from DenverAndRioGrande
	{
	return  AIEngine.GetCapacity(engineId) * AIEngine.GetMaxSpeed(engineId);
	}

function RailBuilder::FindBestWagon(cargoIndex, track_type)//from DenverAndRioGrande
	{   
    local wagons = RailBuilder.FindWagons(cargoIndex, track_type);
	if(wagons.Count()==0) return null;
    wagons.Valuate(RailBuilder.WagonValuator);
    return wagons.Begin();
	}

function RailBuilder::FindBestEngine(wagonId, trainsize, cargoId, track_type)//from DenverAndRioGrande	
	{
	local minHP = 175 * trainsize;
  
	local speed = AIEngine.GetMaxSpeed(wagonId);
	if(speed == 0) {speed = 2500;}
	local engines = AIEngineList(AIVehicle.VT_RAIL);
	engines.Valuate(AIEngine.IsWagon);
	engines.RemoveValue(1);
	
	engines.Valuate(AIEngine.IsBuildable);
	engines.RemoveValue(0);
	engines.Valuate(AIEngine.CanPullCargo, cargoId);
	engines.RemoveValue(0);
	engines.Valuate(AIEngine.HasPowerOnRail, track_type);
	engines.RemoveValue(0);
	engines.Valuate(AIEngine.CanRunOnRail, track_type);
	engines.RemoveValue(0);
	
	engines.Valuate(AIEngine.GetPower);
	
	engines.Sort(AIAbstractList.SORT_BY_VALUE, false);
	
/*	if(engines.GetValue(engines.Begin()) < minHP ) //no engine can pull the wagon at it's top speed.
		{
		Error("No engine has enough horsepower to pull all the wagons well.");
		}
	else{
		engines.RemoveBelowValue(minHP);
		} TODO: przerobi� ca�e engine choosing*/
	
  
	engines.Valuate(AIEngine.GetMaxSpeed);
	engines.Sort(AIAbstractList.SORT_BY_VALUE, false);
	if(engines.Count()==0) return null;
	
	if(engines.GetValue(engines.Begin()) < speed ) //no engine can pull the wagon at it's top speed.
		{
		//Info("No engine has top speed of wagon. Checking Fastest.");
		//Info("The fastest engine to pull '" + AIEngine.GetName(wagonId) + "'' at full speed ("+ speed +") is '" + AIEngine.GetName(engines.Begin()) +"'" );
		local cash = GetAvailableMoney();
		if(cash > AIEngine.GetPrice(engines.Begin()) * 2 || AIVehicleList().Count() > 10)//if there are 10 trains, just return the best one and let it fail.
			{
			return engines.Begin();
			}
		else{
			//Info("The company is poor. Picking a slower, cheaper engine.");
			engines.Valuate(AIEngine.GetPrice);
			engines.Sort(AIAbstractList.SORT_BY_VALUE, true);
			//Info("The Cheapest engine to pull '" + AIEngine.GetName(wagonId) + "'  is '" + AIEngine.GetName(engines.Begin()) +"'" );
			return engines.Begin();
			}
		}
  
	engines.RemoveBelowValue(speed);
	engines.Valuate(AIEngine.GetPrice);
	engines.Sort(AIAbstractList.SORT_BY_VALUE, true);
	
	//Info("The cheapest engine to pull '" + AIEngine.GetName(wagonId) + "'' at full speed ("+ speed +") is '" + AIEngine.GetName(engines.Begin()) +"'" );
	return engines.Begin();
	}
	
function RailBuilder::ValuateProducer(ID, cargo)
	{
	if(AIIndustry.GetLastMonthProduction(ID, cargo)<50-4*desperation)return 0; //protection from tiny industries servised by giant trains
	local base = AIIndustry.GetLastMonthProduction(ID, cargo);
	base*=(100-AIIndustry.GetLastMonthTransportedPercentage (ID, cargo));
	if(AIIndustry.GetLastMonthTransportedPercentage (ID, cargo)==0)base*=3;
	base*=AICargo.GetCargoIncome(cargo, 10, 50);
	if(base!=0){
		if(AIIndustryType.IsRawIndustry(AIIndustry.GetIndustryType(ID))){
			//base*=3;
			//base/=2;
			base+=10000;
			base*=100;
			}
		else{
			base*=min(99, TotalLastYearProfit())+1;
			}
		}
	//Info(AIIndustry.GetName(ID) + " is " + base + " point producer of " + AICargo.GetCargoLabel(cargo));
	return base;
	}

function RailBuilder::ValuateConsumer(ID, cargo, score)
	{
	if(AIIndustry.GetStockpiledCargo(ID, cargo)==0) score*=2;
	//Info("   " + AIIndustry.GetName(ID) + " is " + score + " point consumer of " + AICargo.GetCargoLabel(cargo));
	return score;
	}

function RailBuilder::GetMinimalStationSize()
	{
	return max(1, min(4 - (desperation/2), AIGameSettings.GetValue("station.station_spread")));
	}

function RailBuilder::StationPreparation() 
	{
	ignore = [];
	if(trasa.first_station.direction != StationDirection.x_is_constant__horizontal){
		start[0] = [trasa.first_station.location+AIMap.GetTileIndex(-1, 0), trasa.first_station.location] 
		start[1] = [trasa.first_station.location+AIMap.GetTileIndex(trasa.station_size, 0), trasa.first_station.location+AIMap.GetTileIndex(trasa.station_size -1, 0)] 
	for(local tile = trasa.first_station.location; tile!=trasa.first_station.location+AIMap.GetTileIndex(trasa.station_size, 0) ;tile+=AIMap.GetTileIndex(1, 0)){
			ignore.append(tile);
			}
		}
	else
		{
		start[0] = [trasa.first_station.location + AIMap.GetTileIndex(0, -1), trasa.first_station.location] //TODO drugi koniedc
		start[1] = [trasa.first_station.location+AIMap.GetTileIndex(0, trasa.station_size), trasa.first_station.location+AIMap.GetTileIndex(0, trasa.station_size -1)] 
	for(local tile = trasa.first_station.location; tile!=trasa.first_station.location+AIMap.GetTileIndex(0, trasa.station_size); tile+=AIMap.GetTileIndex(0, 1)){
		ignore.append(tile);
		}
   }

if(trasa.second_station.direction != StationDirection.x_is_constant__horizontal)
   {
   end[0] = [trasa.second_station.location+AIMap.GetTileIndex(-1, 0), trasa.second_station.location] //TODO drugi koniedc
   end[1] = [trasa.second_station.location+AIMap.GetTileIndex(trasa.station_size, 0), trasa.second_station.location+AIMap.GetTileIndex(trasa.station_size -1, 0)] 
   for(local tile = trasa.second_station.location; tile!=trasa.second_station.location+AIMap.GetTileIndex(trasa.station_size, 0) ;tile+=AIMap.GetTileIndex(1, 0))
		{
		ignore.append(tile);
		}
   }
else
   {
   end[0] = [trasa.second_station.location+AIMap.GetTileIndex(0, -1), trasa.second_station.location] //TODO drugi koniedc
   end[1] = [trasa.second_station.location+AIMap.GetTileIndex(0, trasa.station_size), trasa.second_station.location+AIMap.GetTileIndex(0, trasa.station_size -1)] 
   for(local tile = trasa.second_station.location; tile!=trasa.second_station.location+AIMap.GetTileIndex(0, trasa.station_size); tile+=AIMap.GetTileIndex(0, 1))
		{
		ignore.append(tile);
		}
   }
}

function RailBuilder::StationConstruction() 
{
//BuildNewGRFRailStation (TileIndex tile, RailTrack direction, uint num_platforms, uint platform_length, StationID station_id, 
//						CargoID cargo_id, IndustryType source_industry, IndustryType goal_industry, int distance, bool source_station)
AIRail.SetCurrentRailType(trasa.track_type); 
local source_industry;
local goal_industry;
if(trasa.first_station.is_city) source_industry = 0xFF;
else source_industry = AIIndustry.GetIndustryType(trasa.start);

if(trasa.second_station.is_city) goal_industry = 0xFF;
else goal_industry = AIIndustry.GetIndustryType(trasa.end);

local distance = 50;

if(trasa.first_station.direction != StationDirection.x_is_constant__horizontal)
   {
   //BuildNewGRFRailStation (TileIndex tile, RailTrack direction, uint num_platforms, uint platform_length, StationID station_id, CargoID cargo_id, IndustryType source_industry, IndustryType goal_industry, int distance, bool source_station)
   if(!AIRail.BuildNewGRFRailStation(trasa.first_station.location, AIRail.RAILTRACK_NE_SW, 1, trasa.station_size, AIStation.STATION_NEW, trasa.cargo, source_industry, goal_industry, distance, true)) //TODO to 1, 1 miasto (patrz tt moj temat)
   if(!AIRail.BuildRailStation(trasa.first_station.location, AIRail.RAILTRACK_NE_SW, 1, trasa.station_size, AIStation.STATION_NEW))
   {
	  AISign.BuildSign(trasa.first_station.location, AIError.GetLastErrorString()+" Smart Sa");
	  if(!trasa.first_station.is_city) trasa.forbidden.AddItem(trasa.start, 0);
	  return false;
	  }
   }
else
   {
   if(!AIRail.BuildNewGRFRailStation(trasa.first_station.location, AIRail.RAILTRACK_NW_SE, 1, trasa.station_size, AIStation.STATION_NEW, trasa.cargo, source_industry, goal_industry, distance, true)) 
   if(!AIRail.BuildRailStation(trasa.first_station.location, AIRail.RAILTRACK_NW_SE, 1, trasa.station_size, AIStation.STATION_NEW))
      {
	  AISign.BuildSign(trasa.first_station.location, AIError.GetLastErrorString()+" Smart Sb");
	  if(!trasa.first_station.is_city) trasa.forbidden.AddItem(trasa.start, 0);
	  return false;
	  }
   }

if(trasa.second_station.direction != StationDirection.x_is_constant__horizontal)
   {
   if(!AIRail.BuildNewGRFRailStation(trasa.second_station.location, AIRail.RAILTRACK_NE_SW, 1, trasa.station_size, AIStation.STATION_NEW, trasa.cargo, source_industry, goal_industry, distance, false))
   if(!AIRail.BuildRailStation(trasa.second_station.location, AIRail.RAILTRACK_NE_SW, 1, trasa.station_size, AIStation.STATION_NEW))
      {
	  AISign.BuildSign(trasa.second_station.location, AIError.GetLastErrorString()+" Smart Ea");
	  if(!trasa.second_station.is_city) trasa.forbidden.AddItem(trasa.end, 0);
	  AITile.DemolishTile(trasa.first_station.location);
	  return false;
	  }
   }
else
   {
   if(!AIRail.BuildNewGRFRailStation(trasa.second_station.location, AIRail.RAILTRACK_NW_SE, 1, trasa.station_size, AIStation.STATION_NEW, trasa.cargo, source_industry, goal_industry, distance, false))
   if(!AIRail.BuildRailStation(trasa.second_station.location, AIRail.RAILTRACK_NW_SE, 1, trasa.station_size, AIStation.STATION_NEW))
      {
	  AISign.BuildSign(trasa.second_station.location, AIError.GetLastErrorString()+" Smart Eb");
	  if(!trasa.second_station.is_city) trasa.forbidden.AddItem(trasa.end, 0); 
	  AITile.DemolishTile(trasa.first_station.location);
	  return false;
	  }
   }
return true;
}

function RailBuilder::PathFinder(reverse, limit) 
{
/*
trasa
ignore is used
*/
local pathfinder = Rail();
pathfinder.estimate_multiplier = 3;
pathfinder.cost.bridge_per_tile = 500;
pathfinder.cost.tunnel_per_tile = 35;
pathfinder.cost.diagonal_tile = 35;
pathfinder.cost.coast = 0;
pathfinder.cost.turn = 50;
pathfinder.cost.max_bridge_length = 40;   // The maximum length of a bridge that will be build.
pathfinder.cost.max_tunnel_length = 40;   // The maximum length of a tunnel that will be build.

pathfinder.InitializePath(end, start, ignore);
if(reverse)pathfinder.InitializePath(start, end, ignore);

path = false;
local guardian=0;
while (path == false) {
  Info("   Pathfinding ("+guardian+" / " + limit + ") started");
  path = pathfinder.FindPath(2000);
  Info("   Pathfinding ("+guardian+" / " + limit + ") ended");
  rodzic.Maintenance();
  AIController.Sleep(1);
  guardian++;
  if(guardian>limit )break;
}

if(path == false || path == null){
  Info("   Pathfinder failed to find route. ");
  return false;
  }
Info("   Pathfinder found sth.");
return true;
}