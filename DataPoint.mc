import Toybox.Lang;

module MyGraph{
	class DataPoint{
		var x as Numeric;
		var y as Numeric|Null;
		function initialize(x as Numeric, y as Numeric){
			self.x = x;
			self.y = y;
		}
	}
}