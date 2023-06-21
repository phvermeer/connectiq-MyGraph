import Toybox.Lang;

module MyGraph{
	typedef ISerieData as interface{
		// point indicators for min and max values
		var ptMin as DataPoint|Null; // point containing the lowest value
		var ptMax as DataPoint|Null; // point containing the highest value

		// current min and max values
		var xMin as Numeric|Null;
		var xMax as Numeric|Null;
		var yMin as Numeric|Null;
		var yMax as Numeric|Null;

		function size() as Number;
		function clear() as Void;
		function addDataPoint(pt as DataPoint) as Void;
		function firstDataPoint() as DataPoint|Null;
		function lastDataPoint() as DataPoint|Null;
		function nextDataPoint() as DataPoint|Null;
	};
}