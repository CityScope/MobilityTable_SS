model main

import "./Agents.gaml"
import "./Loggers.gaml"
import "./Parameters.gaml"


global {
	//---------------------------------------------------------Performance Measures-----------------------------------------------------------------------------
	//-------------------------------------------------------------------Necessary Variables--------------------------------------------------------------------------------------------------

	// GIS FILES
	geometry shape <- envelope(bound_shapefile);
	graph roadNetwork;
	list<int> chargingStationLocation;
	
	// UDP connection
	int port <- 9877;
	string url <- "localhost";	
	
    // ---------------------------------------Agent Creation----------------------------------------------
	init{
    	// ---------------------------------------Buildings-----------------------------i----------------
		do logSetUp;
	    create building from: buildings_shapefile with: [type:string(read (usage))] {
		 	if(type!=office and type!=residence and type!=park and type!=education){ type <- "Other"; }
		}
	    
		// ---------------------------------------The Road Network----------------------------------------------
		create road from: roads_shapefile;
		
		roadNetwork <- as_edge_graph(road) ;
		
		/*loop vertex over: roadNetwork.edges {
			create intersection {
				//id <- roadNetwork.edges index_of vertex using topology(roadNetwork);
				location <- point(vertex);
			}
		}
		
		loop vertex over: roadNetwork.vertices {
			create intersection {
				//id <- roadNetwork.edges index_of vertex using topology(roadNetwork);
				location <- point(vertex);
			}
		}*/
				
		create restaurant from: restaurants_csv with:
			[lat::float(get("latitude")),
			lon::float(get("longitude"))
			]
			{location <- to_GAMA_CRS({lon,lat},"EPSG:4326").location;}
			
		create gasstation from: gasstations_csv with:
			[lat::float(get("lat")),
			lon::float(get("lon"))
			]
			{	
				location <- to_GAMA_CRS({lon,lat},"EPSG:4326").location;
				// DATA: https://faqautotips.com/how-many-fuel-pumps-does-a-typical-gas-station-have
				gasStationCapacity <- rnd(8,16);
			}
					   		
		create chargingStation from: chargingStations_csv with:
			[lat::float(get("Latitude")),
			lon::float(get("Longitude")),
			capacity::int(get("Total docks"))
			]
			{
				location <- to_GAMA_CRS({lon,lat},"EPSG:4326").location;
			}
					
		/*if traditionalScenario{
			numCars <- round(1*numVehiclesPackageTraditional);
			// drop-down menu
			if carType = "Combustion"{
				maxFuelCar <- 500000.0 #m;
				refillingRate <- maxFuelCar/3*60 #m/#s;
			} else{
				maxFuelCar <- 342000.0 #m;
				refillingRate <- maxFuelCar/30*60 #m/#s;
			}
		} else if !traditionalScenario {
			//numCars <- 0;
			if maxBatteryLifeAutonomousBike = 35000.0{
				coefficient <- 21;
			} else if maxBatteryLifeAutonomousBike = 50000.0{
				coefficient <- 30;
			} else if maxBatteryLifeAutonomousBike = 65000.0{
				coefficient <- 39;
			}
		}*/
		
		/*create autonomousBike number:numAutonomousBikes{					
			location <- point(one_of(roadNetwork.vertices));
			batteryLife <- rnd(minSafeBatteryAutonomousBike,maxBatteryLifeAutonomousBike);
		}*/
		
		/*if rechargeRate = "111s"{
			V2IChargingRate <- maxBatteryLifeAutonomousBike/(111);
			nightRechargeCond <- false;
			rechargeCond <- false;
			
		} else{
			V2IChargingRate <- maxBatteryLifeAutonomousBike/(4.5*60*60);
		}*/

	    /*create car number:numCars{		    
			location <- point(one_of(road));
			fuel <- rnd(minSafeFuelCar,maxFuelCar); 	//Battery life random bewteen max and min
		}*/
		
		// true false switch
//		if isCombustionCar{
//			maxFuelCar <- 500000.0 #m;
//			refillingRate <- maxFuelCar/3*60 #m/#s;
//			write(string(maxFuelCar));
//		} else if !isCombustionCar{
//			maxFuelCar <- 342000.0 #m;
//			refillingRate <- maxFuelCar/30*60 #m/#s;
//			write(string(maxFuelCar));
//		}
		    
		create package from: pdemand_csv with:
		[start_hour::date(get("start_time")),
				start_lat::float(get("start_latitude")),
				start_lon::float(get("start_longitude")),
				target_lat::float(get("end_latitude")),
				target_lon::float(get("end_longitude"))	
		]{
			
			start_point  <- to_GAMA_CRS({start_lon,start_lat},"EPSG:4326").location;
			target_point  <- to_GAMA_CRS({target_lon,target_lat},"EPSG:4326").location;
			location <- start_point;
			initial_closestPoint <- (road closest_to start_point using topology(road));
			final_closestPoint <- (road closest_to target_point using topology(road));
			
			string start_h_str <- string(start_hour,'kk');
			start_h <-  int(start_h_str);
			if start_h = 24 {
				start_h <- 0;
			}
			string start_min_str <- string(start_hour,'mm');
			start_min <- int(start_min_str);
		}
		
		// UDP connection
		create NetworkingAgent number: 1 {
		   do connect to: url protocol: "udp_server" port: port ;
		}	
		
		write "FINISH INITIALIZATION";
		initial_hour <- current_date.hour;
		initial_minute <- current_date.minute;
    }
    
	/*reflex stop_simulation when: cycle >= numberOfDays * numberOfHours * 3600 / step {
		do pause ;
	}*/
	
	/* corresponds with fleetsize state, new vehicles are created when the number of vehicles is increased. adds the amount needed to fulfill total amount of vehicles */
	reflex create_autonomousBikes when: !traditionalScenario and fleetsizeCount+wanderCount+lowBattCount+getChargeCount+nightRelCount+pickUpCount+inUseCount < numAutonomousBikes{ 
		create autonomousBike number: (numAutonomousBikes - (wanderCount+lowBattCount+getChargeCount+nightRelCount+pickUpCount+inUseCount)){
			location <- point(one_of(roadNetwork.vertices));
			batteryLife <- rnd(minSafeBatteryAutonomousBike,maxBatteryLifeAutonomousBike);
			fleetsizeCount <- fleetsizeCount +1;
		}
	}
	/* corresponds with fleetsize state, new vehicles are created when the number of vehicles is increased. adds the amount needed to fulfill total amount of vehicles */
	reflex create_cars when: traditionalScenario and fleetsizeCountCar+wanderCountCar+lowFuelCount+getFuelCount+pickUpCountCar+inUseCountCar < numCars{ 
		create car number: (numCars - (wanderCountCar+lowFuelCount+getFuelCount+pickUpCountCar+inUseCountCar)){
			location <- point(one_of(road));
			fuel <- rnd(minSafeFuelCar,maxFuelCar); 
			fleetsizeCountCar <- fleetsizeCountCar +1;
		}
	}
	
	// Reset the number of unserved trips
	reflex reset_unserved_counter when: ((initial_ab_number != numAutonomousBikes) or (initial_ab_battery != maxBatteryLifeAutonomousBike) or (initial_ab_speed != PickUpSpeedAutonomousBike) or (initial_ab_recharge_rate != rechargeRate) or (initial_c_number != numCars) or (initial_c_battery != maxFuelCar) or (initial_c_type != carType) or (initial_scenario != traditionalScenario)) { 
		initial_ab_number <- numAutonomousBikes;
		initial_ab_battery <- maxBatteryLifeAutonomousBike;
		initial_ab_speed <- PickUpSpeedAutonomousBike;
		initial_ab_recharge_rate <- rechargeRate;
		initial_c_number <- numCars;
		initial_c_battery <- maxFuelCar;
		initial_c_type <- carType;
		initial_scenario <- traditionalScenario;
		unservedCount <- 0;
		totalCount <- 0;
	}
	
	/*reflex stop_simulation when: cycle >= numberOfDays * numberOfHours * 3600 / step {
		timetoreload <- true;
		do pause;
		
	}*/
	
}

