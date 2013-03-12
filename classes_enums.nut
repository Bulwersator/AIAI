enum StationDirection
{
x_is_constant__horizontal,
y_is_constant__vertical
}

class Station
{
location = null;
direction = null;
is_city = null;
connection = null;
area_blocked_by_station = null;
}

class RailwayStation extends Station
{
platform_count = null;
railway_tracks = null; 
//[[tile_a_neighbour, []], [tile_b_neighbour, []]]

function BuildRailwayTracks(first, last)
	{
	if(railway_tracks == null) return true;
		for(local x = 0; x < railway_tracks.len(); x++){
		if(first == railway_tracks[x][0] || last == railway_tracks[x][0]){
			for(local i = 0; i < railway_tracks[x][1].len(); i++){
				if(!AIRail.BuildRail(railway_tracks[x][1][i][0], railway_tracks[x][1][i][1], railway_tracks[x][1][i][2])){
					Error(AIError.GetLastErrorString() + " - RailwayStation::BuildRailwayTracks ")
					if(AIAI.GetSetting("debug_signs_about_failed_railway_contruction"))AISign.BuildSign(railway_tracks[x][1][i][0], "a")
					if(AIAI.GetSetting("debug_signs_about_failed_railway_contruction"))AISign.BuildSign(railway_tracks[x][1][i][1], "b")
					if(AIAI.GetSetting("debug_signs_about_failed_railway_contruction"))AISign.BuildSign(railway_tracks[x][1][i][2], "c")
					Error(i);
					return false;
					}
				}
			}
		}
		return true;
	}

function RemoveRailwayTracks(first, last)
	{
	if(railway_tracks == null) return true;
		for(local x = 0; x < railway_tracks.len(); x++){
		if(first == railway_tracks[x][0] || last == railway_tracks[x][0]){
			for(local i = 0; i < railway_tracks[x][1].len(); i++){
				if(!AIRail.RemoveRail(railway_tracks[x][1][i][0], railway_tracks[x][1][i][1], railway_tracks[x][1][i][2])){
					Error(AIError.GetLastErrorString() + " - RailwayStation::BuildRailwayTracks ")
					if(AIAI.GetSetting("debug_signs_about_failed_railway_contruction"))AISign.BuildSign(railway_tracks[x][1][i][0], "a")
					if(AIAI.GetSetting("debug_signs_about_failed_railway_contruction"))AISign.BuildSign(railway_tracks[x][1][i][1], "b")
					if(AIAI.GetSetting("debug_signs_about_failed_railway_contruction"))AISign.BuildSign(railway_tracks[x][1][i][2], "c")
					Error(i);
					return false;
					}
				}
			}
		}
		return true;
	}
}

class Route
{
start = null;
end = null;
forbidden_industries = null;
start_otoczka = null;
koniec_otoczka = null;
depot_tile = null;
start_tile = null;
end_tile = null;
cargo = null;
production = null;
type = null;
station_size = null;
station_direction = null;
first_station = null;
second_station = null;

track_type = null;

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
forbidden_industries = AIList();
start_otoczka=null; //obsolete TODO //move to Station()
koniec_otoczka=null; //obsolete TODO //move to Station()
depot_tile = null;
start_tile = null;
end_tile = null;
cargo = null;
production = null;
type = null;
station_size = null;
engine = null;
engine_count = null;
budget = null;
}

function StationsAllocated()
{
return first_station.location != null && second_station.location != null
}

}