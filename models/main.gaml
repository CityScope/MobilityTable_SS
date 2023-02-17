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
	/*int port <- 9877;
	string url <- "localhost";*/	
	
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
		/*create NetworkingAgent number: 1 {
		   do connect to: url protocol: "udp_server" port: port ;
		}*/	
		
		// Arduino connection
		create NetworkingAgent number: 1 {
		   do connect protocol: "arduino" to:"COM3";
		}
		
		write "FINISH INITIALIZATION";
		initial_hour <- current_date.hour;
		initial_minute <- current_date.minute;
    }
	
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
	
	// Restart the demand at the end of the day
	reflex reset_demand when: current_date.hour = 0 and current_date.minute = 0 and current_date.second = 0 {
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
	}
}

experiment generalScenario type: gui {
	int fontSize <- 5;
	int x_val <- 100;
	int x_step <- 300;
	int y_val <- 3000;
	int y_step <- 150;
		
	float minimum_cycle_duration <- 0.070 #s;

    output {
	    layout  #split background: #black consoles: false controls: false editors: false navigator: false parameters: false toolbars: false tray: false tabs: true;
		
		display dashboard  antialias: false type: java2D fullscreen: 0 background: #black{ 
			graphics Strings{
				draw "AUTONOMOUS MICRO-MOBILITY VS CARS" at: {500,90} color: #white font: font("Helvetica", 25,  #bold);
				draw "FOR FOOD DELIVERIES" at: {1050,200} color: #white font: font("Helvetica", 25,  #bold);
				draw rectangle(3650,2) at: {1880, 224} color: #white;
				if !traditionalScenario {
					draw "Future Scenario: Autonomous Micro-Mobility" at: {600,380} color: #white font: font("Helvetica", 25,  #bold);
					draw rectangle(3000,150) at: {1880, 350} color: #white wireframe: true;
				} else {
					draw "Current Scenario: Cars" at: {1250,380} color: #white font: font("Helvetica", 25,  #bold);
					draw rectangle(3000,150) at: {1880, 350} color: #white wireframe: true;
				}
			}
			chart "" type: histogram reverse_axes: true style: stack x_tick_values_visible: false background: #black title_font: font("Helvetica",15,#bold) color: #white y_range: [0.0,170.0] y_tick_unit: 10 memorize:false position: {100,550} size:{2500,200}{
				data "" value: round(gramsCO2*100)/100 	color: diagram_color;
				data " " value: (107.53-round(gramsCO2*100)/100) color: #darkgray ;
				data "  " value: (top_value) color: #dimgray;
			}
			graphics Strings {
				draw "gCO2/km traveled" at: {1050, 525} color: #white font: font("Helvetica", 15, #bold);
				if traditionalScenario and carType = "Combustion" {
					draw "" + round(gramsCO2*100)/100 at: {1250, 660} color: #white font: font("Helvetica", 12, #bold);
				} else if traditionalScenario and carType = "Electric" {
					draw "" + round(gramsCO2*100)/100 at: {750, 660} color: #white font: font("Helvetica", 12, #bold);
				} else {
					draw "" + round(gramsCO2*100)/100 at: {275, 660} color: #black font: font("Helvetica", 12, #bold);
				}
				draw rectangle(4000,65) at: {1880, 700} color: #black;
				if traditionalScenario and carType = "Combustion" {
					draw "Combustion Cars" at: {2250, 695} color: #red font: font("Helvetica", 8, #bold);
					draw "" + 161.97 at: {2350, 725} color: #red font: font("Helvetica", 8, #bold);			
					draw "Electric Cars" at: {1550, 695} color: #darkgray font: font("Helvetica", 8, #bold);
					draw "" + 107.53 at: {1600, 725} color: #darkgray font: font("Helvetica", 8, #bold);
				} else if traditionalScenario and carType = "Electric" {
					draw "Combustion Cars" at: {2250, 695} color: #dimgray font: font("Helvetica", 8, #bold);
					draw "" + 161.97 at: {2350, 725} color: #dimgray font: font("Helvetica", 8, #bold);			
					draw "Electric Cars" at: {1550, 695} color: #tomato font: font("Helvetica", 8, #bold);
					draw "" + 107.53 at: {1600, 725} color: #tomato font: font("Helvetica", 8, #bold);
				} else {
					draw "Electric Cars" at: {1550, 695} color: #darkgray font: font("Helvetica", 8, #bold);
					draw "" + 107.53 at: {1600, 725} color: #darkgray font: font("Helvetica", 8, #bold);
					draw "Combustion Cars" at: {2250, 695} color: #dimgray font: font("Helvetica", 8, #bold);
					draw "" + 161.97 at: {2350, 725} color: #dimgray font: font("Helvetica", 8, #bold);			
					draw "Autonomous Micro-Mobility" at: {200, 695} color: #lime font: font("Helvetica", 8, #bold);
					draw "" + round(gramsCO2*100)/100 at: {400, 725} color: #lime font: font("Helvetica", 8, #bold);
				}
			}
			/*chart "" type: pie style: ring background: #black color: #white title_font: font("Helvetica", 15, #bold) series_label_position: none memorize:false position: {850,600} size:{1000,550}{
				data "reduction %" value: round(reductionICE*100)/100 color: #lightgreen;
				data " " value: 100-round(reductionICE*100)/100 color: #darkgray;
			}
			graphics Strings {
				draw "CO2 reduction compared" at: {920, 550} color: #white font: font("Helvetica", 15, #bold);
				draw "to Combustion Cars" at: {1040, 630} color: #white font: font("Helvetica", 15, #bold);
				draw " " + round(reductionICE*100)/100 + "%" at: {1170, 900} color: #white font: font("Helvetica", 20, #bold);
			}
			chart "" type: pie style: ring background: #black color: #white title_font: font("Helvetica", 15, #bold) series_label_position: none memorize:false position: {1900,600} size:{1000,550}{ 
				data "reduction %" value: round(reductionBEV*100)/100 color: #darkgreen;
				data " " value: 100-round(reductionBEV*100)/100 color: #darkgray;
			}
			graphics Strings{
				draw "CO2 reduction compared" at: {1960, 550} color: #white font: font("Helvetica", 15, #bold);
				draw "to Electric Cars" at: {2150, 630} color: #white font: font("Helvetica", 15, #bold);
				draw " " + round(reductionBEV*100)/100 + "%" at: {2230, 900} color: #white font: font("Helvetica", 20, #bold);
			}*/
			graphics Strings {
				draw "Unserved trips" at: {3050, 525} color: #white font: font("Helvetica", 15, #bold) ;
				draw "" + unservedCount at: {3000,700} color: #red font:(font("Helvetica",35,#bold));
				draw "/" at: {3350,700} color: #dimgray font:(font("Helvetica",25,#bold));
				draw "" + totalCount at: {3400,700} color: #dimgray font:(font("Helvetica",25,#bold));
			}
			chart "Vehicle Tasks" type: series  background: #black color: #white title_font: font("Helvetica", 15, #bold) title_visible: false axes: #white tick_line_color:#transparent x_label: "" y_label: "" x_serie_labels: (string(current_date.hour))  x_tick_unit: 1810 memorize:false position: {100,800} size:{3000,600} series_label_position: none{
    			
    			data "Idling Cars" value: wanderCountCar color: #dimgray marker: false style: line ;
				//data "cars low battery/fuel" value: lowFuelCount color: #orange marker: false style: line;
				data "Recharging/Refuelling" value: getFuelCount color: #red marker: false style: line ;
				data "Cars in use" value: inUseCountCar+pickUpCountCar color: #cyan marker: false style: line;
				
				data "Idling AMM" value: wanderCount+fleetsizeCount color: #dimgray marker: false style: line;	
				//data "bikes with low battery" value: lowBattCount color: #coral marker: false style: line;
				data "Recharging" value: getChargeCount color: #red marker: false style: line;
				data "Autonomous micro-mobility in use" value: inUseCount+pickUpCount color: #lime marker: false style: line;
				//data "bikes night relocating" value: nightRelCount color: #plum marker: false style: line;
   			}
   			graphics Strings {
				draw "Number of vehicles" rotate: 270 at: {-90, 1050} color: #white font: font("Helvetica", 10, #bold);
				draw "Vehicle tasks" at: {1550, 775} color: #white font: font("Helvetica", 15, #bold);
				draw rectangle(50,10) at: {3150, 990} color: #lime;
				draw rectangle(50,10) at: {3150, 1050} color: #cyan;
				draw rectangle(50,10) at: {3150, 1110} color: #dimgray;
				draw rectangle(50,10) at: {3150, 1170} color: #red;
				
				draw "Micro-mobility in use" at: {3200, 1000} color: #white font: font("Helvetica", 10, #bold);
				draw "Cars in use" at: {3200, 1060} color: #white font: font("Helvetica", 10, #bold);
				draw "Vehicles idling" at: {3200, 1120} color: #white font: font("Helvetica", 10, #bold);
				draw "Recharging/Refilling" at: {3200, 1180} color: #white font: font("Helvetica", 10, #bold);
				list date_time <- string(current_date) split_with (" ",true);
				draw ("" + date_time[1]) at: {3150, 1350} color: #white font: font("Helvetica", 15, #bold);
				draw "Time of the day" at: {1600, 1420} color: #white font: font("Helvetica", 8, #bold);
			}
   			chart "Average Wait Time" type: series background: #black title_font: font("Helvetica", 15, #bold) title_visible: false color: #white axes: #white y_range:[0,120] tick_line_color:#transparent x_label: "" y_label: "" x_serie_labels: (string(current_date.hour)) x_tick_unit: 1810  memorize:false position: {100,1525} size:{3000,600} series_label_position: none {
				data "Wait Time" value: avgWait color: #pink marker: false style: line;
				data "40 min" value: 40 color: #red marker: false style: line;
			}
			graphics Strings {
				draw "Moving average wait time [min]" rotate: 270 at: {-220, 1800} color: #white font: font("Helvetica", 10, #bold);
				draw "Wait time" at: {1600, 1500} color: #white font: font("Helvetica", 15, #bold);
				draw rectangle(50,10) at: {3150, 1750} color: #red;
				draw rectangle(50,10) at: {3150, 1800} color: #pink;
				
				draw "40 minutes" at: {3200, 1760} color: #white font: font("Helvetica", 10, #bold);
				draw "Wait time" at: {3200, 1810} color: #white font: font("Helvetica", 10, #bold);
				list date_time <- string(current_date) split_with (" ",true);
				draw ("" + date_time[1]) at: {3150, 2080} color: #white font: font("Helvetica", 15, #bold);
				draw "Time of the day" at: {1600, 2150} color: #white font: font("Helvetica", 8, #bold);
			}
		}
		
				
		display agentSimulation type:opengl background: #black fullscreen: 1 axes: false {	 
			// species building aspect: type visible:show_building ;
			species road aspect: base visible:show_road transparency: 0;
			species gasstation aspect:base visible:(traditionalScenario and show_gasStation);
			species chargingStation aspect:base visible:(!traditionalScenario and show_chargingStation);
			//species restaurant aspect:base visible:show_restaurant;
			species autonomousBike aspect: realistic visible:show_autonomousBike trace:5 fading: true;
			species car aspect: realistic visible:show_car trace:3 fading: true; 
			species package aspect:base visible:show_package transparency: 0;
				
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
				draw triangle(40) at: {x_val+x_step*4, y_val + y_step - 20} color: #lime;
				draw triangle(40) at: {x_val+x_step*4, y_val + y_step*2 - 20} color: #cyan;
				draw triangle(40) at: {x_val+x_step*4, y_val + y_step*3 - 20} color: #dimgray;
				draw triangle(40) at: {x_val+x_step*4, y_val + y_step*4 - 20} color: #red;
				draw " = Micro-mobility in use" at: {x_val+x_step*4 + 50, y_val + y_step} color: #white font: font("Helvetica", fontSize, #bold);
				draw " = Cars in use" at: {x_val+x_step*4 + 50, y_val + y_step*2} color: #white font: font("Helvetica", fontSize, #bold);
				draw " = Vehicles idling" at: {x_val+x_step*4 + 50, y_val + y_step*3} color: #white font: font("Helvetica", fontSize, #bold);
				draw " = Vehicles charging" at: {x_val+x_step*4 + 50, y_val + y_step*4} color: #white font: font("Helvetica", fontSize, #bold);
				draw square(20) at: {x_val+x_step*6.3, y_val + y_step - 20} color: #lime;
				draw square(20) at: {x_val+x_step*6.3, y_val + y_step*2 - 20} color: #cyan;
				draw square(20) at: {x_val+x_step*6.3, y_val + y_step*3 - 20} color: #red;
				draw " = Food order transported by micro-mobility" at: {x_val+x_step*6.3 + 50, y_val + y_step} color: #white font: font("Helvetica", fontSize, #bold);
				draw " = Food order transported by car" at: {x_val+x_step*6.3 + 50, y_val + y_step*2} color: #white font: font("Helvetica", fontSize, #bold);
				draw " = Food order requesting delivery mode" at: {x_val+x_step*6.3 + 50, y_val + y_step*3} color: #white font: font("Helvetica", fontSize, #bold);
				draw circle(20)at: {x_val+x_step*10, y_val + y_step - 20} color: #yellow;
				draw circle(20)at: {x_val+x_step*10, y_val + y_step*2 - 20} color: #hotpink;
				draw " = Restaurants" at: {x_val+x_step*10 + 50, y_val + y_step} color: #white font: font("Helvetica", fontSize, #bold);
				if traditionalScenario{
					draw " = Gas Stations" at: {x_val+x_step*10 + 50, y_val + y_step*2} color: #white font: font("Helvetica", fontSize, #bold);
				} else{
					draw " = Charge Stations" at: {x_val+x_step*10 + 50, y_val + y_step*2} color: #white font: font("Helvetica", fontSize, #bold);				
				}
				list date_time <- string(current_date) split_with (" ",true);
				draw ("" + date_time[1]) at: {x_val+x_step*10-20, y_val + y_step*3} color: #white font: font("Helvetica", 7, #bold);
				
				draw "SCENARIO" at: {x_val, y_val+100} color: #white font: font("Helvetica", fontSize, #bold);
				draw rectangle(300,260)  border: #white wireframe: true at: {x_val+130,y_val+150};
				if traditionalScenario{
					draw "Current" at: {x_val+50, y_val+y_step+100} color: #white font: font("Helvetica", fontSize);
					draw "TYPE" at: {x_val+x_step+60, y_val+100} color: #white font: font("Helvetica", fontSize, #bold);
					draw carType at: {x_val+x_step+20, y_val+y_step+100} color: #white font: font("Helvetica", fontSize);
					draw rectangle(300,260)  border: #white wireframe: true at: {x_val+x_step+140,y_val+150};
					draw "Current Scenario: Cars" at: {x_val+x_step*9, y_val - 100} color: #white font: font("Helvetica", 7, #bold);
					draw rectangle(1000,250)  border: #white wireframe: true at: {x_val+x_step*10.3,y_val-120};
				} else{
					draw "Future Scenario" at: {x_val+x_step*9.35, y_val - 150} color: #white font: font("Helvetica", 7, #bold);
					draw "Autonomous Micro-Mobility" at: {x_val+x_step*8.75, y_val - 50} color: #white font: font("Helvetica", 7, #bold);
					draw rectangle(1000,250)  border: #white wireframe: true at: {x_val+x_step*10.3,y_val-120};
					
					draw "Future" at: {x_val+50, y_val+y_step+100} color: #white font: font("Helvetica", fontSize);
					
					draw "CHARGE" at: {x_val+20, y_val+y_step*2+80} color: #white font: font("Helvetica", fontSize, #bold);
					draw chargeSpeed at: {x_val+60, y_val+y_step*3+80} color: #white font: font("Helvetica", fontSize);
					draw rectangle(300,260)  border: #white wireframe: true at: {x_val+130,y_val+y_step*2+130};
					
					draw "BATTERY" at: {x_val+x_step+20, y_val+y_step*2+80} color: #white font: font("Helvetica", fontSize, #bold);
					draw batterySize at: {x_val+x_step+50, y_val+y_step*3+80} color: #white font: font("Helvetica", fontSize);
					draw rectangle(300,260)  border: #white wireframe: true at: {x_val+x_step+140,y_val+y_step*2+130};
					
					draw "NUM VEHICLES" at: {x_val+x_step*2+50, y_val+100} color: #white font: font("Helvetica", fontSize, #bold);
					draw ""+numAutonomousBikes at: {x_val+x_step*3, y_val+y_step/2.4+120} color: #white font: font("Helvetica", fontSize);
					
					draw "SPEED [km/h]" at: {x_val+x_step*2+50, y_val+y_step*2+20} color: #white font: font("Helvetica", fontSize, #bold);
					draw ""+round(PickUpSpeedAutonomousBike*100*3.6)/100 at: {x_val+x_step*3,y_val+y_step*3} color: #white font: font("Helvetica", fontSize);	
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