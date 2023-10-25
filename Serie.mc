import Toybox.Lang;
import Toybox.Graphics;

module MyGraph{

	enum DrawStyle {
		DRAW_STYLE_FILLED = 0x0,
		DRAW_STYLE_LINE = 0x1,
	}
	enum MarkerType{
		MARKER_MIN = 0x1,
		MARKER_MAX = 0x2,
	}

	class Serie{
		// additional properties
		var color as Graphics.ColorType or Null = null; // if null then let the graph decide (based upon background)
		var style as DrawStyle = DRAW_STYLE_FILLED;
		var markers as MarkerType or Number = MARKER_MIN | MARKER_MAX;
		var yRangeMin as Numeric = 20.0f; // (x,y) minimum range
		
		var pts as IIterator;
		var ptMin as DataPoint?;
		var ptMax as DataPoint?;
		var ptFirst as DataPoint?;
		var ptLast as DataPoint?;
		hidden var index as Number = -1;

		function initialize(options as {
			:pts as IIterator, // required
			:color as ColorType, // optional
			:style as DrawStyle, //optional
			:markers as MarkerType,
			:yRangeMin as Numeric,
		}){
			pts = (options.hasKey(:pts) ? options.get(:pts) : []) as IIterator;
			if(options.hasKey(:color)){ color = options.get(:color); }
			if(options.hasKey(:style)){ style = options.get(:style) as DrawStyle; }
			if(options.hasKey(:markers)){ markers = options.get(:markers) as Number; }
			if(options.hasKey(:yRangeMin)){ yRangeMin = options.get(:yRangeMin) as Numeric; }
		}

		function updateStatistics() as Void{
			// changes can be:
			//	Null => all statistics will be cleared and renewed
			//	single DataPoint => current statistics will be updated with given DataPoint
			//	array of DataPoints => current statistics will be updated with given DataPoints

			// clear old statistics
			ptMin = null;
			ptMax = null;
			ptFirst = null;
			ptLast = null;

			if(pts.first()){
				do{
					var pt = pts.current() as DataPoint;
					var x = pt.x;
					if(x != null){
						var xMin = (ptFirst != null) ? ptFirst.x : null;
						var xMax = (ptLast != null) ? ptLast.x : null;
						if(ptMin == null || x < xMin as Numeric){
							ptFirst = pt;
						}
						if(xMax == null || x > xMax as Numeric){
							ptLast = pt;
						}
					}

					var y = pt.y;
					if(y != null){
						var yMin = (ptMin != null) ? ptMin.y : null;
						var yMax = (ptMax != null) ? ptMax.y : null;
						if(yMin == null || y < yMin as Numeric){
							ptMin = pt;
						}
						if(yMax == null || y > yMax as Numeric){
							ptMax = pt;
						}
					}
				}while(pts.next());
			}
		}

		function reset() as DataPoint|Null{
/*
			index = pts.size() > 0 ? 0 : -1;
			return (index >= 0) ? pts[index] : null;
*/
			return pts.first() ? pts.current() as DataPoint : null;
		}
		function next() as DataPoint|Null{
/*
			index = pts.size() > index+1 ? index+1 : -1;
			return (index >= 0) ? pts[index] : null;
*/
			return pts.next() ? pts.current() as DataPoint : null;
		}
		function size() as Number{
			return pts.size();
		}
	}
}