import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

module MyGraph{
	class Trend extends WatchUi.Drawable{
		var xAxis as Axis;
		var yAxis as Axis;
		var series as Array<Serie> = [] as Array<Serie>;
		var markers as Array<Marker> = [] as Array<Marker>;

		public var frameColor as Graphics.ColorType = Graphics.COLOR_BLACK;
		public var textColor as Graphics.ColorType = Graphics.COLOR_BLACK;
		public var xyMarkerColor as Graphics.ColorType = Graphics.COLOR_BLACK;
		public var maxMarkerColor as Graphics.ColorType = Graphics.COLOR_RED;
		public var minMarkerColor as Graphics.ColorType = Graphics.COLOR_GREEN;

		hidden var axisPenWidth as Number = 3;
		hidden var markerFont as FontType = Graphics.FONT_XTINY;
		hidden var markerSize as Number = 6;

		// margins for series area
		hidden var topMargin as Numeric = 0;
		hidden var leftMargin as Numeric = 0;
		hidden var bottomMargin as Numeric = 0;
		hidden var rightMargin as Numeric = 0;

		function initialize(options as {
			:xAxis as Axis, // required
			:yAxis as Axis, // required
			:locX as Number, 
			:locY as Number,
			:width as Number, 
			:height as Number,
			:series as Array<Serie>,
			:darkMode as Boolean,
			:xRangeMin as Float,
		}){
			var requiredOptions = [:xAxis, :yAxis] as Array<Symbol>;
			for(var i=0; i<requiredOptions.size(); i++){
				var key = requiredOptions[i];
				if(!options.hasKey(key)){
					throw new Lang.InvalidOptionsException(Lang.format("Missing option: $1$", [key.toString()]));
				}
			}
			xAxis = options.get(:xAxis) as Axis;
			yAxis = options.get(:yAxis) as Axis;

			if(!options.hasKey(:identifier)){ options.put(:identifier, "Graph"); }
			Drawable.initialize(options);
			if(options.hasKey(:series)){ setSeries(options.get(:series) as Array<Serie>); }
			if(options.hasKey(:darkMode)){ setDarkMode(options.get(:darkMode) as Boolean); }

			updateSerieMargins();
		}

		function draw(dc as Dc) as Void{
			drawFrame(dc);

			for(var i=0; i<series.size(); i++){
				series[i].draw(dc);
			}

			for(var i=0; i<markers.size(); i++){
				markers[i].draw(dc);
			}

		}

		protected function drawFrame(dc as Dc) as Void{
			var axisOffset = 0.5f * axisPenWidth; // space for the axis width

			var x1 = locX + leftMargin - axisOffset;
			var x2 = locX + width - rightMargin + axisOffset;
			var y1 = locY + topMargin - axisOffset;
			var y2 = locY + height - bottomMargin + axisOffset;

			// draw the xy-axis frame
			dc.setPenWidth(axisPenWidth);
			dc.setColor(frameColor, Graphics.COLOR_TRANSPARENT);
			dc.drawLine(x1, y1, x1, y2);
			dc.drawLine(x1, y2, x2, y2);
			dc.drawLine(x2, y2, x2, y1);
		}

