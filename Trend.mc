import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

module MyGraph{
	class Trend extends WatchUi.Drawable{
		hidden var series as Array<Serie> = [] as Array<Serie>;
		hidden var xRangeMin as Numeric = 20.0f;
		hidden var xCurrent as Numeric or Null;
		hidden var yCurrent as Numeric or Null;

		public var frameColor as Graphics.ColorType = Graphics.COLOR_BLACK;
		public var textColor as Graphics.ColorType = Graphics.COLOR_BLACK;
		public var xyMarkerColor as Graphics.ColorType = Graphics.COLOR_BLACK;
		public var maxMarkerColor as Graphics.ColorType = Graphics.COLOR_RED;
		public var minMarkerColor as Graphics.ColorType = Graphics.COLOR_GREEN;

		function initialize(options as {
			:locX as Number, 
			:locY as Number,
			:width as Number, 
			:height as Number,
			:series as Array<Serie>,
			:darkMode as Boolean,
			:xRangeMin as Float,
		}){
			if(!options.hasKey(:identifier)){ options.put(:identifier, "Graph"); }
			Drawable.initialize(options);

			if(options.hasKey(:series)){ series = options.get(:series) as Array<Serie>; }
			if(options.hasKey(:darkMode)){ setDarkMode(options.get(:darkMode) as Boolean); }
			if(options.hasKey(:xRangeMin)){ xRangeMin = options.get(:xRangeMin) as Numeric; }
		}

		function draw(dc as Dc){
			// collect data
			if(series == null){ return; }

			// draw frame
			var font = Graphics.FONT_XTINY;
			var labelHeight = dc.getFontHeight(font);
			var topMargin = labelHeight + 6; // space for the markers
			var bottomMargin = 0; // space for the min/max distance 
			var axisWidth = 2;
			var axisMargin = 0.5f + Math.ceil(0.5f * axisWidth); // space for the axis width
			var innerHeight = height - (topMargin + bottomMargin + axisMargin);
			var innerWidth = width - (2 * axisMargin);

			// draw the xy-axis frame
			dc.setPenWidth(axisWidth);
			dc.setColor(frameColor, Graphics.COLOR_TRANSPARENT);
			dc.drawLine(locX, locY+topMargin, locX, locY+height-bottomMargin);
			dc.drawLine(locX, locY+height-bottomMargin, locX+width, locY+height-bottomMargin);
			dc.drawLine(locX+width, locY+topMargin, locX+width, locY+height-bottomMargin);
			
			// determine the generic limits (xMin, xMax, yMin, yMax)
			if(series.size() > 0){
				var xMinValues = [] as Array<Numeric>;
				var xMaxValues = [] as Array<Numeric>;
				var yMinValues = [] as Array<Numeric>;
				var yMaxValues = [] as Array<Numeric>;
				for(var s=0; s<series.size(); s++){
					var data = series[0].data;
					if(data.xMin != null){ xMinValues.add(data.xMin as Numeric); }
					if(data.xMax != null){ xMaxValues.add(data.xMax as Numeric); }
					if(data.yMin != null){ yMinValues.add(data.yMin as Numeric); }
					if(data.yMax != null){ yMaxValues.add(data.yMax as Numeric); }
				}
				var xMin = xMinValues.size() > 0 ? MyMath.min(xMinValues) : null;
				var xMax = xMaxValues.size() > 0 ? MyMath.max(xMaxValues) : null;
				var yMin = yMinValues.size() > 0 ? MyMath.min(yMinValues) : null;
				var yMax = yMaxValues.size() > 0 ? MyMath.max(yMaxValues) : null;

				if(yMin != null && yMax != null && xMin != null && xMax != null) {
					if(xMin >= xMax) { return; }
					if(yMin >= yMax) { return; }
				}else{
					return;
				}

				var xFactor = 1f * innerWidth / (xMax - xMin);
				var yFactor = -1f * innerHeight / (yMax - yMin);
				var xOffset = locX + axisMargin - xFactor * xMin;
				var yOffset = locY + topMargin + innerHeight - yMin * yFactor;
				var xPrev = null;
				var yPrev = null;
				
				for(var s=0; s<series.size(); s++){
					var serie = series[s];
					if(serie.data != null){
						var pts = serie.data;
						if(pts.size() < 2){ return; }

						// var ptFirst = pts.firstDataPoint();
						// var ptLast = pts.lastDataPoint();
					
						var yRangeMin = serie.yRangeMin; // minimal vertical range

						if((pts.size() > 1) && (xMax > xMin)){

							if((xMax - xMin) < xRangeMin){
								var xExtra = xRangeMin - (xMax - xMin);
								xMax += 1.0 * xExtra;
								xMin -= 0.0 * xExtra;
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
								var pt = pts.firstDataPoint();
								var screenPts = [] as Array< Array<Numeric> >;
								while(pt != null){
									if(pt.y != null){
										var x = xOffset + xFactor * pt.x;
										var y = yOffset + yFactor * pt.y as Numeric; 
										if(xPrev == null){
											// first valid point -> add additional point from bottom
											screenPts.add([x, locY + height - axisMargin] as Array<Numeric>);
										}
										screenPts.add([x, y] as Array<Numeric>);
										xPrev = x;
										yPrev = y;
									}else{
										// from previous x value go down
										if(screenPts.size() > 0){
											// draw serie till last point
											screenPts.add([xPrev as Numeric, locY + height - axisMargin] as Array<Numeric>);
											dc.fillPolygon(screenPts);
										}
										// and start a new one
										screenPts = [] as Array< Array<Numeric> >;
										xPrev = null;
										yPrev = null;
									}
									pt = pts.nextDataPoint();
								}
								if(xPrev != null){
									//screenPts.add([xPrev as Numeric, locY + height - axisMargin] as Array<Numeric>);
									screenPts.add([xPrev, locY + height - axisMargin] as Array<Numeric>);
									dc.fillPolygon(screenPts);
								}
							}else if(serie.style == DRAW_STYLE_LINE){
								var pt = pts.firstDataPoint();
								while(pt != null){
									var x = xOffset + xFactor * pt.x;
									if(pt.y != null){
										var y = yOffset + yFactor * pt.y as Numeric;
										if(xPrev != null && yPrev != null){											
											dc.drawLine(xPrev as Numeric, yPrev as Numeric, x, y);
										}
										yPrev = y;
									}else{
										yPrev = null;
									}
									xPrev = x;
									pt = pts.nextDataPoint();
								}
							}

							// Min value
							var pt = serie.data.ptMin;
							if((serie.markers != null) && (pt != null) && (MARKER_MIN == MARKER_MIN)){
								if(pt.y != null){
									var pt_y = pt.y as Numeric;
									dc.setColor(minMarkerColor, Graphics.COLOR_TRANSPARENT);
									drawMarker(
										dc, 
										xOffset + xFactor * pt.x, 
										yOffset + yFactor * pt_y, 
										axisMargin, 
										pt_y.format("%d")
									);
								}
							}
							// Max value
							pt = serie.data.ptMax;
							if((serie.markers != null) && (pt != null) && (MARKER_MAX == MARKER_MAX)){
								if(pt.y != null){
									var pt_y = pt.y as Numeric;
									dc.setColor(maxMarkerColor, Graphics.COLOR_TRANSPARENT);
									drawMarker(
										dc, 
										xOffset + xFactor * pt.x, 
										yOffset + yFactor * pt_y, 
										axisMargin, 
										pt_y.format("%d")
									);
								}
							}
						}
					}
				}
				// draw current x and y markers
				if(xCurrent != null){
					var x = xOffset + xFactor * xCurrent;
					dc.setColor(xyMarkerColor, Graphics.COLOR_TRANSPARENT);
					dc.setPenWidth(1);
					dc.drawLine(x, locY, x, locY + height);
				}
				if(yCurrent != null){
					var y = yOffset + yFactor * yCurrent;
					dc.setColor(xyMarkerColor, Graphics.COLOR_TRANSPARENT);
					dc.setPenWidth(1);
					dc.drawLine(xOffset, y, xOffset + xMax * xFactor, y);
				}
			}
		}
		
