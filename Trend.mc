import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

module MyGraph{
	class Trend extends WatchUi.Drawable{
		hidden var series as Array<Serie> = [] as Array<Serie>;
		hidden var xRangeMin as Numeric = 20.0f;

		public var frameColor as Graphics.ColorType = Graphics.COLOR_BLACK;
		public var textColor as Graphics.ColorType = Graphics.COLOR_BLACK;
		public var xyMarkerColor as Graphics.ColorType = Graphics.COLOR_BLACK;
		public var maxMarkerColor as Graphics.ColorType = Graphics.COLOR_RED;
		public var minMarkerColor as Graphics.ColorType = Graphics.COLOR_GREEN;

		// values to calculate screen positions from x,y
		// (these values are updates when frame is drawn)
		hidden var topMargin as Numeric = 0;
		hidden var leftMargin as Numeric = 0;
		hidden var innerWidth as Numeric = 0;
		hidden var innerHeight as Numeric = 0;
		// (these values are determined when series are drawn)
		hidden var xMin as Numeric?;
		hidden var xMax as Numeric?;
		hidden var yMin as Numeric?;
		hidden var yMax as Numeric?;
		hidden var xOffset as Numeric = 0;
		hidden var yOffset as Numeric = 0;
		hidden var xFactor as Numeric = 0;
		hidden var yFactor as Numeric = 0;
		

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

			if(options.hasKey(:series)){
				series = options.get(:series) as Array<Serie>;
				updateMinMax();
			}
			if(options.hasKey(:darkMode)){ setDarkMode(options.get(:darkMode) as Boolean); }
			if(options.hasKey(:xRangeMin)){ xRangeMin = options.get(:xRangeMin) as Numeric; }
		}

		function draw(dc as Dc){
			// collect data
			if(series == null){ return; }
			drawFrame(dc);
			drawSeries(dc);
		}

		protected function drawFrame(dc as Dc) as Void{
			var font = Graphics.FONT_XTINY;
			var labelHeight = dc.getFontHeight(font);
			var bottomMargin = 0; // space for the min/max distance 
			var axisWidth = 2;
			var axisMargin = 0.5f + Math.ceil(0.5f * axisWidth); // space for the axis width

			self.topMargin = labelHeight + 6; // space for the markers
			self.leftMargin = axisMargin;
			self.innerHeight = height - (topMargin + bottomMargin + axisMargin);
			self.innerWidth = width - (2 * axisMargin);


			// draw the xy-axis frame
			dc.setPenWidth(axisWidth);
			dc.setColor(frameColor, Graphics.COLOR_TRANSPARENT);
			dc.drawLine(locX, locY+topMargin, locX, locY+height-bottomMargin);
			dc.drawLine(locX, locY+height-bottomMargin, locX+width, locY+height-bottomMargin);
			dc.drawLine(locX+width, locY+topMargin, locX+width, locY+height-bottomMargin);
		}

		protected function updateMinMax() as Void{
			// update generic min/max values
			xMin = null;
			xMax = null;
			yMin = null;
			yMax = null;
			for(var i=0; i<series.size(); i++){
				var serie = series[i];
				var ptFirst = serie.ptFirst;
				var ptLast = serie.ptLast;
				var ptMin = serie.ptMin;
				var ptMax = serie.ptMax;

				var xMin_ = (ptFirst != null) ? ptFirst.x : null;
				var xMax_ = (ptLast != null) ? ptLast.x : null;
				var yMin_ = (ptMin != null) ? ptMin.y : null;
				var yMax_ = (ptMax != null) ? ptMax.y : null;
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

			// calculate factor x,y => pixels
			if(xMin != null && xMax != null){
				self.xFactor = innerWidth / (self.xMax-self.xMin);
			}
			if(yMin != null && yMax != null){
				self.yFactor = innerHeight / (self.yMax-self.yMin);
			}
		}

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

		public function drawCurrentXY(dc as Dc, x as Numeric, y as Numeric) as Void{
			dc.setColor(xyMarkerColor, Graphics.COLOR_TRANSPARENT);
			var xScreen = locX + xOffset + xFactor * x;
			var yScreen = locY + yOffset + yFactor * y;
			drawMarker(dc, xScreen, yScreen, leftMargin, y.format("%d"));
		}
	
		protected function drawMarker(dc as Dc, x as Numeric, y as Numeric, margin as Numeric, text as String) as Void{
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
			self.xyMarkerColor = darkMode ? Graphics.COLOR_YELLOW : Graphics.COLOR_DK_BLUE;
			self.minMarkerColor = darkMode ? Graphics.COLOR_RED : Graphics.COLOR_DK_RED;
			self.maxMarkerColor = darkMode ? Graphics.COLOR_GREEN : Graphics.COLOR_DK_GREEN;
		}

		public function addSerie(serie as Serie) as Void{
			series.add(serie);
			updateMinMax();
		}
		public function removeSerie(serie as Serie) as Void{
			series.remove(serie);
			updateMinMax();
		}
	}
}