		function setSeries(series as Array<Serie>) as Void{
			for(var i=0; i<series.size(); i++){
				var serie = series[i];
				serie.xAxis = xAxis;
				serie.yAxis = yAxis;
			}
			self.series = series;
//			updateMinMax();
		}
/*
		protected function updateMinMax() as Void{
			// update generic min/max values
			var xMin = null;
			var xMax = null;
			var yMin = null;
			var yMax = null;
			for(var i=0; i<series.size(); i++){
				var serie = series[i];
				var xMin_ = serie.getXmin();
				var xMax_ = serie.getXmax();
				var yMin_ = serie.getYmin();
				var yMax_ = serie.getYmax();

				if(xMin_ != null && (xMin == null || xMin_ < xMin as Numeric)){
					xMin = xMin_ as Numeric;
				}
				if(xMax_ != null && (xMax == null || xMax_ < xMax as Numeric)){
					xMax = xMax_ as Numeric;
				}
				if(yMin_ != null && (yMin == null || (yMin_ as Numeric) < yMin as Numeric)){
					yMin = yMin_ as Numeric;
				}
				if(yMax_ != null && (yMax == null || (yMax_ as Numeric) < yMax as Numeric)){
					yMax = yMax_ as Numeric;
				}
			}

			if(xMin != null){ xAxis.min = xMin; }
			if(xMax != null){ xAxis.max = xMax; }
			if(yMin != null){ yAxis.min = yMin; }
			if(yMax != null){ yAxis.max = yMax; }
		}
*/
/*
		protected function drawSeries(dc as Dc) as Void{
			if(series.size() > 0){
				updateMinMax();
				var xMin = self.xMin;
				var xMax = self.xMax;
				var yMin = self.yMin;
				var yMax = self.yMax;

				if(yMin != null && yMax != null && xMin != null && xMax != null) {
					if(xMin >= xMax) { return; }
					if(yMin >= yMax) { return; }

					// the following values are also used when drawing the current position
					self.xFactor = innerWidth / (xMax - xMin);
					self.yFactor = -1 * innerHeight / (yMax - yMin);
					self.xOffset = locX + leftMargin;
					self.yOffset = locY + topMargin + innerHeight;

					var xPrev = null;
					var yPrev = null;
					
					for(var s=0; s<series.size(); s++){
						var serie = series[s];
						serie.draw(xAxis, yAxis);
						if(xMax <= xMin){ return; }

						var yRangeMin = serie.yRangeMin; // minimal vertical range

						if((xMax - xMin) < xRangeMin){
							var xExtra = xRangeMin - (xMax - xMin);
							xMax += xExtra;
						}

						if((yMax - yMin) < yRangeMin){
							var yExtra = yRangeMin - (yMax - yMin);
							yMax += 0.8 * yExtra;
							yMin -= 0.2 * yExtra;
						}

						// Create an array of point with screen xy
						var color = (serie.color != null) ? serie.color as ColorType : textColor;
						dc.setColor(color, Graphics.COLOR_TRANSPARENT);
						
						if(serie.style == DRAW_STYLE_FILLED){
							// On null values draw the shape and start a new shape
							var pt = serie.reset();
							var screenPts = [] as Array< Array<Numeric> >;
							while(pt != null){
								if(pt.y != null){
									var x = xOffset + xFactor * (pt.x - xMin);
									var y = yOffset + yFactor * (pt.y as Numeric - yMin); 
									if(xPrev == null){
										// first valid point -> add additional point from bottom
										screenPts.add([x, yOffset] as Array<Numeric>);
									}
									screenPts.add([x, y] as Array<Numeric>);
									xPrev = x;
									yPrev = y;
								}else{
									// from previous x value go down
									if(screenPts.size() > 0){
										// draw serie till last point
										screenPts.add([xPrev as Numeric, yOffset] as Array<Numeric>);
										dc.fillPolygon(screenPts);
									}
									// and start a new one
									screenPts = [] as Array< Array<Numeric> >;
									xPrev = null;
									yPrev = null;
								}
								pt = serie.next();
							}
							if(xPrev != null){
								//screenPts.add([xPrev as Numeric, locY + height - axisMargin] as Array<Numeric>);
								screenPts.add([xPrev, yOffset] as Array<Numeric>);
								dc.fillPolygon(screenPts);
							}
						}else if(serie.style == DRAW_STYLE_LINE){
							var pt = serie.reset();
							while(pt != null){
								var x = xOffset + xFactor * (pt.x - xMin);
								if(pt.y != null){
									var y = yOffset + yFactor * (pt.y as Numeric - yMin);
									if(xPrev != null && yPrev != null){											
										dc.drawLine(xPrev as Numeric, yPrev as Numeric, x, y);
									}
									yPrev = y;
								}else{
									yPrev = null;
								}
								xPrev = x;
								pt = serie.next();
							}
						}

						// Min value
						var pt = serie.ptMin;
						var markers = serie.markers;
						if((markers != null) && (pt != null) && (markers & MARKER_MIN > 0)){
							if(pt.y != null){
								var pt_y = pt.y as Numeric;
								dc.setColor(minMarkerColor, Graphics.COLOR_TRANSPARENT);
								drawMarker(
									dc, 
									xOffset + xFactor * (pt.x - xMin), 
									yOffset + yFactor * (pt_y - yMin),
									leftMargin, 
									pt_y.format("%d")
								);
							}
						}
						// Max value
						pt = serie.ptMax;
						if((serie.markers != null) && (pt != null) && (markers & MARKER_MAX > 0)){
							if(pt.y != null){
								var pt_y = pt.y as Numeric;
								dc.setColor(maxMarkerColor, Graphics.COLOR_TRANSPARENT);
								drawMarker(
									dc, 
									xOffset + xFactor * (pt.x - xMin), 
									yOffset + yFactor * (pt_y - yMin), 
									leftMargin, 
									pt_y.format("%d")
								);
							}
						}
					}
				}
			}
		}
*/
		public function setDarkMode(darkMode as Boolean) as Void{
			self.textColor = darkMode ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
			self.frameColor = darkMode ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_DK_GRAY;
			self.xyMarkerColor = darkMode ? Graphics.COLOR_YELLOW : Graphics.COLOR_DK_BLUE;
			self.minMarkerColor = darkMode ? Graphics.COLOR_RED : Graphics.COLOR_DK_RED;
			self.maxMarkerColor = darkMode ? Graphics.COLOR_GREEN : Graphics.COLOR_DK_GREEN;
		}

		function setSize(w as Numeric, h as Numeric) as Void{
			Drawable.setSize(w, h);

			var w_ = width - (leftMargin + rightMargin);
			var h_ = height - (topMargin + bottomMargin);

			// update area for the series
			for(var i=0; i<series.size(); i++){
				series[i].setSize(w_, h_);
			}
		}

		function setLocation(x as Numeric, y as Numeric) as Void{
			Drawable.setLocation(x, y);

			var x_ = locX + leftMargin;
			var y_ = locY + topMargin;
			for(var i=0; i<series.size(); i++){
				series[i].setLocation(x_, y_);
			}
		}

		hidden function updateSerieMargins() as Void{
			topMargin = 0;
			bottomMargin = axisPenWidth; // space for the min/max distance 
			leftMargin = axisPenWidth;
			rightMargin = axisPenWidth;
		}
	}
}