		public function setCurrentX(x as Numeric or Null) as Void{
			// This will draw the current X marker in the graph
			self.xCurrent = x;			
		}
		public function setCurrentY(y as Numeric or Null) as Void{
			// This will draw the current X marker in the graph
			self.yCurrent = y;			
		}
		
		protected function drawMarker(dc as Graphics.Dc, x as Numeric, y as Numeric, margin as Numeric, text as String) as Void{
			var font = Graphics.FONT_XTINY;
			var w2 = dc.getTextWidthInPixels(text, font)/2;
			var h = dc.getFontHeight(font);
			var xText = x;
			if((x-w2) < (locX + margin)){
				xText = locX + margin + w2;
			}else if((x+w2) > (locX + width - margin)){
				xText = locX + width - margin - w2;
			}
			dc.fillPolygon([
				[x, y] as Array<Numeric>,
				[x-5, y-6] as Array<Numeric>,
				[x+5, y-6] as Array<Numeric>
			] as Array< Array<Numeric> >);
			dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
			dc.drawText(xText, y-6-h, font, text, Graphics.TEXT_JUSTIFY_CENTER);
		}

		public function setDarkMode(darkMode as Boolean) as Void{
			self.textColor = darkMode ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
			self.frameColor = darkMode ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_DK_GRAY;
			self.xyMarkerColor = darkMode ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
			self.minMarkerColor = darkMode ? Graphics.COLOR_RED : Graphics.COLOR_DK_RED;
			self.maxMarkerColor = darkMode ? Graphics.COLOR_GREEN : Graphics.COLOR_DK_GREEN;
		}

		public function addSerie(serie as Serie) as Void{
			series.add(serie);
		}
		public function removeSerie(serie as Serie) as Void{
			series.remove(serie);
		}
	}
}