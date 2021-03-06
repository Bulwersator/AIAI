function IsItNeededToImproveThatStation(station, cargo) {
	//TODO: enable once it will be available in trunk
	//if (!AIStation.HasCargoRating(station, cargo)) {
	//	return false;
	//}
	if (AIStation.GetCargoWaiting(station, cargo)>50) {
		return true;
	}
	if (AIStation.GetCargoRating(station, cargo)<40 && AIStation.GetCargoWaiting(station, cargo)>0) {
		return true;
	}
	return false;
}
function IsItNeededToImproveThatNoRawStation(station, cargo) {
	//TODO: enable once it will be available in trunk
	//if (!AIStation.HasCargoRating(station, cargo)) {
	//	return false;
	//}
	if (AIStation.GetCargoRating(station, cargo)<70 && AIStation.GetCargoWaiting(station, cargo)>150) {
		return true;
	}
	if (AIStation.GetCargoRating(station, cargo)<40 && AIStation.GetCargoWaiting(station, cargo)>0) {
		return true;
	}
	return false;
}

function NameCompany() {
	if ((AICompany.GetName(AICompany.COMPANY_SELF)!="AIAI") && (AIVehicleList().Count()>0)) {
		while(true) {
			Error("Company created by other ai. As such it is not possible for AIAI to menage that company.");
			Info("Zzzzz...");
			Sleep(1000);
		}
	}
	AICompany.SetPresidentName("http://tinyurl.com/ottdaiai")
	AICompany.SetName("AIAI")
	if (AICompany.GetName(AICompany.COMPANY_SELF)!="AIAI") {
		if (!AICompany.SetName("Suicide AIAI")) {
			local i = 2;
			while (!AICompany.SetName("Suicide AIAI #" + i)) {
				i++;
			}
		}
		Info("BUUUUUUURN!");
		Money.BurnMoney();
		while(true) {
			Error("Multiple instances of AIAI would cause problems. As there is already other company named AIAI this company will do nothing");
			Info("Zzzzz...");
			Sleep(1000);
		}
	}
}

function AIAI::ShowContactInfoOnTheMap() {
	if (AIAI.GetSetting("hide_contact_information") != 1) {
		local tile = AICompany.GetCompanyHQ(AICompany.COMPANY_SELF);
		if (!AIMap.IsValidTile(tile)) {
			return false;
		}
		AISign.BuildSign(tile, "In case of strange or stupid");
		AISign.BuildSign(tile+AIMap.GetTileIndex(1, 1), "AIAI behaviour, please");
		AISign.BuildSign(tile+AIMap.GetTileIndex(2, 2), "report it on");
		AISign.BuildSign(tile+AIMap.GetTileIndex(3, 3), "http://tinyurl.com/ottdaiai");
		AISign.BuildSign(tile+AIMap.GetTileIndex(4, 4), "or matkoniecz@gmail.com");
		return true;
	}
	return false;
}

function IsConnectedIndustryUsingThisAirport(industry, cargo_id, airport_type) {
	local radius = AIAirport.GetAirportCoverageRadius(airport_type)

	local tile_list=AITileList_IndustryProducing(industry, radius)
	for (local q = tile_list.Begin(); tile_list.HasNext(); q = tile_list.Next()) {
		local station_id = AIStation.GetStationID(q)
		if (AIAirport.IsAirportTile(q))
			if (AIAirport.GetAirportType(q)==airport_type) {
				if (IsCargoLoadedOnThisStation(station_id, cargo_id)) {
					return true;
				}
			}
		}
	return false;
}

function IsConnectedIndustry(industry_id, cargo_id) {
	if (AIStationList(AIStation.STATION_ANY).IsEmpty()) {
		return false;
	}

	local tile_list = AITileList_IndustryProducing(industry_id, AIStation.GetCoverageRadius(AIStation.STATION_TRAIN))

	for(local tile = tile_list.Begin(); tile_list.HasNext(); tile = tile_list.Next()) {
		local station_id = AIStation.GetStationID(tile)
		if (AIStation.IsValidStation(station_id)) {
			if (AITile.HasTransportType(tile, AITile.TRANSPORT_RAIL)) {//check for railstation (workaround, as there is no equivalent of IsAirportTile. this hack will fail with eyecandy station tiles without rail)
				if (IsCargoLoadedOnThisStation(station_id, cargo_id)) {
					return true;
				}
			}
		}
	}

	assert(AIStation.GetCoverageRadius(AIStation.STATION_TRUCK_STOP) == AIStation.GetCoverageRadius(AIStation.STATION_BUS_STOP));
	local tile_list = AITileList_IndustryProducing(industry_id, AIStation.GetCoverageRadius(AIStation.STATION_TRUCK_STOP))
	for(local tile = tile_list.Begin(); tile_list.HasNext(); tile = tile_list.Next()) {
		local station_id = AIStation.GetStationID(tile)
		if (AIStation.IsValidStation(station_id)) {
			if (AITile.HasTransportType(tile, AITile.TRANSPORT_ROAD)) { //check for railstation (workaround, as there is no equivalent of IsAirportTile. this hack will fail with eyecandy station tiles)
				if (IsCargoLoadedOnThisStation(station_id, cargo_id)) {
					return true;
				}
			}
		}
	}

	if (IsConnectedIndustryUsingThisAirport(industry_id, cargo_id, AIAirport.AT_LARGE)) {
		return true;
	}
	if (IsConnectedIndustryUsingThisAirport(industry_id, cargo_id, AIAirport.AT_METROPOLITAN)) {
		return true;
	}
	if (IsConnectedIndustryUsingThisAirport(industry_id, cargo_id, AIAirport.AT_COMMUTER)) {
		return true;
	}
	if (IsConnectedIndustryUsingThisAirport(industry_id, cargo_id, AIAirport.AT_SMALL)) {
		return true;
	}
	return false;
}
