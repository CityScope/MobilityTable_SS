model Arduino_Listener

global {	


	init {
		create NetworkingAgent number: 1 {
		   do connect protocol: "arduino" to:"COM4";
		}		
	}
}

species NetworkingAgent skills:[network] {

	reflex fetch when:has_more_message() {	
		message mes <- fetch_message();
		write("Again");
		list mes_filter_1 <- string(mes.contents) split_with('[,]');
		list mes_filter_2 <- string(mes_filter_1[1]) split_with('[,]');
		list mes_filter_3 <- string(mes_filter_2) split_with('[:]');
		string source_string <- replace(mes_filter_3[0],"'","");
		int source <- int(source_string);
		string value_string <- replace(mes_filter_3[1],"'","");
		int value <- int(value_string);
		write("" + source + " " + value);
		
		
		/*loop while:has_more_message()
		{
			message mes <- fetch_message();
 			//list m <- string(mes.contents) split_with('[; ]');
			write (mes);
		}*/
	}
}



experiment test_Arduino type: gui {
	
}