experiment generalScenario type: gui {
	int fontSize <- 20;
	int x_val <- 100;
	int x_step <- 300;
	int y_val <- 3000;
	int y_step <- 150;
		
	float minimum_cycle_duration <- 0.070 #s;

    output {
	    layout  #split background: #black consoles: false controls: false editors: false navigator: false parameters: false toolbars: false tray: false tabs: true;
		
		display reductionICE antialias: false type: java2D background: #black{ 
			graphics Strings{
				draw "AUTONOMOUS MICRO-MOBILITY VS CARS" at: {450,90} color: #white font: font("Helvetica", 25,  #bold);
				draw "FOR FOOD DELIVERIES" at: {1000,200} color: #white font: font("Helvetica", 25,  #bold);
			}
			chart "gCO2/km served" type: histogram style: bar background: #black title_font: font("Helvetica",15,#bold) color: #white y_range: [0.0,60.0] memorize:false position: {200,250} size:{550,600}{
				data "" value: round(gramsCO2*100)/100 	color: #red;
			}
			graphics Strings {
				draw "" + round(gramsCO2*100)/100 + " gCO2/km served" at: {200, 850} color: #white font: font("Helvetica", 12, #bold);
			}
			chart "CO2 reduction compared to Combustion Cars" type: pie style: ring background: #black color: #white title_font: font("Helvetica", 15, #bold) series_label_position: none memorize:false position: {800,250} size:{1000,650}{
				data "reduction %" value: round(reductionICE*100)/100 color: #lightgreen;
				data " " value: 100-round(reductionICE*100)/100 color: #darkgray;
			}
			graphics Strings {
				draw " " + round(reductionICE*100)/100 + "%" at: {1120, 675} color: #white font: font("Helvetica", 20, #bold);
			}
			chart "CO2 reduction compared to Electric Cars" type: pie style: ring background: #black color: #white title_font: font("Helvetica", 15, #bold) series_label_position: none memorize:false position: {1850,250} size:{1000,650}{ 
				data "reduction %" value: round(reductionBEV*100)/100 color: #darkgreen;
				data " " value: 100-round(reductionBEV*100)/100 color: #darkgray;
			}
			graphics Strings{
				draw " " + round(reductionBEV*100)/100 + "%" at: {2180, 675} color: #white font: font("Helvetica", 20, #bold);
			}
			
			graphics Strings {
				draw "Unserved trips" at: {3000, 350} color: #white font: font("Helvetica", 15, #bold) ;
				draw "" + unservedCount + "/" + totalCount at: {3100,600} color: #red font:(font("Helvetica",30,#bold));
			}
			chart "Vehicle Tasks" type: series  background: #black color: #white title_font: font("Helvetica", 15, #bold) axes: #white tick_line_color:#transparent x_label: "Time of the Day" y_label: "Number of Vehicles" x_serie_labels: (string(current_date.hour))  x_tick_unit: 1810 memorize:false position: {0,900} size:{3000,1100} series_label_position: none{
    			
    			data "Idling vehicles" value: wanderCountCar color: #dimgray marker: false style: line ;
				//data "cars low battery/fuel" value: lowFuelCount color: #orange marker: false style: line;
				data "Recharging/Refuelling" value: getFuelCount color: #red marker: false style: line ;
				data "Cars in use" value: inUseCountCar+pickUpCountCar color: #cyan marker: false style: line;
				
				data "Idling vehicles" value: wanderCount color: #dimgray marker: false style: line;	
				//data "bikes with low battery" value: lowBattCount color: #coral marker: false style: line;
				data "Recharging" value: getChargeCount color: #red marker: false style: line;
				data "Autonomous micro-mobility in use" value: inUseCount+pickUpCount color: #lime marker: false style: line;
				//data "bikes night relocating" value: nightRelCount color: #plum marker: false style: line;
   			}
   			graphics Strings {
				draw rectangle(50,10) at: {3050, 1290} color: #dimgray;
				draw rectangle(50,10) at: {3050, 1390} color: #cyan;
				draw rectangle(50,10) at: {3050, 1490} color: #lime;
				draw rectangle(50,10) at: {3050, 1590} color: #red;
				
				draw "Vehicles idling" at: {3100, 1300} color: #white font: font("Helvetica", 10, #bold);
				draw "Cars in use" at: {3100, 1400} color: #white font: font("Helvetica", 10, #bold);
				draw "Micro-mobility in use" at: {3100, 1500} color: #white font: font("Helvetica", 10, #bold);
				draw "Recharging/Refilling" at: {3100, 1600} color: #white font: font("Helvetica", 10, #bold);
				list date_time <- string(current_date) split_with (" ",true);
				draw ("" + date_time[1]) at: {3050, 1855} color: #white font: font("Helvetica", 15, #bold);
			}
   			chart "Average Wait Time" type: series background: #black title_font: font("Helvetica", 15, #bold) color: #white axes: #white y_range:[0,120] tick_line_color:#transparent x_label: "Time of the Day" y_label: "Average Last 10 Wait Times (min)" x_serie_labels: (string(current_date.hour)) x_tick_unit: 1810  memorize:false position: {0,2000} size:{3000,1100} series_label_position: none {
				data "Wait Time" value: avgWait color: #pink marker: false style: line;
				data "40 min" value: 40 color: #red marker: false style: line;
			}
			graphics Strings {
				draw rectangle(50,10) at: {3050, 2500} color: #red;
				draw rectangle(50,10) at: {3050, 2600} color: #pink;
				
				draw "40 minutes" at: {3100, 2510} color: #white font: font("Helvetica", 10, #bold);
				draw "Wait time" at: {3100, 2610} color: #white font: font("Helvetica", 10, #bold);
				list date_time <- string(current_date) split_with (" ",true);
				draw ("" + date_time[1]) at: {3050, 2950} color: #white font: font("Helvetica", 15, #bold);
			}
		}
				
		display autonomousScenario type:opengl background: #black axes: false {	 
			// species building aspect: type visible:show_building ;
			species road aspect: base visible:show_road;
			species gasstation aspect:base visible:(traditionalScenario and show_gasStation);
			species chargingStation aspect: base visible:(!traditionalScenario and show_chargingStation);
			species restaurant aspect:base visible:show_restaurant;
			species autonomousBike aspect: realistic visible:show_autonomousBike trace:15 fading: true;
			species car aspect: realistic visible:show_car trace:3 fading: true; 
			species package aspect:base visible:show_package;
				
			event["b"] {show_building<-!show_building;}
			event["r"] {show_road<-!show_road;}
			event["s"] {show_chargingStation<-!show_chargingStation;}
			event["s"] {show_gasStation<-!show_gasStation;}
			event["f"] {show_restaurant<-!show_restaurant;}
			event["d"] {show_package<-!show_package;}
			event["a"] {show_autonomousBike<-!show_autonomousBike;}
			event["c"] {show_car<-!show_car;}
	
			graphics Strings {
				if maxBatteryLifeAutonomousBike = 65000.0{
					batterySize <- "Large";
				} if rechargeRate = "111s"{
					chargeSpeed <- "Fast";
				}
				draw triangle(40) at: {x_val+x_step*4, y_val + y_step - 20} color: #dimgray;
				draw triangle(40) at: {x_val+x_step*4, y_val + y_step*2 - 20} color: #cyan;
				draw triangle(40) at: {x_val+x_step*4, y_val + y_step*3 - 20} color: #lime;
				draw triangle(40) at: {x_val+x_step*4, y_val + y_step*4 - 20} color: #red;
				draw " = Vehicles idling" at: {x_val+x_step*4 + 50, y_val + y_step} color: #white font: font("Helvetica", fontSize, #bold);
				draw " = Cars in use" at: {x_val+x_step*4 + 50, y_val + y_step*2} color: #white font: font("Helvetica", fontSize, #bold);
				draw " = Micro-mobility in use" at: {x_val+x_step*4 + 50, y_val + y_step*3} color: #white font: font("Helvetica", fontSize, #bold);
				draw " = Charging Vehicles" at: {x_val+x_step*4 + 50, y_val + y_step*4} color: #white font: font("Helvetica", fontSize, #bold);
				draw square(20) at: {x_val+x_step*6.3, y_val + y_step - 20} color: #red;
				draw square(20) at: {x_val+x_step*6.3, y_val + y_step*2 - 20} color: #cyan;
				draw square(20) at: {x_val+x_step*6.3, y_val + y_step*3 - 20} color: #lime;
				draw " = Requesting delivery mode" at: {x_val+x_step*6.3 + 50, y_val + y_step} color: #white font: font("Helvetica", fontSize, #bold);
				draw " = Picked-up/delivered by car" at: {x_val+x_step*6.3 + 50, y_val + y_step*2} color: #white font: font("Helvetica", fontSize, #bold);
				draw " = Picked-up/delivered by micro-mobility" at: {x_val+x_step*6.3 + 50, y_val + y_step*3} color: #white font: font("Helvetica", fontSize, #bold);
				draw circle(20)at: {x_val+x_step*10, y_val + y_step - 20} color: #yellow;
				draw circle(20)at: {x_val+x_step*10, y_val + y_step*2 - 20} color: #hotpink;
				draw " = Restaurants" at: {x_val+x_step*10 + 50, y_val + y_step} color: #white font: font("Helvetica", fontSize, #bold);
				if traditionalScenario{
					draw " = Gas Stations" at: {x_val+x_step*10 + 50, y_val + y_step*2} color: #white font: font("Helvetica", fontSize, #bold);
				} else{
					draw " = Charge Stations" at: {x_val+x_step*10 + 50, y_val + y_step*2} color: #white font: font("Helvetica", fontSize, #bold);				
				}
				list date_time <- string(current_date) split_with (" ",true);
				draw ("" + date_time[1]) at: {x_val+x_step*10-20, y_val + y_step*3} color: #white font: font("Helvetica", 30, #bold);
				
				draw "SCENARIO" at: {x_val, y_val-10} color: #white font: font("Helvetica", fontSize, #bold);
				draw rectangle(300,260)  border: #white wireframe: true at: {x_val+130,y_val+50};
				if traditionalScenario{
					draw "Current" at: {x_val+50, y_val+y_step+10} color: #white font: font("Helvetica", fontSize);
					draw carType at: {x_val+x_step+20, y_val+y_step+10} color: #white font: font("Helvetica", fontSize);
					draw rectangle(300,260)  border: #white wireframe: true at: {x_val+x_step+140,y_val+50};
				} else{
					draw "Future" at: {x_val+50, y_val+y_step+13} color: #white font: font("Helvetica", fontSize);
					
					draw "CHARGE" at: {x_val+20, y_val+y_step*2-20} color: #white font: font("Helvetica", fontSize, #bold);
					draw chargeSpeed at: {x_val+60, y_val+y_step*3+5} color: #white font: font("Helvetica", fontSize);
					draw rectangle(300,260)  border: #white wireframe: true at: {x_val+130,y_val+y_step*2+40};
					
					draw "BATTERY" at: {x_val+x_step+20, y_val+y_step*2-20} color: #white font: font("Helvetica", fontSize, #bold);
					draw batterySize at: {x_val+x_step+50, y_val+y_step*3+5} color: #white font: font("Helvetica", fontSize);
					draw rectangle(300,260)  border: #white wireframe: true at: {x_val+x_step+140,y_val+y_step*2+40};
					
					draw "NUM VEHICLES" at: {x_val+x_step*2+50, y_val-10} color: #white font: font("Helvetica", fontSize, #bold);
					draw ""+numAutonomousBikes at: {x_val+x_step*3, y_val+y_step/2.4+10} color: #white font: font("Helvetica", fontSize);
					
					draw "SPEED [km/h]" at: {x_val+x_step*2+50, y_val+y_step*2-80} color: #white font: font("Helvetica", fontSize, #bold);
					draw ""+round(PickUpSpeedAutonomousBike*100*3.6)/100 at: {x_val+x_step*3,y_val+y_step*2.3-20} color: #white font: font("Helvetica", fontSize);	
				}
			}
		}    	
    }	
}

/*experiment car_batch_experiment type: batch repeat: 1 until: (cycle >= numberOfDays * numberOfHours * 3600 / step) {
	parameter var: numVehiclesPackageTraditional among: [5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80];
}

experiment autonomousbike_batch_experiment type: batch repeat: 1 until: (cycle >= numberOfDays * numberOfHours * 3600 / step) {
	//parameter var: numAutonomousBikes among: [200];
	parameter var: numAutonomousBikes among: [50,350];
	//parameter var: PickUpSpeedAutonomousBike among: [11/3.6];
	parameter var: PickUpSpeedAutonomousBike among: [5/3.6,20/3.6];
	//parameter var: maxBatteryLifeAutonomousBike among: [50000.0];
	parameter var: maxBatteryLifeAutonomousBike among: [35000.0,65000.0];
}*/