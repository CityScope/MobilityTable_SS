/**
* Name: TestPlot
* Based on the internal empty template. 
* Author: naroacorettisanchez
* Tags: 
*/



model TestPlot

/* Insert your model definition here */

global{
	//Initialize list
	list values <- list_with(2000, 0);

	//Reflex update values
	reflex update_values{
		if (cycle > 2000) {
			//Remove last value
			remove first(values) from: values;
		}
		//Add new value	
		add current_date.minute to: values;

	}	
}


experiment test type: gui {

	output {
		display dashboard type: java2D{
			chart "Test Plot" type: series background: #black x_range: 2000 memorize: false {
				data "Data" value:values color: #pink marker: false style: line;
			}
		}
	}
}