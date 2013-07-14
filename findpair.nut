function DefaultIsConsumerOK(industry_id)
{
	if(AIIndustry.IsValidIndustry(industry_id)==false) {
		return false; //industry closed during preprocessing
	}
	return true;
}

function DefaultIsProducerOK(industry_id)
{
	local cargo_list = AIIndustryType.GetProducedCargo(AIIndustry.GetIndustryType(industry_id));
	if(cargo_list==null) {
		return false;
	}
	if(cargo_list.Count()==0) {
		return false;
	}
	if(AIIndustry.IsValidIndustry(industry_id)==false) {
		return false; //industry closed during preprocessing
	}
	return true;
}

function FindPairWrapped (route, GetIndustryList, IsProducerOK, IsConnectedIndustry, ValuateProducer, IsConsumerOK, ValuateConsumer, distanceBetweenIndustriesValuator, DualIndustryStationAllocator, GetNiceTownForMe, CityStationAllocator, FindEngine)
{
	if(IsProducerOK == null) {
		IsProducerOK = DefaultIsProducerOK;
	}
	if(IsConsumerOK == null) {
		IsConsumerOK = DefaultIsConsumerOK;
	}
	return FindPairDeepWrapped (route, GetIndustryList, IsProducerOK, IsConnectedIndustry, ValuateProducer, IsConsumerOK, ValuateConsumer, distanceBetweenIndustriesValuator, DualIndustryStationAllocator, GetNiceTownForMe, CityStationAllocator, FindEngine);
}

function FindPairDeepWrapped (route, GetIndustryList, IsProducerOK, IsConnectedIndustry, ValuateProducer, IsConsumerOK, ValuateConsumer, distanceBetweenIndustriesValuator, DualIndustryStationAllocator, GetNiceTownForMe, ToCityStationAllocator, FindEngine)
{
	local industry_list = GetIndustryList();
	local choise = Route();
	Info("Finding the best route started! Industry list count: " + industry_list.Count());
	local best = 0;
	local new;
	//local counter = 1;
	for (route.start = industry_list.Begin(); industry_list.HasNext(); route.start = industry_list.Next()) {
		//Info(counter++ + " of " + industry_list.Count());
		if(IsProducerOK(route.start)==false) {
			continue;
		}
		if(route.forbidden_industries.HasItem(route.start)) {
			continue;
		}
		local cargo_list = AIIndustryType.GetProducedCargo(AIIndustry.GetIndustryType(route.start));
		for (route.cargo = cargo_list.Begin(); cargo_list.HasNext(); route.cargo = cargo_list.Next()) {
			//Info(AICargo.GetCargoLabel(route.cargo));
			route.production = AIIndustry.GetLastMonthProduction(route.start, route.cargo)*(100-AIIndustry.GetLastMonthTransportedPercentage (route.start, route.cargo))/100;
			if(IsConnectedIndustry(route.start, route.cargo)) {
				continue;
			}
			local industry_list_accepting_current_cargo = rodzic.GetLimitedIndustryList_CargoAccepting(route.cargo);
			local base = ValuateProducer(route.start, route.cargo);
			if(industry_list_accepting_current_cargo.Count()>0) {
				for(route.end = industry_list_accepting_current_cargo.Begin(); industry_list_accepting_current_cargo.HasNext(); route.end = industry_list_accepting_current_cargo.Next()) {
					if(route.forbidden_industries.HasItem(route.end)) {
						continue;
					}
					if(!IsConsumerOK(route.end)) {
						continue; 
					}
					new = ValuateConsumer(route.end, route.cargo, base);
					local distance = AITile.GetDistanceManhattanToTile(AIIndustry.GetLocation(route.end), AIIndustry.GetLocation(route.start)); 
					new *= distanceBetweenIndustriesValuator(distance); 
					if(AITile.GetCargoAcceptance (AIIndustry.GetLocation(route.end), route.cargo, 1, 1, 4)==0) {
						new=0;
					}
					if(new>best) {
						route.start_tile = AIIndustry.GetLocation(route.start);
						route.end_tile = AIIndustry.GetLocation(route.end);
						route = DualIndustryStationAllocator(route);
						if(route.StationsAllocated()) {
							route = FindEngine(route);
							if(route.engine != null) {
								best = new;
								choise.start_tile = route.start_tile;
								choise.end_tile = route.end_tile;
								choise = clone route;
								choise.first_station = clone route.first_station;
								choise.second_station = clone route.second_station;
								choise.first_station.is_city = false;
								choise.second_station.is_city = false;
								choise.track_type = route.track_type;
							}
						}
					}
				}
			} else {
				route.end = GetNiceTownForMe(AIIndustry.GetLocation(route.start));
				if(route.end == null) {
					continue;
				}
				local distance = AITile.GetDistanceManhattanToTile(AITown.GetLocation(route.end), AIIndustry.GetLocation(route.start));
				new = ValuateConsumerTown(route.end, route.cargo, base);
				new *= distanceBetweenIndustriesValuator(distance);
				new*=2; /*if(AIIndustry.GetStockpiledCargo(x, route.cargo)==0)*/
				if(new>best) {
					route.start_tile = AIIndustry.GetLocation(route.start);
					route.end_tile = AITown.GetLocation(route.end);
					route = ToCityStationAllocator(route)
					if(route.StationsAllocated()){
						route = FindEngine(route);
						if(route.engine != null) {
							best = new;
							choise.start_tile = route.start_tile;
							choise.end_tile = route.end_tile;
							choise = clone route;
							choise.first_station = clone route.first_station;
							choise.second_station = clone route.second_station;
							choise.start_tile = AIIndustry.GetLocation(route.start);
							choise.end_tile = AITown.GetLocation(route.end);
							choise.first_station.is_city = false;
							choise.second_station.is_city = true;
						}
					}
				}
			}
		}
	}
	Info("(" + best/1000 + "k points)");
	if(best == 0) {
		route.OK=false;
		return route;
	}
	choise.OK = true;
	if(AIIndustryType.IsRawIndustry(AIIndustry.GetIndustryType(choise.start))) {
		choise.type = RouteType.rawCargo;
	} else {
		choise.type = RouteType.processedCargo;
	}
	return choise;
}